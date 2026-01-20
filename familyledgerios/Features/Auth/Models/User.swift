import Foundation

enum UserRole: String, Codable, CaseIterable {
    case parent
    case coparent
    case guardian
    case advisor
    case viewer

    var displayName: String {
        switch self {
        case .parent: return "Parent"
        case .coparent: return "Co-Parent"
        case .guardian: return "Guardian"
        case .advisor: return "Advisor"
        case .viewer: return "Viewer"
        }
    }
}

enum AuthProvider: String, Codable {
    case email
    case google
    case apple
    case facebook
}

struct User: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let firstName: String?
    let lastName: String?
    let email: String
    let phone: String?
    let role: UserRole?
    let roleName: String?
    let avatar: String?
    let authProvider: AuthProvider?
    let emailVerified: Bool?
    let mfaEnabled: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, role, avatar
        case firstName = "first_name"
        case lastName = "last_name"
        case roleName = "role_name"
        case authProvider = "auth_provider"
        case emailVerified = "email_verified"
        case mfaEnabled = "mfa_enabled"
        case createdAt = "created_at"
    }

    var displayName: String {
        if let firstName = firstName, !firstName.isEmpty {
            if let lastName = lastName, !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return name
    }

    var initials: String {
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1)) + String(names[1].prefix(1))
        } else if let first = names.first {
            return String(first.prefix(2))
        }
        return "?"
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
