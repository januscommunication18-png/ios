import SwiftUI

struct MemberMedicalEditView: View {
    let circleId: Int
    let memberId: Int
    let existingMedicalInfo: MedicalInfo?
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    // Form fields
    @State private var bloodType = ""
    @State private var insuranceProvider = ""
    @State private var insurancePolicyNumber = ""
    @State private var insuranceGroupNumber = ""
    @State private var primaryPhysician = ""
    @State private var physicianPhone = ""
    @State private var notes = ""

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    static let bloodTypes = [
        ("", "Select Blood Type"),
        ("A+", "A Positive (A+)"),
        ("A-", "A Negative (A-)"),
        ("B+", "B Positive (B+)"),
        ("B-", "B Negative (B-)"),
        ("AB+", "AB Positive (AB+)"),
        ("AB-", "AB Negative (AB-)"),
        ("O+", "O Positive (O+)"),
        ("O-", "O Negative (O-)")
    ]

    var body: some View {
        Form {
            // Blood Type
            Section {
                Picker("Blood Type", selection: $bloodType) {
                    ForEach(Self.bloodTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }
            } header: {
                Label("Blood Information", systemImage: "drop.fill")
            }

            // Insurance Information
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Insurance Provider")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("e.g., Blue Cross Blue Shield", text: $insuranceProvider)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Policy Number")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Enter policy number", text: $insurancePolicyNumber)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Group Number")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Enter group number", text: $insuranceGroupNumber)
                }
            } header: {
                Label("Insurance", systemImage: "creditcard.fill")
            }

            // Primary Physician
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Physician")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Dr. Name", text: $primaryPhysician)
                        .onChange(of: primaryPhysician) { _, newValue in
                            primaryPhysician = newValue.filter { !$0.isNumber }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Physician Phone")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Phone number", text: $physicianPhone)
                        .keyboardType(.phonePad)
                }
            } header: {
                Label("Primary Care", systemImage: "stethoscope")
            }

            // Notes
            Section {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            } header: {
                Label("Notes", systemImage: "note.text")
            } footer: {
                Text("Any additional medical notes or information")
            }
        }
        .navigationTitle("Medical Information")
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
                        await saveMedicalInfo()
                    }
                }
                .disabled(isSaving)
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
        guard let info = existingMedicalInfo else { return }

        bloodType = info.bloodType ?? ""
        insuranceProvider = info.insuranceProvider ?? ""
        insurancePolicyNumber = info.insurancePolicyNumber ?? ""
        insuranceGroupNumber = info.insuranceGroupNumber ?? ""
        primaryPhysician = info.primaryPhysician ?? ""
        physicianPhone = info.physicianPhone ?? ""
        notes = info.notes ?? ""
    }

    private func saveMedicalInfo() async {
        isSaving = true

        let request = MemberMedicalInfoRequest(
            bloodType: bloodType.isEmpty ? nil : bloodType,
            insuranceProvider: insuranceProvider.isEmpty ? nil : insuranceProvider,
            insurancePolicyNumber: insurancePolicyNumber.isEmpty ? nil : insurancePolicyNumber,
            insuranceGroupNumber: insuranceGroupNumber.isEmpty ? nil : insuranceGroupNumber,
            primaryPhysician: primaryPhysician.isEmpty ? nil : primaryPhysician,
            physicianPhone: physicianPhone.isEmpty ? nil : physicianPhone,
            notes: notes.isEmpty ? nil : notes
        )

        let success = await viewModel.updateMedicalInfo(
            circleId: circleId,
            memberId: memberId,
            request: request
        )

        isSaving = false

        if success {
            onSave?()
            dismiss()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to save medical information"
            showError = true
        }
    }
}

// MARK: - Request Model

struct MemberMedicalInfoRequest: Encodable {
    let bloodType: String?
    let insuranceProvider: String?
    let insurancePolicyNumber: String?
    let insuranceGroupNumber: String?
    let primaryPhysician: String?
    let physicianPhone: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case bloodType = "blood_type"
        case insuranceProvider = "insurance_provider"
        case insurancePolicyNumber = "insurance_policy_number"
        case insuranceGroupNumber = "insurance_group_number"
        case primaryPhysician = "primary_physician"
        case physicianPhone = "physician_phone"
        case notes
    }
}

struct MemberMedicalInfoResponse: Codable {
    let medicalInfo: MedicalInfo?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case medicalInfo = "medical_info"
        case message
    }
}

#Preview {
    MemberMedicalEditView(
        circleId: 1,
        memberId: 1,
        existingMedicalInfo: nil
    )
}
