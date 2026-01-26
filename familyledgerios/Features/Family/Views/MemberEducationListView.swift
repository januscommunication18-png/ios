import SwiftUI

struct MemberEducationListView: View {
    let initialMember: FamilyMember
    let circleId: Int

    @State private var member: FamilyMember
    @State private var isRefreshing = false
    @State private var refreshID = UUID()
    @State private var navigationPath = NavigationPath()

    init(member: FamilyMember, circleId: Int) {
        self.initialMember = member
        self.circleId = circleId
        self._member = State(initialValue: member)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info banner for multiple records
                if let records = member.schoolRecords, records.count > 1 {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppColors.info)

                        Text("Records are sorted by most recent school year first. Current school appears at the top.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.info)
                    }
                    .padding()
                    .background(AppColors.info.opacity(0.1))
                    .cornerRadius(12)
                }

                // School Records List
                if let schoolRecords = member.schoolRecords, !schoolRecords.isEmpty {
                    ForEach(schoolRecords) { record in
                        NavigationLink {
                            MemberEducationDetailView(
                                schoolRecord: record,
                                member: member,
                                circleId: circleId,
                                onDelete: {
                                    Task {
                                        await refreshMember()
                                    }
                                },
                                onUpdate: {
                                    Task {
                                        await refreshMember()
                                    }
                                }
                            )
                        } label: {
                            SchoolRecordRow(schoolRecord: record)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else if let schoolInfo = member.schoolInfo {
                    NavigationLink {
                        MemberEducationDetailView(
                            schoolRecord: schoolInfo,
                            member: member,
                            circleId: circleId,
                            onDelete: {
                                Task {
                                    await refreshMember()
                                }
                            },
                            onUpdate: {
                                Task {
                                    await refreshMember()
                                }
                            }
                        )
                    } label: {
                        SchoolRecordRow(schoolRecord: schoolInfo)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Empty State
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)

                            Text("🎓")
                                .font(.system(size: 36))
                        }

                        Text("No School Records")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        Text("Start tracking education history by adding a school record.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)

                        NavigationLink {
                            AddSchoolRecordView(
                                circleId: circleId,
                                memberId: member.id,
                                isMinor: member.isMinor ?? false,
                                onSave: {
                                    Task {
                                        await refreshMember()
                                    }
                                }
                            )
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Add School Record")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppColors.info)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
        .id(refreshID)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Education")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AddSchoolRecordView(
                        circleId: circleId,
                        memberId: member.id,
                        isMinor: member.isMinor ?? false,
                        onSave: {
                            Task {
                                await refreshMember()
                            }
                        }
                    )
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.info)
                }
            }
        }
        .refreshable {
            await refreshMember()
        }
    }

    private func refreshMember() async {
        isRefreshing = true
        do {
            let response: FamilyMemberDetailResponse = try await APIClient.shared.request(
                APIEndpoint.familyCircleMember(circleId: circleId, memberId: initialMember.id)
            )
            member = response.member
            refreshID = UUID()
        } catch {
            print("Failed to refresh member: \(error.localizedDescription)")
        }
        isRefreshing = false
    }
}

// MARK: - School Record Row

struct SchoolRecordRow: View {
    let schoolRecord: MemberSchoolInfo

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(schoolRecord.isCurrent == true ? AppColors.info.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 48, height: 48)

                Text("🏫")
                    .font(.system(size: 24))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(schoolRecord.schoolName ?? "Unknown School")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    if schoolRecord.isCurrent == true {
                        Text("Current")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.info)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    if !schoolRecord.displayGradeLevel.isEmpty {
                        Text(schoolRecord.displayGradeLevel)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    if let schoolYear = schoolRecord.schoolYear, !schoolYear.isEmpty {
                        if !schoolRecord.displayGradeLevel.isEmpty {
                            Text("|")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        Text(schoolYear)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Education Detail View

struct MemberEducationDetailView: View {
    let schoolRecord: MemberSchoolInfo
    let member: FamilyMember
    let circleId: Int
    var onDelete: (() -> Void)?
    var onUpdate: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.info.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Text("🎓")
                            .font(.system(size: 40))
                    }

                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text(schoolRecord.schoolName ?? "Unknown School")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)

                            if schoolRecord.isCurrent == true {
                                Text("Current")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppColors.info)
                                    .cornerRadius(4)
                            }
                        }

                        if !schoolRecord.displayGradeLevel.isEmpty {
                            Text(schoolRecord.displayGradeLevel)
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.background)
                .cornerRadius(16)

                // School Details
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.info)
                        Text("School Details")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)
                    }

                    VStack(spacing: 0) {
                        if let schoolYear = schoolRecord.schoolYear, !schoolYear.isEmpty {
                            EducationDetailRow(icon: "calendar", label: "School Year", value: schoolYear)
                            Divider().padding(.leading, 44)
                        }

                        if let studentId = schoolRecord.studentId, !studentId.isEmpty {
                            EducationDetailRow(icon: "person.text.rectangle", label: "Student ID", value: studentId)
                            Divider().padding(.leading, 44)
                        }

                        if let dateRange = schoolRecord.formattedDateRange {
                            EducationDetailRow(icon: "clock", label: "Duration", value: dateRange)
                            Divider().padding(.leading, 44)
                        }

                        if let address = schoolRecord.schoolAddress, !address.isEmpty {
                            EducationDetailRow(icon: "mappin.circle", label: "Address", value: address)
                            Divider().padding(.leading, 44)
                        }

                        if let phone = schoolRecord.schoolPhone, !phone.isEmpty {
                            EducationDetailRow(icon: "phone", label: "Phone", value: phone, isPhone: true)
                            Divider().padding(.leading, 44)
                        }

                        if let email = schoolRecord.schoolEmail, !email.isEmpty {
                            EducationDetailRow(icon: "envelope", label: "Email", value: email, isEmail: true)
                        }
                    }
                    .background(AppColors.background)
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Teacher & Counselor
                if schoolRecord.hasTeacherInfo || schoolRecord.hasCounselorInfo {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contacts")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)

                        VStack(spacing: 0) {
                            if let teacherName = schoolRecord.teacherName, !teacherName.isEmpty {
                                EducationContactRow(
                                    icon: "person.fill",
                                    title: "Teacher",
                                    name: teacherName,
                                    email: schoolRecord.teacherEmail
                                )
                                if schoolRecord.hasCounselorInfo {
                                    Divider().padding(.leading, 44)
                                }
                            }

                            if let counselorName = schoolRecord.counselorName, !counselorName.isEmpty {
                                EducationContactRow(
                                    icon: "person.badge.shield.checkmark.fill",
                                    title: "Counselor",
                                    name: counselorName,
                                    email: schoolRecord.counselorEmail
                                )
                            }
                        }
                        .background(AppColors.background)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Bus Information
                if schoolRecord.hasBusInfo {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Bus Information")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)

                        VStack(spacing: 0) {
                            if let busNumber = schoolRecord.busNumber, !busNumber.isEmpty {
                                EducationDetailRow(icon: "bus", label: "Bus Number", value: busNumber)
                                Divider().padding(.leading, 44)
                            }

                            if let pickup = schoolRecord.busPickupTime, !pickup.isEmpty {
                                EducationDetailRow(icon: "arrow.up.circle", label: "Pickup Time", value: pickup)
                                Divider().padding(.leading, 44)
                            }

                            if let dropoff = schoolRecord.busDropoffTime, !dropoff.isEmpty {
                                EducationDetailRow(icon: "arrow.down.circle", label: "Dropoff Time", value: dropoff)
                            }
                        }
                        .background(AppColors.background)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Notes
                if let notes = schoolRecord.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)

                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Documents
                if let documents = schoolRecord.documents, !documents.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.info)
                            Text("Documents")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(.uppercase)
                        }

                        VStack(spacing: 12) {
                            ForEach(documents) { document in
                                EducationDocumentRow(document: document)
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("School Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.info)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditSchoolRecordView(
                circleId: circleId,
                memberId: member.id,
                schoolRecord: schoolRecord,
                isMinor: member.isMinor ?? false,
                onSave: {
                    onUpdate?()
                }
            )
        }
        .alert("Delete School Record", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteSchoolRecord()
                }
            }
        } message: {
            Text("Are you sure you want to delete this school record? This action cannot be undone.")
        }
    }

    private func deleteSchoolRecord() async {
        isDeleting = true
        do {
            try await APIClient.shared.requestEmpty(
                APIEndpoint.deleteSchoolRecord(circleId: circleId, memberId: member.id, schoolRecordId: schoolRecord.id)
            )
            // Dismiss first, then trigger refresh
            await MainActor.run {
                dismiss()
            }
            // Small delay to ensure dismiss animation starts
            try? await Task.sleep(nanoseconds: 100_000_000)
            onDelete?()
        } catch {
            print("Failed to delete school record: \(error.localizedDescription)")
        }
        isDeleting = false
    }
}

// MARK: - Education Document Row

struct EducationDocumentRow: View {
    let document: MemberEducationDocument

    var body: some View {
        HStack(spacing: 12) {
            // File icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.info.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: document.fileIcon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.info)
            }

            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let typeName = document.documentTypeName {
                        Text(typeName)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    if let fileSize = document.formattedFileSize {
                        Text("•")
                            .foregroundColor(AppColors.textTertiary)
                        Text(fileSize)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            Spacer()

            // View button
            if let fileUrl = document.fileUrl, let url = URL(string: fileUrl) {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.family)
                        .padding(10)
                        .background(AppColors.family.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Education Detail Row

struct EducationDetailRow: View {
    let icon: String
    let label: String
    let value: String
    var isPhone: Bool = false
    var isEmail: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.info)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)

                if isPhone {
                    Button {
                        if let url = URL(string: "tel:\(value)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(value)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.family)
                    }
                } else if isEmail {
                    Button {
                        if let url = URL(string: "mailto:\(value)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(value)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.family)
                    }
                } else {
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
}

// MARK: - Education Contact Row

struct EducationContactRow: View {
    let icon: String
    let title: String
    let name: String
    let email: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.info)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)

                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()

            if let email = email, !email.isEmpty {
                Button {
                    if let url = URL(string: "mailto:\(email)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.family)
                        .padding(8)
                        .background(AppColors.family.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
}

