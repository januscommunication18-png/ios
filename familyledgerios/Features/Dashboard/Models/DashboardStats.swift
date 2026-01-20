import Foundation

struct DashboardStats: Decodable {
    let familyCircles: Int?
    let familyMembers: Int?
    let assets: Int?
    let totalAssetValue: Double?
    let formattedAssetValue: String?

    enum CodingKeys: String, CodingKey {
        case familyCircles = "family_circles"
        case familyMembers = "family_members"
        case assets
        case totalAssetValue = "total_asset_value"
        case formattedAssetValue = "formatted_asset_value"
    }
}

struct QuickAction: Decodable, Identifiable {
    let id: String
    let title: String
    let icon: String
    let route: String
}

struct DashboardOverview: Decodable {
    let user: User?
    let tenant: Tenant?
    let stats: DashboardStats?
    let quickActions: [QuickAction]?

    enum CodingKeys: String, CodingKey {
        case user, tenant, stats
        case quickActions = "quick_actions"
    }
}

struct RecentActivity: Decodable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let description: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, type, title, description
        case createdAt = "created_at"
    }

    var icon: String {
        switch type.lowercased() {
        case "expense": return "dollarsign.circle"
        case "goal": return "target"
        case "task": return "checkmark.circle"
        case "journal": return "book"
        case "reminder": return "bell"
        case "family": return "person.3"
        default: return "circle"
        }
    }
}

struct UpcomingReminder: Decodable, Identifiable {
    let id: Int
    let title: String
    let dueDate: String
    let priority: String

    enum CodingKeys: String, CodingKey {
        case id, title, priority
        case dueDate = "due_date"
    }
}
