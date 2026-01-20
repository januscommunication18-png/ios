import Foundation
import SwiftUI

struct Pet: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let species: String?
    let speciesLabel: String?
    let speciesEmoji: String?
    let breed: String?
    let dateOfBirth: String?
    let age: String?
    let ageShort: String?
    let gender: String?
    let genderLabel: String?
    let color: String?
    let weight: Double?
    let microchipId: String?
    let photoUrl: String?
    let status: String?
    let isPassedAway: Bool?
    let passedAwayDate: String?
    let vetName: String?
    let vetPhone: String?
    let vetClinic: String?
    let vetAddress: String?
    let allergies: String?
    let conditions: String?
    let insuranceProvider: String?
    let insurancePolicyNumber: String?
    let notes: String?
    let overdueVaccinations: [Vaccination]?
    let upcomingVaccinations: [Vaccination]?
    let activeMedications: [Medication]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, species, breed, gender, color, weight, notes, age, status, allergies, conditions
        case speciesLabel = "species_label"
        case speciesEmoji = "species_emoji"
        case dateOfBirth = "date_of_birth"
        case ageShort = "age_short"
        case genderLabel = "gender_label"
        case microchipId = "microchip_id"
        case photoUrl = "photo_url"
        case isPassedAway = "is_passed_away"
        case passedAwayDate = "passed_away_date"
        case vetName = "vet_name"
        case vetPhone = "vet_phone"
        case vetClinic = "vet_clinic"
        case vetAddress = "vet_address"
        case insuranceProvider = "insurance_provider"
        case insurancePolicyNumber = "insurance_policy_number"
        case overdueVaccinations = "overdue_vaccinations"
        case upcomingVaccinations = "upcoming_vaccinations"
        case activeMedications = "active_medications"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: Pet, rhs: Pet) -> Bool { lhs.id == rhs.id }
}

struct Vaccination: Codable, Identifiable {
    let id: Int
    let name: String
    let dateGiven: String?
    let administeredDate: String?
    let nextDueDate: String?
    let nextDueDateRaw: String?
    let administeredBy: String?
    let batchNumber: String?
    let status: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, notes, status
        case dateGiven = "date_given"
        case administeredDate = "administered_date"
        case nextDueDate = "next_due_date"
        case nextDueDateRaw = "next_due_date_raw"
        case administeredBy = "administered_by"
        case batchNumber = "batch_number"
    }
}

struct Medication: Codable, Identifiable {
    let id: Int
    let name: String
    let dosage: String?
    let frequency: String?
    let startDate: String?
    let endDate: String?
    let prescribedBy: String?
    let reason: String?
    let isActive: Bool?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, dosage, frequency, notes, reason
        case startDate = "start_date"
        case endDate = "end_date"
        case prescribedBy = "prescribed_by"
        case isActive = "is_active"
    }
}

struct PetsResponse: Codable {
    let pets: [Pet]?
    let totalPets: Int?
    let upcomingVaccinations: Int?
    let overdueVaccinations: Int?

    enum CodingKeys: String, CodingKey {
        case pets
        case totalPets = "total_pets"
        case upcomingVaccinations = "upcoming_vaccinations"
        case overdueVaccinations = "overdue_vaccinations"
    }
}

struct PetDetailResponse: Codable {
    let pet: Pet
    let vaccinations: [Vaccination]?
    let medications: [Medication]?
    let stats: PetStats?
}

struct PetStats: Codable {
    let overdueVaccinations: Int?
    let dueSoonVaccinations: Int?
    let activeMedications: Int?
    let totalVaccinations: Int?
    let totalMedications: Int?

    enum CodingKeys: String, CodingKey {
        case overdueVaccinations = "overdue_vaccinations"
        case dueSoonVaccinations = "due_soon_vaccinations"
        case activeMedications = "active_medications"
        case totalVaccinations = "total_vaccinations"
        case totalMedications = "total_medications"
    }
}
