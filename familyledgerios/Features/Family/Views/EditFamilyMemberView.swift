import SwiftUI
import PhotosUI

struct EditFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    let circleId: Int
    let member: FamilyMemberBasic
    var onMemberUpdated: (() -> Void)?

    // Basic Information
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedMonth = ""
    @State private var selectedDay = ""
    @State private var selectedYear = ""
    @State private var selectedRelationship = ""

    // Contact Information
    @State private var email = ""
    @State private var phoneCountryCode = "+1"
    @State private var phone = ""

    // Parent Information
    @State private var fatherName = ""
    @State private var motherName = ""

    // Status
    @State private var immigrationStatus = ""
    @State private var isMinor = false
    @State private var coParentingEnabled = false

    // Profile Image
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false
    @State private var hasChangedImage = false

    // State
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var relationships: [String: String] = [:]
    @State private var immigrationStatuses: [String: String] = [:]

    private let months = [
        ("01", "January"), ("02", "February"), ("03", "March"), ("04", "April"),
        ("05", "May"), ("06", "June"), ("07", "July"), ("08", "August"),
        ("09", "September"), ("10", "October"), ("11", "November"), ("12", "December")
    ]

    private let countryCodes = ["+1", "+44", "+91", "+61", "+86", "+81", "+49", "+33"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    profilePhotoSection

                    // Basic Information Section
                    basicInfoSection

                    // Contact Information Section
                    contactInfoSection

                    // Parent Information Section
                    parentInfoSection

                    // Status Section
                    statusSection

                    // Error Message
                    if let error = errorMessage {
                        errorView(error)
                    }

                    Spacer().frame(height: 20)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await updateMember() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                MemberImagePicker(imageData: $selectedImageData)
                    .onChange(of: selectedImageData) { _, _ in
                        hasChangedImage = true
                    }
            }
            .task {
                await loadOptions()
                populateFields()
            }
        }
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        VStack(spacing: 12) {
            Button {
                showingImagePicker = true
            } label: {
                ZStack {
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppColors.family, lineWidth: 3))
                    } else if let profileUrl = member.profileImageUrl, !profileUrl.isEmpty {
                        AsyncImage(url: URL(string: profileUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppColors.family, lineWidth: 3))
                            case .failure, .empty:
                                defaultProfileImage
                            @unknown default:
                                defaultProfileImage
                            }
                        }
                    } else {
                        defaultProfileImage
                    }

                    // Camera badge
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .offset(x: 35, y: 35)
                }
            }

            Text("Change Profile Photo")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var defaultProfileImage: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppColors.family, AppColors.family.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay(
                Text(member.initials)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Basic Information Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Basic Information", subtitle: "Enter the member's personal details")

            VStack(spacing: 16) {
                // First Name
                FormTextField(
                    label: "First Name",
                    placeholder: "John",
                    text: $firstName,
                    isRequired: true
                )

                // Last Name
                FormTextField(
                    label: "Last Name",
                    placeholder: "Doe",
                    text: $lastName,
                    isRequired: true
                )

                // Date of Birth
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Date of Birth")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        Text("*")
                            .foregroundColor(.red)
                    }

                    HStack(spacing: 8) {
                        // Month Picker
                        Menu {
                            ForEach(months, id: \.0) { month in
                                Button(month.1) {
                                    selectedMonth = month.0
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedMonth.isEmpty ? "Month" : months.first { $0.0 == selectedMonth }?.1 ?? "Month")
                                    .foregroundColor(selectedMonth.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Day
                        TextField("Day", text: $selectedDay)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(width: 70)

                        // Year
                        TextField("Year", text: $selectedYear)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(width: 80)
                    }
                }

                // Relationship
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Relationship")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        Text("*")
                            .foregroundColor(.red)
                    }

                    Menu {
                        ForEach(Array(relationships.keys.sorted()), id: \.self) { key in
                            Button(relationships[key] ?? key) {
                                selectedRelationship = key
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedRelationship.isEmpty ? "Select relationship" : (relationships[selectedRelationship] ?? selectedRelationship))
                                .foregroundColor(selectedRelationship.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
        }
    }

    // MARK: - Contact Information Section

    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Contact Information", subtitle: "Optional contact details")

            VStack(spacing: 16) {
                // Email
                FormTextField(
                    label: "Email",
                    placeholder: "john@example.com",
                    text: $email,
                    keyboardType: .emailAddress
                )

                // Phone
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: 8) {
                        // Country Code
                        Menu {
                            ForEach(countryCodes, id: \.self) { code in
                                Button(code) {
                                    phoneCountryCode = code
                                }
                            }
                        } label: {
                            HStack {
                                Text(phoneCountryCode)
                                    .foregroundColor(AppColors.textPrimary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .frame(width: 80)

                        TextField("5551234567", text: $phone)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
        }
    }

    // MARK: - Parent Information Section

    private var parentInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Parent Information", subtitle: "Optional parent details")

            VStack(spacing: 16) {
                FormTextField(
                    label: "Father's Name",
                    placeholder: "Enter father's name",
                    text: $fatherName
                )

                FormTextField(
                    label: "Mother's Name",
                    placeholder: "Enter mother's name",
                    text: $motherName
                )
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Status", subtitle: "Additional member details")

            VStack(spacing: 16) {
                // Immigration Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Immigration Status")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    Menu {
                        Button("Select status (optional)") {
                            immigrationStatus = ""
                        }
                        ForEach(Array(immigrationStatuses.keys.sorted()), id: \.self) { key in
                            Button(immigrationStatuses[key] ?? key) {
                                immigrationStatus = key
                            }
                        }
                    } label: {
                        HStack {
                            Text(immigrationStatus.isEmpty ? "Select status (optional)" : (immigrationStatuses[immigrationStatus] ?? immigrationStatus))
                                .foregroundColor(immigrationStatus.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }

                // Is Minor Toggle
                Toggle(isOn: $isMinor) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This person is a minor (under 18)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Enable additional protections for minors")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.family)

                // Co-parenting Toggle
                Toggle(isOn: $coParentingEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable co-parenting features")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Allow sharing information with co-parents")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.family)
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private func errorView(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedMonth.isEmpty &&
        !selectedDay.isEmpty &&
        !selectedYear.isEmpty &&
        !selectedRelationship.isEmpty
    }

    private var formattedDateOfBirth: String {
        let day = selectedDay.count == 1 ? "0\(selectedDay)" : selectedDay
        return "\(selectedYear)-\(selectedMonth)-\(day)"
    }

    // MARK: - Actions

    private func populateFields() {
        firstName = member.firstName ?? ""
        lastName = member.lastName ?? ""
        email = member.email ?? ""
        phone = member.phone ?? ""
        selectedRelationship = member.relationship ?? ""
        isMinor = member.isMinor ?? false
        coParentingEnabled = member.coParentingEnabled ?? false
        immigrationStatus = member.immigrationStatus ?? ""

        // Parse date of birth
        if let dob = member.dateOfBirth {
            let components = dob.prefix(10).split(separator: "-")
            if components.count >= 3 {
                selectedYear = String(components[0])
                selectedMonth = String(components[1])
                selectedDay = String(Int(components[2]) ?? 0)
            }
        }
    }

    private func loadOptions() async {
        // Load relationships
        do {
            let response: RelationshipsResponse = try await APIClient.shared.request(.familyMemberRelationships)
            await MainActor.run {
                relationships = response.relationships
            }
        } catch {
            print("Failed to load relationships: \(error)")
            relationships = [
                "self": "Self",
                "spouse": "Spouse",
                "partner": "Partner",
                "child": "Child",
                "stepchild": "Stepchild",
                "parent": "Parent",
                "sibling": "Sibling",
                "grandparent": "Grandparent",
                "grandchild": "Grandchild",
                "guardian": "Guardian",
                "relative": "Other Relative"
            ]
        }

        // Load immigration statuses
        do {
            let response: ImmigrationStatusesResponse = try await APIClient.shared.request(.familyMemberImmigrationStatuses)
            await MainActor.run {
                immigrationStatuses = response.immigrationStatuses
            }
        } catch {
            print("Failed to load immigration statuses: \(error)")
            immigrationStatuses = [
                "citizen": "Citizen",
                "permanent_resident": "Permanent Resident",
                "visa_holder": "Visa Holder",
                "pending": "Pending",
                "other": "Other"
            ]
        }
    }

    private func updateMember() async {
        isLoading = true
        errorMessage = nil

        // Convert image to base64 only if changed
        var photoBase64: String? = nil
        if hasChangedImage, let imageData = selectedImageData {
            photoBase64 = "data:image/jpeg;base64," + imageData.base64EncodedString()
        }

        let request = CreateFamilyMemberRequest(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.isEmpty ? nil : phone,
            phoneCountryCode: phoneCountryCode,
            dateOfBirth: formattedDateOfBirth,
            relationship: selectedRelationship,
            fatherName: fatherName.isEmpty ? nil : fatherName.trimmingCharacters(in: .whitespacesAndNewlines),
            motherName: motherName.isEmpty ? nil : motherName.trimmingCharacters(in: .whitespacesAndNewlines),
            isMinor: isMinor,
            coParentingEnabled: coParentingEnabled,
            immigrationStatus: immigrationStatus.isEmpty ? nil : immigrationStatus,
            profileImage: photoBase64
        )

        do {
            let _: CreateFamilyMemberResponse = try await APIClient.shared.request(
                .updateFamilyCircleMember(circleId: circleId, memberId: member.id),
                body: request
            )

            await MainActor.run {
                onMemberUpdated?()
                dismiss()
            }
        } catch let error as APIError {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update family member"
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }
}

#Preview {
    EditFamilyMemberView(
        circleId: 1,
        member: FamilyMemberBasic(
            id: 1,
            firstName: "John",
            lastName: "Doe",
            fullName: "John Doe",
            email: "john@example.com",
            phone: "5551234567",
            dateOfBirth: "1990-05-15",
            age: 35,
            relationship: "spouse",
            relationshipName: "Spouse",
            isMinor: false,
            profileImageUrl: nil,
            immigrationStatus: nil,
            immigrationStatusName: nil,
            coParentingEnabled: false,
            createdAt: nil,
            updatedAt: nil,
            documentsCount: nil
        )
    )
}
