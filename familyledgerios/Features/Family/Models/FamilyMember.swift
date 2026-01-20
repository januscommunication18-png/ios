import Foundation

enum RelationshipType: String, Codable, CaseIterable {
    case `self` = "self"
    case spouse = "spouse"
    case partner = "partner"
    case child = "child"
    case stepchild = "stepchild"
    case parent = "parent"
    case sibling = "sibling"
    case grandparent = "grandparent"
    case guardian = "guardian"
    case caregiver = "caregiver"
    case relative = "relative"
    case other = "other"

    var displayName: String {
        switch self {
        case .`self`: return "Self"
        case .spouse: return "Spouse"
        case .partner: return "Partner"
        case .child: return "Child"
        case .stepchild: return "Stepchild"
        case .parent: return "Parent"
        case .sibling: return "Sibling"
        case .grandparent: return "Grandparent"
        case .guardian: return "Guardian"
        case .caregiver: return "Caregiver"
        case .relative: return "Relative"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .`self`: return "person.fill"
        case .spouse, .partner: return "heart.fill"
        case .child, .stepchild: return "figure.child"
        case .parent: return "figure.stand"
        case .sibling: return "person.2.fill"
        case .grandparent: return "figure.walk"
        case .guardian, .caregiver: return "hand.raised.fill"
        case .relative: return "person.3.fill"
        case .other: return "person.fill.questionmark"
        }
    }
}

