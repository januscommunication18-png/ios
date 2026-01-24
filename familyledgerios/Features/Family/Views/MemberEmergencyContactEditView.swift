import SwiftUI

struct MemberEmergencyContactEditView: View {
    let circleId: Int
    let memberId: Int
    let existingContact: MemberContact?
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    // Form fields
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var relationship = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var priority = 1

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    static let relationships = [
        "spouse",
        "parent",
        "sibling",
        "child",
        "grandparent",
        "aunt/uncle",
        "cousin",
        "friend",
        "neighbor",
        "coworker",
        "doctor",
        "other"
    ]

    var isEditing: Bool {
        existingContact != nil
    }

    var body: some View {
        Form {
            // Contact Information
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Contact name", text: $name)
                        .textContentType(.name)
                        .onChange(of: name) { _, newValue in
                            name = newValue.filter { !$0.isNumber }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: phone) { oldValue, newValue in
                            // Only allow digits, spaces, dashes, parentheses, and plus sign
                            let filtered = newValue.filter { "0123456789 ()-+".contains($0) }
                            if filtered != newValue {
                                phone = filtered
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
            } header: {
                Label("Contact Information", systemImage: "person.fill")
            }

            // Relationship
            Section {
                Picker("Relationship", selection: $relationship) {
                    Text("Select Relationship").tag("")
                    ForEach(Self.relationships, id: \.self) { rel in
                        Text(rel.capitalized).tag(rel)
                    }
                }
            } header: {
                Label("Relationship", systemImage: "heart.fill")
            }

            // Address
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Contact address", text: $address)
                        .textContentType(.fullStreetAddress)
                }
            } header: {
                Label("Address", systemImage: "mappin.and.ellipse")
            }

            // Priority
            Section {
                Stepper("Priority: \(priority)", value: $priority, in: 1...10)
            } header: {
                Label("Priority", systemImage: "list.number")
            } footer: {
                Text("Lower numbers are contacted first in an emergency")
            }

            // Notes
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            } header: {
                Label("Notes", systemImage: "note.text")
            }
        }
        .navigationTitle(isEditing ? "Edit Contact" : "Add Emergency Contact")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await saveContact()
                    }
                }
                .disabled(name.isEmpty || phone.isEmpty || isSaving)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadExistingData()
        }
    }

    private func loadExistingData() {
        guard let contact = existingContact else { return }

        name = contact.name ?? ""
        phone = contact.phone ?? ""
        email = contact.email ?? ""
        relationship = contact.relationship ?? ""
        address = contact.address ?? ""
        notes = contact.notes ?? ""
        priority = contact.priority ?? 1
    }

    private func saveContact() async {
        isSaving = true

        let request = MemberEmergencyContactRequest(
            name: name,
            phone: phone,
            email: email.isEmpty ? nil : email,
            relationship: relationship.isEmpty ? nil : relationship,
            address: address.isEmpty ? nil : address,
            notes: notes.isEmpty ? nil : notes,
            isEmergencyContact: true,
            priority: priority
        )

        let success: Bool
        if isEditing, let contactId = existingContact?.id {
            success = await viewModel.updateEmergencyContact(
                circleId: circleId,
                memberId: memberId,
                contactId: contactId,
                request: request
            )
        } else {
            success = await viewModel.createEmergencyContact(
                circleId: circleId,
                memberId: memberId,
                request: request
            )
        }

        isSaving = false

        if success {
            onSave?()
            dismiss()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to save emergency contact"
            showError = true
        }
    }
}

// MARK: - Request Model

struct MemberEmergencyContactRequest: Encodable {
    let name: String
    let phone: String
    let email: String?
    let relationship: String?
    let address: String?
    let notes: String?
    let isEmergencyContact: Bool
    let priority: Int

    enum CodingKeys: String, CodingKey {
        case name, phone, email, relationship, address, notes, priority
        case isEmergencyContact = "is_emergency_contact"
    }
}

struct MemberEmergencyContactResponse: Codable {
    let contact: MemberContact?
    let message: String?
}

#Preview {
    MemberEmergencyContactEditView(
        circleId: 1,
        memberId: 1,
        existingContact: nil
    )
}
