import SwiftUI

struct MemberMedicalInfoView: View {
    let circleId: Int
    let memberId: Int

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()
    @State private var member: FamilyMember?

    // Blood Type editing
    @State private var isEditingBloodType = false
    @State private var selectedBloodType = ""
    @State private var isSavingBloodType = false

    // Add sheet states
    @State private var showingAddMedication = false
    @State private var showingAddCondition = false
    @State private var showingAddAllergy = false
    @State private var showingAddProvider = false
    @State private var showingAddVaccination = false

    // Edit states
    @State private var editingMedication: FamilyMemberMedication?
    @State private var editingCondition: MedicalCondition?
    @State private var editingAllergy: Allergy?
    @State private var editingProvider: HealthcareProvider?
    @State private var editingVaccination: MemberVaccination?

    @State private var isLoading = true
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

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack(spacing: 16) {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading health info...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    bloodTypeSection
                    medicationsSection
                    conditionsSection
                    vaccinationsSection
                    allergiesSection
                    providersSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    var body: some View {
        contentView
            .navigationTitle("Health & Medical")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadMember()
            }
            .refreshable {
                await loadMember()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        // Add Sheets
        .sheet(isPresented: $showingAddMedication) {
            NavigationStack {
                AddMedicationView(circleId: circleId, memberId: memberId) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(isPresented: $showingAddCondition) {
            NavigationStack {
                AddConditionView(circleId: circleId, memberId: memberId) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(isPresented: $showingAddAllergy) {
            NavigationStack {
                AddAllergyView(circleId: circleId, memberId: memberId) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(isPresented: $showingAddProvider) {
            NavigationStack {
                AddProviderView(circleId: circleId, memberId: memberId) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(isPresented: $showingAddVaccination) {
            NavigationStack {
                AddVaccinationView(circleId: circleId, memberId: memberId) {
                    Task { await loadMember() }
                }
            }
        }
        // Edit Sheets
        .sheet(item: $editingMedication) { medication in
            NavigationStack {
                EditMedicationView(circleId: circleId, memberId: memberId, medication: medication) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(item: $editingCondition) { condition in
            NavigationStack {
                EditConditionView(circleId: circleId, memberId: memberId, condition: condition) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(item: $editingAllergy) { allergy in
            NavigationStack {
                EditAllergyView(circleId: circleId, memberId: memberId, allergy: allergy) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(item: $editingProvider) { provider in
            NavigationStack {
                EditProviderView(circleId: circleId, memberId: memberId, provider: provider) {
                    Task { await loadMember() }
                }
            }
        }
        .sheet(item: $editingVaccination) { vaccination in
            NavigationStack {
                EditVaccinationView(circleId: circleId, memberId: memberId, vaccination: vaccination) {
                    Task { await loadMember() }
                }
            }
        }
    }

    // MARK: - Blood Type Section

    private var bloodTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .frame(width: 32, height: 32)
                    .background(Color.pink.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("General Information")
                        .font(.headline)
                    Text("Basic medical details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(spacing: 0) {
                if isEditingBloodType {
                    // Edit Mode
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Blood Type")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Blood Type", selection: $selectedBloodType) {
                            ForEach(Self.bloodTypes, id: \.0) { type in
                                Text(type.1).tag(type.0)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack {
                            Button("Save") {
                                Task { await saveBloodType() }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSavingBloodType)

                            Button("Cancel") {
                                isEditingBloodType = false
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color.pink.opacity(0.1))
                } else {
                    // Display Mode
                    HStack {
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Blood Type")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if let bloodType = member?.medicalInfo?.bloodType, !bloodType.isEmpty {
                                Text(MedicalInfo.bloodTypeDisplayNames[bloodType] ?? bloodType)
                                    .font(.body)
                            } else {
                                Text("Not recorded")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            selectedBloodType = member?.medicalInfo?.bloodType ?? ""
                            isEditingBloodType = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Medications Section

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.purple)
                    .frame(width: 32, height: 32)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Medications")
                        .font(.headline)
                    Text("Track medications and dosages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingAddMedication = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let medications = member?.medications, !medications.isEmpty {
                VStack(spacing: 8) {
                    ForEach(medications) { medication in
                        MedicationRow(
                            medication: medication,
                            onEdit: { editingMedication = medication },
                            onDelete: { Task { await deleteMedication(medication) } }
                        )
                    }
                }
            } else {
                Text("No medications recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Conditions Section

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Medical Conditions")
                        .font(.headline)
                    Text("Ongoing health conditions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingAddCondition = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let conditions = member?.medicalConditions, !conditions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(conditions) { condition in
                        ConditionRow(
                            condition: condition,
                            onEdit: { editingCondition = condition },
                            onDelete: { Task { await deleteCondition(condition) } }
                        )
                    }
                }
            } else {
                Text("No conditions recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Vaccinations Section

    private var vaccinationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "syringe.fill")
                    .foregroundColor(.teal)
                    .frame(width: 32, height: 32)
                    .background(Color.teal.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Vaccinations")
                        .font(.headline)
                    Text("Immunization records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingAddVaccination = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let vaccinations = member?.vaccinations, !vaccinations.isEmpty {
                VStack(spacing: 8) {
                    ForEach(vaccinations) { vaccination in
                        VaccinationRow(
                            vaccination: vaccination,
                            onEdit: { editingVaccination = vaccination },
                            onDelete: { Task { await deleteVaccination(vaccination) } }
                        )
                    }
                }
            } else {
                Text("No vaccinations recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Allergies Section

    private var allergiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Medical Allergies")
                        .font(.headline)
                    Text("Track allergies and reactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingAddAllergy = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let allergies = member?.allergies, !allergies.isEmpty {
                VStack(spacing: 8) {
                    ForEach(allergies) { allergy in
                        AllergyRow(
                            allergy: allergy,
                            onEdit: { editingAllergy = allergy },
                            onDelete: { Task { await deleteAllergy(allergy) } }
                        )
                    }
                }
            } else {
                Text("No allergies recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Providers Section

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(.green)
                    .frame(width: 32, height: 32)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Healthcare Providers")
                        .font(.headline)
                    Text("Doctors and care providers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showingAddProvider = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let providers = member?.healthcareProviders, !providers.isEmpty {
                VStack(spacing: 8) {
                    ForEach(providers) { provider in
                        ProviderRow(
                            provider: provider,
                            onEdit: { editingProvider = provider },
                            onDelete: { Task { await deleteProvider(provider) } }
                        )
                    }
                }
            } else {
                Text("No healthcare providers recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Actions

    private func loadMember() async {
        isLoading = true
        member = await viewModel.fetchMemberDetail(circleId: circleId, memberId: memberId)
        isLoading = false
    }

    private func saveBloodType() async {
        isSavingBloodType = true
        let request = MemberMedicalInfoRequest(
            bloodType: selectedBloodType.isEmpty ? nil : selectedBloodType,
            insuranceProvider: nil,
            insurancePolicyNumber: nil,
            insuranceGroupNumber: nil,
            primaryPhysician: nil,
            physicianPhone: nil,
            notes: nil
        )

        let success = await viewModel.updateMedicalInfo(
            circleId: circleId,
            memberId: memberId,
            request: request
        )

        isSavingBloodType = false

        if success {
            isEditingBloodType = false
            await loadMember()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to save blood type"
            showError = true
        }
    }

    private func deleteMedication(_ medication: FamilyMemberMedication) async {
        let success = await viewModel.deleteMedication(
            circleId: circleId,
            memberId: memberId,
            medicationId: medication.id
        )
        if success {
            await loadMember()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to delete medication"
            showError = true
        }
    }

    private func deleteCondition(_ condition: MedicalCondition) async {
        let success = await viewModel.deleteCondition(
            circleId: circleId,
            memberId: memberId,
            conditionId: condition.id
        )
        if success {
            await loadMember()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to delete condition"
            showError = true
        }
    }

    private func deleteAllergy(_ allergy: Allergy) async {
        let success = await viewModel.deleteAllergy(
            circleId: circleId,
            memberId: memberId,
            allergyId: allergy.id
        )
        if success {
            await loadMember()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to delete allergy"
            showError = true
        }
    }

    private func deleteProvider(_ provider: HealthcareProvider) async {
        let success = await viewModel.deleteProvider(
            circleId: circleId,
            memberId: memberId,
            providerId: provider.id
        )
        if success {
            await loadMember()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to delete provider"
            showError = true
        }
    }

    private func deleteVaccination(_ vaccination: MemberVaccination) async {
        let success = await viewModel.deleteVaccination(
            circleId: circleId,
            memberId: memberId,
            vaccinationId: vaccination.id
        )
        if success {
            await loadMember()
        } else {
            errorMessage = viewModel.errorMessage ?? "Failed to delete vaccination"
            showError = true
        }
    }
}

// MARK: - Row Views

struct MedicationRow: View {
    let medication: FamilyMemberMedication
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color.purple)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(medication.name ?? "Unknown")
                        .font(.body)

                    if let dosage = medication.dosage, !dosage.isEmpty {
                        Text("- \(dosage)")
                            .foregroundColor(.secondary)
                    }
                }

                if let frequency = medication.frequency, !frequency.isEmpty {
                    Text(frequency.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button { onEdit() } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ConditionRow: View {
    let condition: MedicalCondition
    let onEdit: () -> Void
    let onDelete: () -> Void

    var statusColor: Color {
        switch condition.statusColor?.lowercased() {
        case "green": return .green
        case "yellow", "amber": return .yellow
        case "red": return .red
        default: return .blue
        }
    }

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(condition.name ?? "Unknown")
                        .font(.body)

                    if let status = condition.status {
                        Text(status.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.2))
                            .foregroundColor(statusColor)
                            .cornerRadius(4)
                    }
                }

                if let date = condition.diagnosedDate {
                    Text("Diagnosed: \(formatDate(date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button { onEdit() } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct AllergyRow: View {
    let allergy: Allergy
    let onEdit: () -> Void
    let onDelete: () -> Void

    var severityColor: Color {
        switch allergy.severityColor?.lowercased() ?? allergy.severity?.lowercased() {
        case "red", "severe", "life_threatening": return .red
        case "yellow", "amber", "moderate": return .orange
        case "green", "mild": return .yellow
        default: return .orange
        }
    }

    var body: some View {
        HStack {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(allergy.allergenName ?? "Unknown")
                        .font(.body)

                    if let severity = allergy.severity {
                        Text(severity.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(severityColor.opacity(0.2))
                            .foregroundColor(severityColor)
                            .cornerRadius(4)
                    }
                }

                if let reaction = allergy.reaction, !reaction.isEmpty {
                    Text(reaction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button { onEdit() } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProviderRow: View {
    let provider: HealthcareProvider
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.green)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(provider.name ?? "Unknown")
                        .font(.body)

                    if let type = provider.providerType {
                        Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }

                    if provider.isPrimary == true {
                        Text("Primary")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    }
                }

                if let specialty = provider.specialty, !specialty.isEmpty {
                    Text(specialty.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let phone = provider.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button { onEdit() } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct VaccinationRow: View {
    let vaccination: MemberVaccination
    let onEdit: () -> Void
    let onDelete: () -> Void

    var statusColor: Color {
        if vaccination.isDue == true {
            return .red
        } else if vaccination.isComingSoon == true {
            return .orange
        }
        return .teal
    }

    var body: some View {
        HStack(alignment: .top) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(vaccination.displayName)
                        .font(.body)

                    if vaccination.isDue == true {
                        Text("Due")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    } else if vaccination.isComingSoon == true {
                        Text("Coming Soon")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                if let date = vaccination.vaccinationDate {
                    Text("Given: \(formatDate(date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let nextDate = vaccination.nextVaccinationDate {
                    Text("Next: \(formatDate(nextDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let administeredBy = vaccination.administeredBy, !administeredBy.isEmpty {
                    Text("By: \(administeredBy)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button { onEdit() } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MM/dd/yy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Add/Edit Views

struct AddMedicationView: View {
    let circleId: Int
    let memberId: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var notes = ""
    @State private var isSaving = false

    static let frequencies = [
        ("once_daily", "Once Daily"),
        ("twice_daily", "Twice Daily"),
        ("three_times_daily", "Three Times Daily"),
        ("four_times_daily", "Four Times Daily"),
        ("as_needed", "As Needed"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly")
    ]

    var body: some View {
        Form {
            Section {
                TextField("Medication Name *", text: $name)
                TextField("Dosage (e.g., 10mg)", text: $dosage)

                Picker("Frequency", selection: $frequency) {
                    Text("Select").tag("")
                    ForEach(Self.frequencies, id: \.0) { freq in
                        Text(freq.1).tag(freq.0)
                    }
                }

                TextField("Notes", text: $notes)
            }
        }
        .navigationTitle("Add Medication")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        let success = await viewModel.createMedication(
            circleId: circleId,
            memberId: memberId,
            name: name,
            dosage: dosage.isEmpty ? nil : dosage,
            frequency: frequency.isEmpty ? nil : frequency,
            notes: notes.isEmpty ? nil : notes
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct EditMedicationView: View {
    let circleId: Int
    let memberId: Int
    let medication: FamilyMemberMedication
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                TextField("Medication Name *", text: $name)
                TextField("Dosage", text: $dosage)

                Picker("Frequency", selection: $frequency) {
                    Text("Select").tag("")
                    ForEach(AddMedicationView.frequencies, id: \.0) { freq in
                        Text(freq.1).tag(freq.0)
                    }
                }
            }
        }
        .navigationTitle("Edit Medication")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = medication.name ?? ""
            dosage = medication.dosage ?? ""
            frequency = medication.frequency ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        let success = await viewModel.updateMedication(
            circleId: circleId,
            memberId: memberId,
            medicationId: medication.id,
            name: name,
            dosage: dosage.isEmpty ? nil : dosage,
            frequency: frequency.isEmpty ? nil : frequency
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct AddConditionView: View {
    let circleId: Int
    let memberId: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var name = ""
    @State private var status = ""
    @State private var diagnosedDate: Date?
    @State private var notes = ""
    @State private var isSaving = false

    static let statuses = [
        ("active", "Active"),
        ("managed", "Managed"),
        ("resolved", "Resolved"),
        ("monitoring", "Monitoring")
    ]

    var body: some View {
        Form {
            Section {
                TextField("Condition Name *", text: $name)

                Picker("Status", selection: $status) {
                    Text("Select").tag("")
                    ForEach(Self.statuses, id: \.0) { s in
                        Text(s.1).tag(s.0)
                    }
                }

                DatePicker("Diagnosed Date", selection: Binding(
                    get: { diagnosedDate ?? Date() },
                    set: { diagnosedDate = $0 }
                ), displayedComponents: .date)

                TextField("Notes", text: $notes)
            }
        }
        .navigationTitle("Add Condition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true

        var dateString: String? = nil
        if let date = diagnosedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: date)
        }

        let success = await viewModel.createCondition(
            circleId: circleId,
            memberId: memberId,
            name: name,
            status: status.isEmpty ? nil : status,
            diagnosedDate: dateString,
            notes: notes.isEmpty ? nil : notes
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct EditConditionView: View {
    let circleId: Int
    let memberId: Int
    let condition: MedicalCondition
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var name = ""
    @State private var status = ""
    @State private var diagnosedDate: Date?
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                TextField("Condition Name *", text: $name)

                Picker("Status", selection: $status) {
                    Text("Select").tag("")
                    ForEach(AddConditionView.statuses, id: \.0) { s in
                        Text(s.1).tag(s.0)
                    }
                }

                DatePicker("Diagnosed Date", selection: Binding(
                    get: { diagnosedDate ?? Date() },
                    set: { diagnosedDate = $0 }
                ), displayedComponents: .date)

                TextField("Notes", text: $notes)
            }
        }
        .navigationTitle("Edit Condition")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = condition.name ?? ""
            status = condition.status ?? ""
            notes = condition.notes ?? ""

            if let dateStr = condition.diagnosedDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                diagnosedDate = formatter.date(from: dateStr)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true

        var dateString: String? = nil
        if let date = diagnosedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: date)
        }

        let success = await viewModel.updateCondition(
            circleId: circleId,
            memberId: memberId,
            conditionId: condition.id,
            name: name,
            status: status.isEmpty ? nil : status,
            diagnosedDate: dateString,
            notes: notes.isEmpty ? nil : notes
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct AddAllergyView: View {
    let circleId: Int
    let memberId: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var allergyType = ""
    @State private var allergenName = ""
    @State private var severity = ""
    @State private var reaction = ""
    @State private var isSaving = false

    static let allergyTypes = [
        ("medication", "Medication"),
        ("food", "Food"),
        ("environmental", "Environmental"),
        ("insect", "Insect"),
        ("latex", "Latex"),
        ("other", "Other")
    ]

    static let severities = [
        ("mild", "Mild"),
        ("moderate", "Moderate"),
        ("severe", "Severe"),
        ("life_threatening", "Life-Threatening")
    ]

    var body: some View {
        Form {
            Section {
                Picker("Allergy Type *", selection: $allergyType) {
                    Text("Select").tag("")
                    ForEach(Self.allergyTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }

                TextField("Allergen Name *", text: $allergenName)

                Picker("Severity *", selection: $severity) {
                    Text("Select").tag("")
                    ForEach(Self.severities, id: \.0) { sev in
                        Text(sev.1).tag(sev.0)
                    }
                }

                TextField("Reaction/Symptoms", text: $reaction)
            }
        }
        .navigationTitle("Add Allergy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(allergenName.isEmpty || allergyType.isEmpty || severity.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        let success = await viewModel.createAllergy(
            circleId: circleId,
            memberId: memberId,
            allergyType: allergyType,
            allergenName: allergenName,
            severity: severity,
            reaction: reaction.isEmpty ? nil : reaction
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct EditAllergyView: View {
    let circleId: Int
    let memberId: Int
    let allergy: Allergy
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var allergyType = ""
    @State private var allergenName = ""
    @State private var severity = ""
    @State private var reaction = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Picker("Allergy Type *", selection: $allergyType) {
                    Text("Select").tag("")
                    ForEach(AddAllergyView.allergyTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }

                TextField("Allergen Name *", text: $allergenName)

                Picker("Severity *", selection: $severity) {
                    Text("Select").tag("")
                    ForEach(AddAllergyView.severities, id: \.0) { sev in
                        Text(sev.1).tag(sev.0)
                    }
                }

                TextField("Reaction/Symptoms", text: $reaction)
            }
        }
        .navigationTitle("Edit Allergy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            allergenName = allergy.allergenName ?? ""
            severity = allergy.severity ?? ""
            reaction = allergy.reaction ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(allergenName.isEmpty || severity.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        let success = await viewModel.updateAllergy(
            circleId: circleId,
            memberId: memberId,
            allergyId: allergy.id,
            allergyType: allergyType.isEmpty ? nil : allergyType,
            allergenName: allergenName,
            severity: severity,
            reaction: reaction.isEmpty ? nil : reaction
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct AddProviderView: View {
    let circleId: Int
    let memberId: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var providerType = ""
    @State private var name = ""
    @State private var specialty = ""
    @State private var clinicName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var isPrimary = false
    @State private var isSaving = false

    static let providerTypes = [
        ("primary_care", "Primary Care"),
        ("specialist", "Specialist"),
        ("dentist", "Dentist"),
        ("optometrist", "Optometrist"),
        ("therapist", "Therapist"),
        ("other", "Other")
    ]

    static let specialties = [
        ("general_practice", "General Practice"),
        ("pediatrics", "Pediatrics"),
        ("cardiology", "Cardiology"),
        ("dermatology", "Dermatology"),
        ("orthopedics", "Orthopedics"),
        ("neurology", "Neurology"),
        ("psychiatry", "Psychiatry"),
        ("other", "Other")
    ]

    var body: some View {
        Form {
            Section {
                Picker("Provider Type *", selection: $providerType) {
                    Text("Select").tag("")
                    ForEach(Self.providerTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }

                TextField("Doctor Name *", text: $name)
                    .onChange(of: name) { _, newValue in
                        name = newValue.filter { !$0.isNumber }
                    }

                Picker("Specialty", selection: $specialty) {
                    Text("Select").tag("")
                    ForEach(Self.specialties, id: \.0) { spec in
                        Text(spec.1).tag(spec.0)
                    }
                }

                TextField("Clinic / Hospital", text: $clinicName)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                Toggle("Primary Provider", isOn: $isPrimary)
            }
        }
        .navigationTitle("Add Provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || providerType.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        let success = await viewModel.createProvider(
            circleId: circleId,
            memberId: memberId,
            providerType: providerType,
            name: name,
            specialty: specialty.isEmpty ? nil : specialty,
            clinicName: clinicName.isEmpty ? nil : clinicName,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            isPrimary: isPrimary
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct EditProviderView: View {
    let circleId: Int
    let memberId: Int
    let provider: HealthcareProvider
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var providerType = ""
    @State private var name = ""
    @State private var specialty = ""
    @State private var clinicName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var isPrimary = false
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Picker("Provider Type *", selection: $providerType) {
                    Text("Select").tag("")
                    ForEach(AddProviderView.providerTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }

                TextField("Doctor Name *", text: $name)
                    .onChange(of: name) { _, newValue in
                        name = newValue.filter { !$0.isNumber }
                    }

                Picker("Specialty", selection: $specialty) {
                    Text("Select").tag("")
                    ForEach(AddProviderView.specialties, id: \.0) { spec in
                        Text(spec.1).tag(spec.0)
                    }
                }

                TextField("Clinic / Hospital", text: $clinicName)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                Toggle("Primary Provider", isOn: $isPrimary)
            }
        }
        .navigationTitle("Edit Provider")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            providerType = provider.providerType ?? ""
            name = provider.name ?? ""
            specialty = provider.specialty ?? ""
            phone = provider.phone ?? ""
            email = provider.email ?? ""
            isPrimary = provider.isPrimary ?? false
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(name.isEmpty || providerType.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        let success = await viewModel.updateProvider(
            circleId: circleId,
            memberId: memberId,
            providerId: provider.id,
            providerType: providerType,
            name: name,
            specialty: specialty.isEmpty ? nil : specialty,
            clinicName: clinicName.isEmpty ? nil : clinicName,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            isPrimary: isPrimary
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct AddVaccinationView: View {
    let circleId: Int
    let memberId: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var vaccineType = ""
    @State private var vaccineName = ""
    @State private var customVaccineName = ""
    @State private var vaccinationDate: Date?
    @State private var nextVaccinationDate: Date?
    @State private var administeredBy = ""
    @State private var lotNumber = ""
    @State private var notes = ""
    @State private var isSaving = false

    static let vaccineTypes = [
        ("childhood", "Childhood"),
        ("adult", "Adult"),
        ("travel", "Travel"),
        ("flu", "Flu"),
        ("covid", "COVID-19"),
        ("other", "Other")
    ]

    static let vaccineNames: [String: [(String, String)]] = [
        "childhood": [
            ("dtap", "DTaP (Diphtheria, Tetanus, Pertussis)"),
            ("ipv", "IPV (Polio)"),
            ("mmr", "MMR (Measles, Mumps, Rubella)"),
            ("varicella", "Varicella (Chickenpox)"),
            ("hib", "Hib (Haemophilus influenzae type b)"),
            ("hepatitis_b", "Hepatitis B"),
            ("hepatitis_a", "Hepatitis A"),
            ("rotavirus", "Rotavirus"),
            ("pcv", "PCV (Pneumococcal)")
        ],
        "adult": [
            ("tdap", "Tdap (Tetanus, Diphtheria, Pertussis)"),
            ("shingles", "Shingles (Zoster)"),
            ("pneumonia", "Pneumonia"),
            ("hepatitis_b", "Hepatitis B"),
            ("hepatitis_a", "Hepatitis A")
        ],
        "travel": [
            ("yellow_fever", "Yellow Fever"),
            ("typhoid", "Typhoid"),
            ("japanese_encephalitis", "Japanese Encephalitis"),
            ("rabies", "Rabies"),
            ("cholera", "Cholera")
        ],
        "flu": [
            ("seasonal_flu", "Seasonal Flu")
        ],
        "covid": [
            ("covid_primary", "COVID-19 Primary Series"),
            ("covid_booster", "COVID-19 Booster")
        ],
        "other": []
    ]

    var availableVaccines: [(String, String)] {
        AddVaccinationView.vaccineNames[vaccineType] ?? []
    }

    var body: some View {
        Form {
            Section {
                Picker("Vaccine Type *", selection: $vaccineType) {
                    Text("Select").tag("")
                    ForEach(Self.vaccineTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }

                if !availableVaccines.isEmpty {
                    Picker("Vaccine Name", selection: $vaccineName) {
                        Text("Select").tag("")
                        ForEach(availableVaccines, id: \.0) { vaccine in
                            Text(vaccine.1).tag(vaccine.0)
                        }
                    }
                }

                if vaccineType == "other" || (vaccineType != "" && vaccineName == "") {
                    TextField("Custom Vaccine Name", text: $customVaccineName)
                }
            }

            Section("Date Information") {
                DatePicker("Vaccination Date", selection: Binding(
                    get: { vaccinationDate ?? Date() },
                    set: { vaccinationDate = $0 }
                ), displayedComponents: .date)

                DatePicker("Next Due Date", selection: Binding(
                    get: { nextVaccinationDate ?? Date() },
                    set: { nextVaccinationDate = $0 }
                ), displayedComponents: .date)
            }

            Section("Additional Information") {
                TextField("Administered By", text: $administeredBy)
                TextField("Lot Number", text: $lotNumber)
                TextField("Notes", text: $notes)
            }
        }
        .navigationTitle("Add Vaccination")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(vaccineType.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var vacDateStr: String? = nil
        if let date = vaccinationDate {
            vacDateStr = formatter.string(from: date)
        }

        var nextDateStr: String? = nil
        if let date = nextVaccinationDate {
            nextDateStr = formatter.string(from: date)
        }

        let success = await viewModel.createVaccination(
            circleId: circleId,
            memberId: memberId,
            vaccineType: vaccineType,
            vaccineName: vaccineName.isEmpty ? nil : vaccineName,
            customVaccineName: customVaccineName.isEmpty ? nil : customVaccineName,
            vaccinationDate: vacDateStr,
            nextVaccinationDate: nextDateStr,
            administeredBy: administeredBy.isEmpty ? nil : administeredBy,
            lotNumber: lotNumber.isEmpty ? nil : lotNumber,
            notes: notes.isEmpty ? nil : notes
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

struct EditVaccinationView: View {
    let circleId: Int
    let memberId: Int
    let vaccination: MemberVaccination
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FamilyViewModel()

    @State private var vaccineType = ""
    @State private var vaccineName = ""
    @State private var customVaccineName = ""
    @State private var vaccinationDate: Date?
    @State private var nextVaccinationDate: Date?
    @State private var administeredBy = ""
    @State private var lotNumber = ""
    @State private var notes = ""
    @State private var isSaving = false

    var availableVaccines: [(String, String)] {
        AddVaccinationView.vaccineNames[vaccineType] ?? []
    }

    var body: some View {
        Form {
            Section {
                Picker("Vaccine Type *", selection: $vaccineType) {
                    Text("Select").tag("")
                    ForEach(AddVaccinationView.vaccineTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }

                if !availableVaccines.isEmpty {
                    Picker("Vaccine Name", selection: $vaccineName) {
                        Text("Select").tag("")
                        ForEach(availableVaccines, id: \.0) { vaccine in
                            Text(vaccine.1).tag(vaccine.0)
                        }
                    }
                }

                if vaccineType == "other" || (vaccineType != "" && vaccineName == "") {
                    TextField("Custom Vaccine Name", text: $customVaccineName)
                }
            }

            Section("Date Information") {
                DatePicker("Vaccination Date", selection: Binding(
                    get: { vaccinationDate ?? Date() },
                    set: { vaccinationDate = $0 }
                ), displayedComponents: .date)

                DatePicker("Next Due Date", selection: Binding(
                    get: { nextVaccinationDate ?? Date() },
                    set: { nextVaccinationDate = $0 }
                ), displayedComponents: .date)
            }

            Section("Additional Information") {
                TextField("Administered By", text: $administeredBy)
                TextField("Lot Number", text: $lotNumber)
                TextField("Notes", text: $notes)
            }
        }
        .navigationTitle("Edit Vaccination")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vaccineType = vaccination.vaccineType ?? ""
            vaccineName = vaccination.vaccineName ?? ""
            customVaccineName = vaccination.customVaccineName ?? ""
            administeredBy = vaccination.administeredBy ?? ""
            lotNumber = vaccination.lotNumber ?? ""
            notes = vaccination.notes ?? ""

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let dateStr = vaccination.vaccinationDate {
                vaccinationDate = formatter.date(from: dateStr)
            }
            if let dateStr = vaccination.nextVaccinationDate {
                nextVaccinationDate = formatter.date(from: dateStr)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(vaccineType.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var vacDateStr: String? = nil
        if let date = vaccinationDate {
            vacDateStr = formatter.string(from: date)
        }

        var nextDateStr: String? = nil
        if let date = nextVaccinationDate {
            nextDateStr = formatter.string(from: date)
        }

        let success = await viewModel.updateVaccination(
            circleId: circleId,
            memberId: memberId,
            vaccinationId: vaccination.id,
            vaccineType: vaccineType,
            vaccineName: vaccineName.isEmpty ? nil : vaccineName,
            customVaccineName: customVaccineName.isEmpty ? nil : customVaccineName,
            vaccinationDate: vacDateStr,
            nextVaccinationDate: nextDateStr,
            administeredBy: administeredBy.isEmpty ? nil : administeredBy,
            lotNumber: lotNumber.isEmpty ? nil : lotNumber,
            notes: notes.isEmpty ? nil : notes
        )
        isSaving = false

        if success {
            onSave()
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        MemberMedicalInfoView(circleId: 1, memberId: 1)
    }
    .environment(AppRouter())
}
