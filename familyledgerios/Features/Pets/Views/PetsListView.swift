import SwiftUI

@Observable
final class PetsViewModel {
    var pets: [Pet] = []
    var selectedPet: Pet?
    var vaccinations: [Vaccination] = []
    var medications: [Medication] = []
    var stats: PetStats?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadPets() async {
        isLoading = pets.isEmpty
        do {
            let response: PetsResponse = try await APIClient.shared.request(.pets)
            pets = response.pets ?? []
        }
        catch { errorMessage = "Failed to load pets" }
        isLoading = false
    }

    @MainActor
    func loadPet(id: Int) async {
        isLoading = selectedPet == nil
        do {
            let response: PetDetailResponse = try await APIClient.shared.request(.pet(id: id))
            selectedPet = response.pet
            vaccinations = response.vaccinations ?? []
            medications = response.medications ?? []
            stats = response.stats
        }
        catch { errorMessage = "Failed to load pet" }
        isLoading = false
    }
}

struct PetsListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = PetsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading pets...")
            } else if viewModel.pets.isEmpty {
                EmptyStateView.noPets { router.navigate(to: .createPet) }
            } else {
                List(viewModel.pets) { pet in
                    Button { router.navigate(to: .pet(id: pet.id)) } label: {
                        HStack(spacing: 12) {
                            Text(pet.speciesEmoji ?? speciesEmoji(pet.species)).font(.title)
                            VStack(alignment: .leading) {
                                Text(pet.name).font(AppTypography.headline)
                                Text(pet.breed ?? pet.speciesLabel ?? "Pet").font(AppTypography.caption).foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            if let age = pet.age { Text(age).font(AppTypography.caption).foregroundColor(AppColors.textSecondary) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Pets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.navigate(to: .createPet) } label: { Image(systemName: "plus") }
            }
        }
        .task { await viewModel.loadPets() }
    }

    private func speciesEmoji(_ species: String?) -> String {
        switch species?.lowercased() {
        case "dog": return "🐕"
        case "cat": return "🐈"
        case "bird": return "🐦"
        case "fish": return "🐠"
        case "rabbit": return "🐰"
        case "hamster": return "🐹"
        case "turtle": return "🐢"
        case "snake": return "🐍"
        default: return "🐾"
        }
    }
}

struct PetDetailView: View {
    let petId: Int
    @State private var viewModel = PetsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading pet...")
            } else if let pet = viewModel.selectedPet {
                ScrollView {
                    VStack(spacing: 16) {
                        // Profile Card
                        profileCard(pet: pet)

                        // Health & Vet Info Row
                        HStack(alignment: .top, spacing: 12) {
                            healthCard(pet: pet)
                            vetCard(pet: pet)
                        }

                        // Vaccinations
                        vaccinationsCard(pet: pet)

                        // Medications
                        medicationsCard(pet: pet)

                        // Notes
                        if let notes = pet.notes, !notes.isEmpty {
                            notesCard(notes: notes)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            } else {
                VStack {
                    Text("Pet not found")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationTitle(viewModel.selectedPet?.name ?? "Pet")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadPet(id: petId) }
    }

    // MARK: - Profile Card

    private func profileCard(pet: Pet) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Photo or Emoji
                if let photoUrl = pet.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .opacity(pet.isPassedAway == true ? 0.6 : 1)
                        default:
                            petEmojiView(pet: pet)
                        }
                    }
                } else {
                    petEmojiView(pet: pet)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pet.name)
                            .font(AppTypography.displaySmall)
                            .foregroundColor(AppColors.textPrimary)
                        if pet.isPassedAway == true {
                            Text("🌈")
                        }
                    }

                    HStack(spacing: 4) {
                        Text(pet.speciesEmoji ?? "🐾")
                        Text(pet.speciesLabel ?? "Pet")
                        if let breed = pet.breed {
                            Text("•")
                            Text(breed)
                        }
                        if let gender = pet.genderLabel {
                            Text("•")
                            Text(gender)
                        }
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                    Spacer()
                }

                Spacer()
            }

            // Stats Row
            HStack(spacing: 0) {
                if let age = pet.age {
                    statItem(label: "Age", value: age)
                }
                if let microchip = pet.microchipId {
                    statItem(label: "Microchip", value: microchip)
                }
                statItem(label: "Status", value: pet.isPassedAway == true ? "Passed Away" : "Active", isStatus: true, isPassedAway: pet.isPassedAway == true)
            }
            .padding(.top, 12)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    private func petEmojiView(pet: Pet) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [AppColors.primary.opacity(0.1), AppColors.primary.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 100, height: 100)
            Text(pet.speciesEmoji ?? "🐾")
                .font(.system(size: 50))
        }
    }

    private func statItem(label: String, value: String, isStatus: Bool = false, isPassedAway: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
            if isStatus {
                Text(value)
                    .font(AppTypography.captionSmall)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isPassedAway ? Color.gray.opacity(0.2) : Color.green.opacity(0.2))
                    .foregroundColor(isPassedAway ? .gray : .green)
                    .cornerRadius(8)
            } else {
                Text(value)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Health Card

    private func healthCard(pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundColor(.pink)
                Text("Health")
                    .font(AppTypography.headline)
            }

            if let allergies = pet.allergies, !allergies.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ALLERGIES")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    Text(allergies)
                        .font(AppTypography.captionSmall)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.pink.opacity(0.1))
                        .foregroundColor(.pink)
                        .cornerRadius(8)
                }
            }

            if let conditions = pet.conditions, !conditions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONDITIONS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    Text(conditions)
                        .font(AppTypography.captionSmall)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }

            if pet.allergies == nil && pet.conditions == nil {
                Text("No health conditions")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Vet Card

    private func vetCard(pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(.teal)
                Text("Vet")
                    .font(AppTypography.headline)
            }

            if pet.vetName != nil || pet.vetClinic != nil || pet.vetPhone != nil {
                VStack(alignment: .leading, spacing: 8) {
                    if let vetName = pet.vetName {
                        HStack(spacing: 6) {
                            Image(systemName: "person")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                            Text(vetName)
                                .font(AppTypography.bodySmall)
                        }
                    }
                    if let clinic = pet.vetClinic {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                            Text(clinic)
                                .font(AppTypography.captionSmall)
                        }
                    }
                    if let phone = pet.vetPhone {
                        HStack(spacing: 6) {
                            Image(systemName: "phone")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                            Link(phone, destination: URL(string: "tel:\(phone)")!)
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            } else {
                Text("No vet info")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Vaccinations Card

    private func vaccinationsCard(pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "syringe")
                    .foregroundColor(.blue)
                Text("Vaccinations")
                    .font(AppTypography.headline)

                if let overdueCount = viewModel.stats?.overdueVaccinations, overdueCount > 0 {
                    Text("\(overdueCount) overdue")
                        .font(AppTypography.captionSmall)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }

                Spacer()
            }

            // Overdue Alert
            let overdueVax = viewModel.vaccinations.filter { $0.status == "overdue" }
            if !overdueVax.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Overdue")
                            .font(AppTypography.bodySmall)
                            .fontWeight(.medium)
                    }
                    ForEach(overdueVax) { vax in
                        Text("• \(vax.name)")
                            .font(AppTypography.captionSmall)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Due Soon Alert
            let dueSoonVax = viewModel.vaccinations.filter { $0.status == "due_soon" }
            if !dueSoonVax.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Due Soon")
                            .font(AppTypography.bodySmall)
                            .fontWeight(.medium)
                    }
                    ForEach(dueSoonVax) { vax in
                        Text("• \(vax.name) - \(vax.nextDueDate ?? "")")
                            .font(AppTypography.captionSmall)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Vaccination List
            if viewModel.vaccinations.isEmpty {
                Text("No vaccination records")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.vaccinations) { vax in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vax.name)
                                .font(AppTypography.bodySmall)
                                .fontWeight(.medium)
                            if let date = vax.administeredDate {
                                Text("Given: \(date)")
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        Spacer()
                        if let nextDue = vax.nextDueDate {
                            Text(nextDue)
                                .font(AppTypography.captionSmall)
                                .foregroundColor(vax.status == "overdue" ? .red : (vax.status == "due_soon" ? .orange : AppColors.textSecondary))
                        }
                    }
                    .padding(10)
                    .background(vax.status == "overdue" ? Color.red.opacity(0.05) : (vax.status == "due_soon" ? Color.orange.opacity(0.05) : Color(.systemGray6)))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Medications Card

    private func medicationsCard(pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills")
                    .foregroundColor(.purple)
                Text("Medications")
                    .font(AppTypography.headline)

                if let activeCount = viewModel.stats?.activeMedications, activeCount > 0 {
                    Text("\(activeCount) active")
                        .font(AppTypography.captionSmall)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }

                Spacer()
            }

            if viewModel.medications.isEmpty {
                Text("No medications recorded")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.medications) { med in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(med.name)
                                    .font(AppTypography.bodySmall)
                                    .fontWeight(.medium)
                                if med.isActive != true {
                                    Text("Inactive")
                                        .font(.system(size: 9))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            HStack(spacing: 4) {
                                if let dosage = med.dosage {
                                    Text(dosage)
                                }
                                if let frequency = med.frequency {
                                    Text("• \(frequency)")
                                }
                            }
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(med.isActive == true ? Color.purple.opacity(0.05) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(med.isActive == true ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .cornerRadius(8)
                    .opacity(med.isActive == true ? 1 : 0.6)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(AppColors.textSecondary)
                Text("Notes")
                    .font(AppTypography.headline)
            }

            Text(notes)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

struct CreatePetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var species: String = "dog"

    private let speciesOptions = ["dog", "cat", "bird", "fish", "rabbit", "hamster", "turtle", "snake", "other"]

    var body: some View {
        Form {
            TextField("Name", text: $name)
            Picker("Species", selection: $species) {
                ForEach(speciesOptions, id: \.self) { species in
                    Text("\(speciesEmoji(species)) \(species.capitalized)").tag(species)
                }
            }
        }
        .navigationTitle("New Pet")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Add") { dismiss() }.disabled(name.isEmpty) }
        }
    }

    private func speciesEmoji(_ species: String) -> String {
        switch species.lowercased() {
        case "dog": return "🐕"
        case "cat": return "🐈"
        case "bird": return "🐦"
        case "fish": return "🐠"
        case "rabbit": return "🐰"
        case "hamster": return "🐹"
        case "turtle": return "🐢"
        case "snake": return "🐍"
        default: return "🐾"
        }
    }
}
