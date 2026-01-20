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
}
