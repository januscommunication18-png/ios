import Foundation

struct CoparentChild: Codable, Identifiable, Equatable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let fullName: String
    let dateOfBirth: String?
    let age: Int?
    let gender: String?
    let bloodType: String?
    let allergies: String?
    let medicalConditions: String?
    let medications: String?
    let schoolName: String?
    let grade: String?
    let notes: String?
    let profileImageUrl: String?
    let initials: String?
    let coparents: [ChildCoparent]?

    enum CodingKeys: String, CodingKey {
        case id, gender, allergies, medications, grade, notes, coparents, initials
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case age
        case bloodType = "blood_type"
        case medicalConditions = "medical_conditions"
        case schoolName = "school_name"
        case profileImageUrl = "profile_image_url"
    }

    static func == (lhs: CoparentChild, rhs: CoparentChild) -> Bool { lhs.id == rhs.id }
}

struct ChildCoparent: Codable, Identifiable {
    let id: Int
    let name: String?
    let displayName: String?
    let avatarUrl: String?
    let parentRole: String?
    let parentRoleLabel: String?
    let relationship: String?

    enum CodingKeys: String, CodingKey {
        case id, name, relationship
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case parentRole = "parent_role"
        case parentRoleLabel = "parent_role_label"
    }
}

struct CoparentingStats: Codable {
    let childrenCount: Int?
    let coparentsCount: Int?
    let pendingInvitesCount: Int?

    enum CodingKeys: String, CodingKey {
        case childrenCount = "children_count"
        case coparentsCount = "coparents_count"
        case pendingInvitesCount = "pending_invites_count"
    }
}

struct PendingInvite: Codable, Identifiable {
    let id: Int
    let email: String?
    let fullName: String?
    let parentRole: String?
    let parentRoleLabel: String?
    let childrenNames: String?
    let expiresAt: String?
    let expiresIn: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case parentRole = "parent_role"
        case parentRoleLabel = "parent_role_label"
        case childrenNames = "children_names"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
    }
}

struct CoparentingSchedule: Codable, Identifiable {
    let id: Int
    let name: String
    let templateType: String
    let beginsAt: String?
    let endsAt: String?
    let primaryParent: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case templateType = "template_type"
        case beginsAt = "begins_at"
        case endsAt = "ends_at"
        case primaryParent = "primary_parent"
    }
}

struct CoparentActivity: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let date: String
    let time: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, date, time, location
    }
}

struct CoparentConversation: Codable, Identifiable {
    let id: Int
    let title: String
    let lastMessage: String?
    let unreadCount: Int
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case updatedAt = "updated_at"
    }
}

struct CoparentMessage: Codable, Identifiable {
    let id: Int
    let content: String
    let category: String
    let sender: MessageSender
    let isOwn: Bool
    let wasEdited: Bool
    let attachments: [MessageAttachment]?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, content, category, sender, attachments
        case isOwn = "is_own"
        case wasEdited = "was_edited"
        case createdAt = "created_at"
    }
}

struct MessageSender: Codable {
    let id: Int
    let name: String
    let avatar: String?
}

struct MessageAttachment: Codable, Identifiable {
    let id: Int
    let name: String
    let url: String
}

struct CoparentingDashboardResponse: Codable {
    let children: [CoparentChild]?
    let coparents: [ChildCoparent]?
    let pendingInvites: [PendingInvite]?
    let stats: CoparentingStats?
    let upcomingActivities: [CoparentActivity]?
    let recentMessages: [CoparentMessage]?
    let currentUser: CurrentCoparentUser?

    enum CodingKeys: String, CodingKey {
        case children, coparents, stats
        case pendingInvites = "pending_invites"
        case upcomingActivities = "upcoming_activities"
        case recentMessages = "recent_messages"
        case currentUser = "current_user"
    }
}

struct CurrentCoparentUser: Codable {
    let id: Int
    let name: String?
    let initials: String?
}
