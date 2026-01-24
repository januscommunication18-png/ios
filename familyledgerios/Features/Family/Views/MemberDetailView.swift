import SwiftUI

struct MemberDetailView: View {
    let circleId: Int
    let memberId: Int

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false

    // Emergency contact delete confirmation
    @State private var showingDeleteContactConfirmation = false
    @State private var contactToDelete: MemberContact?

    var body: some View {
        Group {
            if let member = viewModel.selectedMember {
                memberContent(member: member)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadMember(circleId: circleId, memberId: memberId)
                    }
                }
            } else {
                // Show loading by default (when no member and no error)
                LoadingView(message: "Loading member details...")
            }
        }
        .navigationTitle(viewModel.selectedMember?.fullName ?? "Member")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    if isDeleting {
                        ProgressView()
                    } else {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .disabled(isDeleting)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let member = viewModel.selectedMember {
                EditFamilyMemberView(
                    circleId: circleId,
                    member: memberToBasic(member)
                ) {
                    // Refresh member after editing
                    Task {
                        await viewModel.loadMember(circleId: circleId, memberId: memberId)
                    }
                }
            }
        }
        .alert("Delete Member", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteMember()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.selectedMember?.displayName ?? "this member")? This action cannot be undone.")
        }
        .alert("Delete Contact", isPresented: $showingDeleteContactConfirmation) {
            Button("Cancel", role: .cancel) {
                contactToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let contact = contactToDelete {
                    Task {
                        await deleteEmergencyContact(contact)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(contactToDelete?.name ?? "this contact")?")
        }
        .task {
            await viewModel.loadMember(circleId: circleId, memberId: memberId)
        }
    }

    private func deleteMember() async {
        isDeleting = true
        let success = await viewModel.deleteMember(circleId: circleId, memberId: memberId)
        isDeleting = false

        if success {
            dismiss()
        }
    }

    private func deleteEmergencyContact(_ contact: MemberContact) async {
        let success = await viewModel.deleteEmergencyContact(
            circleId: circleId,
            memberId: memberId,
            contactId: contact.id
        )

        if success {
            await viewModel.loadMember(circleId: circleId, memberId: memberId)
        }
        contactToDelete = nil
    }

    private func memberToBasic(_ member: FamilyMember) -> FamilyMemberBasic {
        FamilyMemberBasic(
            id: member.id,
            firstName: member.firstName,
            lastName: member.lastName,
            fullName: member.fullName,
            email: member.email,
            phone: member.phone,
            dateOfBirth: member.dateOfBirth,
            age: member.age,
            relationship: member.relationship,
            relationshipName: member.relationshipName,
            isMinor: member.isMinor,
            profileImageUrl: member.profileImageUrl,
            immigrationStatus: member.immigrationStatus,
            immigrationStatusName: member.immigrationStatusName,
            coParentingEnabled: member.coParentingEnabled,
            createdAt: member.createdAt,
            updatedAt: member.updatedAt,
            documentsCount: member.documentsCount
        )
    }

    private func memberContent(member: FamilyMember) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profile Header
                profileHeader(member: member)

                // Personal Information
                personalInfoSection(member: member)

                // Contact Information
                if member.email != nil || member.phone != nil {
                    contactSection(member: member)
                }

                // Documents Section
                documentsSection(member: member)

                // Health & Medical Section
                healthSection(member: member)

                // Emergency Contacts Section
                emergencyContactsSection(member: member)

                // Stats Footer
                statsFooter(member: member)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Profile Header

    private func profileHeader(member: FamilyMember) -> some View {
        VStack(spacing: 16) {
            // Avatar
            MemberAvatar(member: member, size: 96)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

            // Name
            Text(member.fullName ?? member.displayName)
                .font(AppTypography.displaySmall)
                .foregroundColor(AppColors.textPrimary)

            // Badges
            HStack(spacing: 8) {
                // Relationship Badge
                Text(member.relationshipName ?? member.relationship ?? "Member")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.family)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(AppColors.family.opacity(0.1))
                    .cornerRadius(16)

                if member.isMinor == true {
                    Text("Minor")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.info)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppColors.info.opacity(0.1))
                        .cornerRadius(12)
                }

                if member.coParentingEnabled == true {
                    Text("Co-Parent")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.warning)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppColors.warning.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Personal Information Section

    private func personalInfoSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.family.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text("👤")
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Personal Information")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Member details and status")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            // Info Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InfoBox(label: "Full Name", value: member.fullName ?? member.displayName, subtext: member.relationshipName)

                if member.dateOfBirth != nil {
                    InfoBox(label: "Date of Birth", value: member.formattedDateOfBirth ?? "Not specified", subtext: member.formattedAge)
                }

                InfoBox(
                    label: "Blood Group",
                    value: member.medicalInfo?.bloodTypeDisplayName ?? member.medicalInfo?.bloodType ?? "Not specified"
                )

                InfoBox(
                    label: "Immigration Status",
                    value: member.immigrationStatusName ?? "Not specified"
                )
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Contact Section

    private func contactSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.info.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text("📞")
                        .font(.system(size: 18))
                }

                Text("Contact Information")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: 0) {
                if let email = member.email {
                    ContactActionRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        action: {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )

                    if member.phone != nil {
                        Divider()
                    }
                }

                if let phone = member.phone {
                    ContactActionRow(
                        icon: "phone.fill",
                        label: "Phone",
                        value: phone,
                        action: {
                            if let url = URL(string: "tel:\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Documents Section

    @ViewBuilder
    private func documentsSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DOCUMENTS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.5)

                Spacer()

                Text("Tap to edit")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button {
                    router.navigate(to: .editDriversLicense(circleId: circleId, memberId: memberId, document: member.driversLicense))
                } label: {
                    DocumentCard(
                        icon: "🪪",
                        iconBgColor: AppColors.info.opacity(0.15),
                        title: "Driver's License",
                        document: member.driversLicense
                    )
                }
                .buttonStyle(.plain)

                Button {
                    router.navigate(to: .editPassport(circleId: circleId, memberId: memberId, document: member.passport))
                } label: {
                    DocumentCard(
                        icon: "📘",
                        iconBgColor: AppColors.family.opacity(0.15),
                        title: "Passport",
                        document: member.passport
                    )
                }
                .buttonStyle(.plain)

                Button {
                    router.navigate(to: .editSocialSecurity(circleId: circleId, memberId: memberId, document: member.socialSecurity))
                } label: {
                    DocumentCard(
                        icon: "🔒",
                        iconBgColor: AppColors.success.opacity(0.15),
                        title: "Social Security",
                        document: member.socialSecurity,
                        isSsn: true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    router.navigate(to: .editBirthCertificate(circleId: circleId, memberId: memberId, document: member.birthCertificate))
                } label: {
                    DocumentCard(
                        icon: "📄",
                        iconBgColor: AppColors.warning.opacity(0.15),
                        title: "Birth Certificate",
                        document: member.birthCertificate,
                        showStatusOnly: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Health Section

    private func healthSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.error.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text("🏥")
                        .font(.system(size: 18))
                }

                Text("Health & Medical")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button {
                    router.navigate(to: .memberMedicalInfo(circleId: circleId, memberId: memberId))
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.family)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                // Medications
                if let medications = member.medications, !medications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medications")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)

                        FlowLayout(spacing: 6) {
                            ForEach(medications) { medication in
                                Text(medication.name ?? "Unknown")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "7c3aed"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "ede9fe"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Medical Conditions
                if let conditions = member.medicalConditions, !conditions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conditions")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)

                        FlowLayout(spacing: 6) {
                            ForEach(conditions) { condition in
                                Text(condition.name ?? "Unknown")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(statusTextColor(condition.statusColor))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(statusBgColor(condition.statusColor))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Allergies
                if let allergies = member.allergies, !allergies.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Allergies")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)

                        FlowLayout(spacing: 6) {
                            ForEach(allergies) { allergy in
                                Text(allergy.allergenName ?? "Unknown")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(severityTextColor(allergy.severityColor))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(severityBgColor(allergy.severityColor))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Healthcare Providers
                if let providers = member.healthcareProviders, !providers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Providers")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)

                        FlowLayout(spacing: 6) {
                            ForEach(providers) { provider in
                                Text(provider.name ?? "Unknown")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.success)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppColors.success.opacity(0.15))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Blood Type & Insurance Info
                if member.medicalInfo?.bloodType != nil || member.medicalInfo?.insuranceProvider != nil {
                    Divider()

                    HStack(spacing: 16) {
                        if let bloodType = member.medicalInfo?.bloodType {
                            HStack(spacing: 4) {
                                Text("Blood:")
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textTertiary)
                                Text(bloodType)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        if let insurance = member.medicalInfo?.insuranceProvider {
                            HStack(spacing: 4) {
                                Text("Insurance:")
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textTertiary)
                                Text(insurance)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }

                // Empty state
                if member.medicalInfo == nil &&
                   (member.medications?.isEmpty ?? true) &&
                   (member.allergies?.isEmpty ?? true) &&
                   (member.medicalConditions?.isEmpty ?? true) &&
                   (member.healthcareProviders?.isEmpty ?? true) {
                    VStack(spacing: 12) {
                        Text("No medical information on file")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textTertiary)

                        Button {
                            router.navigate(to: .memberMedicalInfo(circleId: circleId, memberId: memberId))
                        } label: {
                            Label("Add Medical Info", systemImage: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.family)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Emergency Contacts Section

    private func emergencyContactsSection(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.warning.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text("🚨")
                        .font(.system(size: 18))
                }

                Text("Emergency Contacts")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button {
                    router.navigate(to: .addEmergencyContact(circleId: circleId, memberId: memberId))
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.family)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                if member.emergencyContacts.isEmpty {
                    VStack(spacing: 12) {
                        Text("No emergency contacts on file")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textTertiary)

                        Button {
                            router.navigate(to: .addEmergencyContact(circleId: circleId, memberId: memberId))
                        } label: {
                            Label("Add Emergency Contact", systemImage: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppColors.family)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(member.emergencyContacts) { contact in
                        EditableEmergencyContactRow(
                            contact: contact,
                            onEdit: {
                                router.navigate(to: .editEmergencyContact(circleId: circleId, memberId: memberId, contact: contact))
                            },
                            onDelete: {
                                contactToDelete = contact
                                showingDeleteContactConfirmation = true
                            }
                        )
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Stats Footer

    private func statsFooter(member: FamilyMember) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    Text("\(member.documentsCount ?? 0)")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.family)

                    Text("Documents")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Button {
                    router.navigate(to: .documents)
                } label: {
                    Text("View")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(AppColors.family)
                        .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(AppColors.divider)
                .frame(width: 1, height: 60)

            VStack(spacing: 4) {
                Text("\(member.emergencyContacts.count)")
                    .font(AppTypography.displaySmall)
                    .foregroundColor(AppColors.family)

                Text("Emergency Contacts")
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Helper Functions

    private func statusBgColor(_ color: String?) -> Color {
        switch color {
        case "emerald": return Color(hex: "d1fae5")
        case "amber": return Color(hex: "fef3c7")
        case "rose": return Color(hex: "fce7f3")
        default: return Color(hex: "f3f4f6")
        }
    }

    private func statusTextColor(_ color: String?) -> Color {
        switch color {
        case "emerald": return Color(hex: "059669")
        case "amber": return Color(hex: "d97706")
        case "rose": return Color(hex: "db2777")
        default: return Color(hex: "6b7280")
        }
    }

    private func severityBgColor(_ color: String?) -> Color {
        switch color {
        case "rose": return Color(hex: "fce7f3")
        case "amber": return Color(hex: "fef3c7")
        case "emerald": return Color(hex: "d1fae5")
        default: return Color(hex: "f3f4f6")
        }
    }

    private func severityTextColor(_ color: String?) -> Color {
        switch color {
        case "rose": return Color(hex: "be185d")
        case "amber": return Color(hex: "d97706")
        case "emerald": return Color(hex: "059669")
        default: return Color(hex: "6b7280")
        }
    }
}

// MARK: - Info Box

struct InfoBox: View {
    let label: String
    let value: String
    var subtext: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            if let subtext = subtext {
                Text(subtext)
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Contact Action Row

struct ContactActionRow: View {
    let icon: String
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)

                    Text(value)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.family)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document Card

struct DocumentCard: View {
    let icon: String
    let iconBgColor: Color
    let title: String
    let document: MemberDocument?
    var isSsn: Bool = false
    var showStatusOnly: Bool = false  // For birth certificate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBgColor)
                    .frame(width: 40, height: 40)

                Text(icon)
                    .font(.system(size: 18))
            }

            // Title
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            if let doc = document {
                VStack(alignment: .leading, spacing: 6) {
                    // Number Row
                    HStack {
                        Text(isSsn ? "SSN" : "Number")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textTertiary)
                        Spacer()
                        Text(isSsn ? maskedSsn(doc.documentNumber) : (doc.documentNumber ?? "---"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Expiry/Status Row
                    HStack {
                        Text((isSsn || showStatusOnly) ? "Status" : "Expires")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textTertiary)
                        Spacer()
                        if isSsn || showStatusOnly {
                            Text("On File")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.success)
                        } else if doc.isExpired == true {
                            Text("Expired")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.error)
                        } else {
                            Text(doc.expiryDate ?? "---")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            } else {
                Text("No data")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    private func maskedSsn(_ ssn: String?) -> String {
        guard let ssn = ssn, ssn.count >= 4 else { return "XXX-XX-****" }
        return "XXX-XX-\(ssn.suffix(4))"
    }
}

// MARK: - Emergency Contact Row

struct EmergencyContactRow: View {
    let contact: MemberContact

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppColors.warning)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                if let phone = contact.phone {
                    Button {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(phone)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.family)
                    }
                }

                if let relationship = contact.relationship {
                    Text(relationship.capitalized)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Editable Emergency Contact Row

struct EditableEmergencyContactRow: View {
    let contact: MemberContact
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppColors.warning)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                if let phone = contact.phone {
                    Button {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(phone)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.family)
                    }
                }

                if let relationship = contact.relationship {
                    Text(relationship.capitalized)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.family)
                        .frame(width: 32, height: 32)
                        .background(AppColors.family.opacity(0.1))
                        .cornerRadius(8)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.error)
                        .frame(width: 32, height: 32)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x - spacing)
            }
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    NavigationStack {
        MemberDetailView(circleId: 1, memberId: 1)
            .environment(AppState())
    }
}
