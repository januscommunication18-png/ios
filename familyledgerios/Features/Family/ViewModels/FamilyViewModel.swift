import Foundation

@Observable
final class FamilyViewModel {
    var circles: [FamilyCircle] = []
    var selectedCircle: FamilyCircle?
    var members: [FamilyMemberBasic] = []
    var selectedMember: FamilyMember?
    var familyResources: [FamilyResource] = []
    var legalDocuments: [LegalDocument] = []

    var isLoading = false
    var isRefreshing = false
    var isLoadingResources = false
    var isLoadingLegalDocs = false
    var errorMessage: String?

    // MARK: - Computed Properties

    var hasCircles: Bool {
        !circles.isEmpty
    }

    var hasMembers: Bool {
        !members.isEmpty
    }

    var hasFamilyResources: Bool {
        !familyResources.isEmpty
    }

    var hasLegalDocuments: Bool {
        !legalDocuments.isEmpty
    }

    // MARK: - Circles Methods

    @MainActor
    func loadCircles() async {
        isLoading = circles.isEmpty
        errorMessage = nil

        do {
            let response: FamilyCirclesResponse = try await APIClient.shared.request(.familyCircles)
            circles = response.familyCircles ?? []
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch let decodingError as DecodingError {
            errorMessage = "Failed to decode: \(decodingError)"
        } catch {
            errorMessage = "Failed to load family circles: \(error)"
        }

        isLoading = false
    }

    @MainActor
    func refreshCircles() async {
        isRefreshing = true

        do {
            let response: FamilyCirclesResponse = try await APIClient.shared.request(.familyCircles)
            circles = response.familyCircles ?? []
        } catch {
            // Silently fail on refresh
        }

        isRefreshing = false
    }

    @MainActor
    func createCircle(name: String, description: String?, includeMe: Bool, photo: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let request = CreateFamilyCircleRequest(
                name: name,
                description: description,
                includeMe: includeMe,
                photo: photo
            )
            let response: FamilyCircleDetailResponse = try await APIClient.shared.request(.createFamilyCircle, body: request)

            // Add the new circle to the list
            circles.insert(response.familyCircle, at: 0)
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create family circle"
        }

        isLoading = false
        return false
    }

    @MainActor
    func loadCircle(id: Int) async {
        isLoading = selectedCircle == nil
        errorMessage = nil

        do {
            let response: FamilyCircleDetailResponse = try await APIClient.shared.request(.familyCircle(id: id))
            selectedCircle = response.familyCircle
            members = response.familyCircle.members ?? []
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load family circle"
        }

        isLoading = false
    }

    // MARK: - Members Methods

    @MainActor
    func loadMembers(circleId: Int) async {
        isLoading = members.isEmpty
        errorMessage = nil

        do {
            let response: FamilyMembersResponse = try await APIClient.shared.request(.familyCircleMembers(circleId: circleId))
            members = response.members ?? []
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load family members"
        }

        isLoading = false
    }

    @MainActor
    func refreshMembers(circleId: Int) async {
        isRefreshing = true

        do {
            let response: FamilyMembersResponse = try await APIClient.shared.request(.familyCircleMembers(circleId: circleId))
            members = response.members ?? []
        } catch {
            // Silently fail on refresh
        }

        isRefreshing = false
    }

    @MainActor
    func loadMember(circleId: Int, memberId: Int) async {
        isLoading = selectedMember == nil
        errorMessage = nil

        do {
            let response: FamilyMemberDetailResponse = try await APIClient.shared.request(.familyCircleMember(circleId: circleId, memberId: memberId))
            selectedMember = response.member
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load member details"
        }

        isLoading = false
    }

    @MainActor
    func updateMember(circleId: Int, memberId: Int, request: CreateFamilyMemberRequest) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: CreateFamilyMemberResponse = try await APIClient.shared.request(
                .updateFamilyCircleMember(circleId: circleId, memberId: memberId),
                body: request
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update family member"
        }

        isLoading = false
        return false
    }

    @MainActor
    func deleteMember(circleId: Int, memberId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteFamilyCircleMember(circleId: circleId, memberId: memberId)
            )

            // Remove from local list
            members.removeAll { $0.id == memberId }
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete family member"
        }

        isLoading = false
        return false
    }

    // MARK: - Filtering

    func filterMembers(by relationship: String?) -> [FamilyMemberBasic] {
        guard let relationship = relationship else { return members }
        return members.filter { $0.relationship == relationship }
    }

    func searchMembers(query: String) -> [FamilyMemberBasic] {
        guard !query.isEmpty else { return members }
        let lowercasedQuery = query.lowercased()
        return members.filter {
            ($0.fullName?.lowercased().contains(lowercasedQuery) == true) ||
            ($0.email?.lowercased().contains(lowercasedQuery) == true)
        }
    }

    // MARK: - Family Resources Methods

    @MainActor
    func loadFamilyResources(circleId: Int) async {
        isLoadingResources = familyResources.isEmpty

        do {
            let response: FamilyResourcesResponse = try await APIClient.shared.request(.familyCircleResources(circleId: circleId))
            familyResources = response.familyResources ?? []
        } catch {
            // Silently fail, empty state will be shown
            familyResources = []
        }

        isLoadingResources = false
    }

    // MARK: - Legal Documents Methods

    @MainActor
    func loadLegalDocuments(circleId: Int) async {
        isLoadingLegalDocs = legalDocuments.isEmpty

        do {
            let response: LegalDocumentsResponse = try await APIClient.shared.request(.familyCircleLegalDocuments(circleId: circleId))
            legalDocuments = response.legalDocuments ?? []
        } catch {
            // Silently fail, empty state will be shown
            legalDocuments = []
        }

        isLoadingLegalDocs = false
    }

    // MARK: - Member Documents

    @MainActor
    func createDocument(circleId: Int, memberId: Int, request: MemberDocumentRequest) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: MemberDocumentResponse = try await APIClient.shared.request(
                .createMemberDocument(circleId: circleId, memberId: memberId),
                body: request
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create document"
        }

        isLoading = false
        return false
    }

    @MainActor
    func updateDocument(circleId: Int, memberId: Int, documentId: Int, request: MemberDocumentRequest) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: MemberDocumentResponse = try await APIClient.shared.request(
                .updateMemberDocument(circleId: circleId, memberId: memberId, documentId: documentId),
                body: request
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update document"
        }

        isLoading = false
        return false
    }

    @MainActor
    func deleteDocument(circleId: Int, memberId: Int, documentId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteMemberDocument(circleId: circleId, memberId: memberId, documentId: documentId)
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete document"
        }

        isLoading = false
        return false
    }

    // MARK: - Medical Info

    @MainActor
    func updateMedicalInfo(circleId: Int, memberId: Int, request: MemberMedicalInfoRequest) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: MemberMedicalInfoResponse = try await APIClient.shared.request(
                .updateMemberMedicalInfo(circleId: circleId, memberId: memberId),
                body: request
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update medical information"
        }

        isLoading = false
        return false
    }

    // MARK: - Emergency Contacts

    @MainActor
    func createEmergencyContact(circleId: Int, memberId: Int, request: MemberEmergencyContactRequest) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: MemberEmergencyContactResponse = try await APIClient.shared.request(
                .createMemberEmergencyContact(circleId: circleId, memberId: memberId),
                body: request
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create emergency contact"
        }

        isLoading = false
        return false
    }

    @MainActor
    func updateEmergencyContact(circleId: Int, memberId: Int, contactId: Int, request: MemberEmergencyContactRequest) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: MemberEmergencyContactResponse = try await APIClient.shared.request(
                .updateMemberEmergencyContact(circleId: circleId, memberId: memberId, contactId: contactId),
                body: request
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update emergency contact"
        }

        isLoading = false
        return false
    }

    @MainActor
    func deleteEmergencyContact(circleId: Int, memberId: Int, contactId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteMemberEmergencyContact(circleId: circleId, memberId: memberId, contactId: contactId)
            )
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete emergency contact"
        }

        isLoading = false
        return false
    }

    // MARK: - Fetch Member Detail (returns member directly)

    @MainActor
    func fetchMemberDetail(circleId: Int, memberId: Int) async -> FamilyMember? {
        do {
            let response: FamilyMemberDetailResponse = try await APIClient.shared.request(
                .familyCircleMember(circleId: circleId, memberId: memberId)
            )
            return response.member
        } catch {
            errorMessage = "Failed to load member details"
            return nil
        }
    }

    // MARK: - Medications

    @MainActor
    func createMedication(circleId: Int, memberId: Int, name: String, dosage: String?, frequency: String?, notes: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = MedicationRequest(name: name, dosage: dosage, frequency: frequency, notes: notes)
            let _: GenericResponse = try await APIClient.shared.request(
                .createMemberMedication(circleId: circleId, memberId: memberId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create medication"
        }
        return false
    }

    @MainActor
    func updateMedication(circleId: Int, memberId: Int, medicationId: Int, name: String, dosage: String?, frequency: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = MedicationRequest(name: name, dosage: dosage, frequency: frequency, notes: nil)
            let _: GenericResponse = try await APIClient.shared.request(
                .updateMemberMedication(circleId: circleId, memberId: memberId, medicationId: medicationId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update medication"
        }
        return false
    }

    @MainActor
    func deleteMedication(circleId: Int, memberId: Int, medicationId: Int) async -> Bool {
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteMemberMedication(circleId: circleId, memberId: memberId, medicationId: medicationId)
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete medication"
        }
        return false
    }

    // MARK: - Medical Conditions

    @MainActor
    func createCondition(circleId: Int, memberId: Int, name: String, status: String?, diagnosedDate: String?, notes: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = ConditionRequest(name: name, status: status, diagnosedDate: diagnosedDate, notes: notes)
            let _: GenericResponse = try await APIClient.shared.request(
                .createMemberCondition(circleId: circleId, memberId: memberId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create condition"
        }
        return false
    }

    @MainActor
    func updateCondition(circleId: Int, memberId: Int, conditionId: Int, name: String, status: String?, diagnosedDate: String?, notes: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = ConditionRequest(name: name, status: status, diagnosedDate: diagnosedDate, notes: notes)
            let _: GenericResponse = try await APIClient.shared.request(
                .updateMemberCondition(circleId: circleId, memberId: memberId, conditionId: conditionId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update condition"
        }
        return false
    }

    @MainActor
    func deleteCondition(circleId: Int, memberId: Int, conditionId: Int) async -> Bool {
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteMemberCondition(circleId: circleId, memberId: memberId, conditionId: conditionId)
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete condition"
        }
        return false
    }

    // MARK: - Allergies

    @MainActor
    func createAllergy(circleId: Int, memberId: Int, allergyType: String, allergenName: String, severity: String, reaction: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = AllergyRequest(allergyType: allergyType, allergenName: allergenName, severity: severity, reaction: reaction)
            let _: GenericResponse = try await APIClient.shared.request(
                .createMemberAllergy(circleId: circleId, memberId: memberId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create allergy"
        }
        return false
    }

    @MainActor
    func updateAllergy(circleId: Int, memberId: Int, allergyId: Int, allergyType: String?, allergenName: String, severity: String, reaction: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = AllergyRequest(allergyType: allergyType, allergenName: allergenName, severity: severity, reaction: reaction)
            let _: GenericResponse = try await APIClient.shared.request(
                .updateMemberAllergy(circleId: circleId, memberId: memberId, allergyId: allergyId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update allergy"
        }
        return false
    }

    @MainActor
    func deleteAllergy(circleId: Int, memberId: Int, allergyId: Int) async -> Bool {
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteMemberAllergy(circleId: circleId, memberId: memberId, allergyId: allergyId)
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete allergy"
        }
        return false
    }

    // MARK: - Healthcare Providers

    @MainActor
    func createProvider(circleId: Int, memberId: Int, providerType: String, name: String, specialty: String?, clinicName: String?, phone: String?, email: String?, isPrimary: Bool) async -> Bool {
        errorMessage = nil

        do {
            let request = ProviderRequest(providerType: providerType, name: name, specialty: specialty, clinicName: clinicName, phone: phone, email: email, isPrimary: isPrimary)
            let _: GenericResponse = try await APIClient.shared.request(
                .createMemberProvider(circleId: circleId, memberId: memberId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create provider"
        }
        return false
    }

    @MainActor
    func updateProvider(circleId: Int, memberId: Int, providerId: Int, providerType: String, name: String, specialty: String?, clinicName: String?, phone: String?, email: String?, isPrimary: Bool) async -> Bool {
        errorMessage = nil

        do {
            let request = ProviderRequest(providerType: providerType, name: name, specialty: specialty, clinicName: clinicName, phone: phone, email: email, isPrimary: isPrimary)
            let _: GenericResponse = try await APIClient.shared.request(
                .updateMemberProvider(circleId: circleId, memberId: memberId, providerId: providerId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update provider"
        }
        return false
    }

    @MainActor
    func deleteProvider(circleId: Int, memberId: Int, providerId: Int) async -> Bool {
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteMemberProvider(circleId: circleId, memberId: memberId, providerId: providerId)
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete provider"
        }
        return false
    }

    // MARK: - Vaccinations

    @MainActor
    func createVaccination(circleId: Int, memberId: Int, vaccineType: String, vaccineName: String?, customVaccineName: String?, vaccinationDate: String?, nextVaccinationDate: String?, administeredBy: String?, lotNumber: String?, notes: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = VaccinationRequest(
                vaccineType: vaccineType,
                vaccineName: vaccineName,
                customVaccineName: customVaccineName,
                vaccinationDate: vaccinationDate,
                nextVaccinationDate: nextVaccinationDate,
                administeredBy: administeredBy,
                lotNumber: lotNumber,
                notes: notes
            )
            let _: GenericResponse = try await APIClient.shared.request(
                .createMemberVaccination(circleId: circleId, memberId: memberId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create vaccination"
        }
        return false
    }

    @MainActor
    func updateVaccination(circleId: Int, memberId: Int, vaccinationId: Int, vaccineType: String, vaccineName: String?, customVaccineName: String?, vaccinationDate: String?, nextVaccinationDate: String?, administeredBy: String?, lotNumber: String?, notes: String?) async -> Bool {
        errorMessage = nil

        do {
            let request = VaccinationRequest(
                vaccineType: vaccineType,
                vaccineName: vaccineName,
                customVaccineName: customVaccineName,
                vaccinationDate: vaccinationDate,
                nextVaccinationDate: nextVaccinationDate,
                administeredBy: administeredBy,
                lotNumber: lotNumber,
                notes: notes
            )
            let _: GenericResponse = try await APIClient.shared.request(
                .updateMemberVaccination(circleId: circleId, memberId: memberId, vaccinationId: vaccinationId),
                body: request
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update vaccination"
        }
        return false
    }

    @MainActor
    func deleteVaccination(circleId: Int, memberId: Int, vaccinationId: Int) async -> Bool {
        errorMessage = nil

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                .deleteMemberVaccination(circleId: circleId, memberId: memberId, vaccinationId: vaccinationId)
            )
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete vaccination"
        }
        return false
    }
}

// MARK: - Request Models

struct MedicationRequest: Encodable {
    let name: String
    let dosage: String?
    let frequency: String?
    let notes: String?
}

struct ConditionRequest: Encodable {
    let name: String
    let status: String?
    let diagnosedDate: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case name, status, notes
        case diagnosedDate = "diagnosed_date"
    }
}

struct AllergyRequest: Encodable {
    let allergyType: String?
    let allergenName: String
    let severity: String
    let reaction: String?

    enum CodingKeys: String, CodingKey {
        case severity, reaction
        case allergyType = "allergy_type"
        case allergenName = "allergen_name"
    }
}

struct ProviderRequest: Encodable {
    let providerType: String
    let name: String
    let specialty: String?
    let clinicName: String?
    let phone: String?
    let email: String?
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case name, specialty, phone, email
        case providerType = "provider_type"
        case clinicName = "clinic_name"
        case isPrimary = "is_primary"
    }
}

struct VaccinationRequest: Encodable {
    let vaccineType: String
    let vaccineName: String?
    let customVaccineName: String?
    let vaccinationDate: String?
    let nextVaccinationDate: String?
    let administeredBy: String?
    let lotNumber: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case vaccineType = "vaccine_type"
        case vaccineName = "vaccine_name"
        case customVaccineName = "custom_vaccine_name"
        case vaccinationDate = "vaccination_date"
        case nextVaccinationDate = "next_vaccination_date"
        case administeredBy = "administered_by"
        case lotNumber = "lot_number"
    }
}

// MARK: - Generic Response

struct GenericResponse: Codable {
    let message: String?
}
