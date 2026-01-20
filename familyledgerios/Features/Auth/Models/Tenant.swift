import Foundation

struct Tenant: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let slug: String?
    let country: String?
    let timezone: String?
    let subscriptionTier: String?
    let onboardingCompleted: Bool?
    let onboardingStep: Int?
    let goals: [String]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, country, timezone, goals
        case subscriptionTier = "subscription_tier"
        case onboardingCompleted = "onboarding_completed"
        case onboardingStep = "onboarding_step"
        case createdAt = "created_at"
    }

    // Handle id as either String or Int from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode id as String first, then as Int
        if let stringId = try? container.decode(String.self, forKey: .id) {
            id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: [CodingKeys.id], debugDescription: "Expected String or Int for id"))
        }

        name = try container.decode(String.self, forKey: .name)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        subscriptionTier = try container.decodeIfPresent(String.self, forKey: .subscriptionTier)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted)
        onboardingStep = try container.decodeIfPresent(Int.self, forKey: .onboardingStep)
        goals = try container.decodeIfPresent([String].self, forKey: .goals)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    static func == (lhs: Tenant, rhs: Tenant) -> Bool {
        lhs.id == rhs.id
    }
}
