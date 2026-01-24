import SwiftUI

enum AppRoute: Hashable {
    // Family
    case familyCircle(id: Int)
    case familyMember(circleId: Int, memberId: Int)

    // Expenses
    case expenses
    case expense(id: Int)
    case createExpense
    case budget(id: Int)
    case createBudget

    // Goals & Tasks
    case goals
    case goal(id: Int)
    case createGoal
    case task(id: Int)
    case createTask(goalId: Int? = nil)

    // Journal
    case journal
    case journalEntry(id: Int)
    case createJournalEntry

    // Shopping
    case shopping
    case shoppingList(id: Int)
    case createShoppingList

    // Pets
    case pets
    case pet(id: Int)
    case createPet

    // People
    case people
    case person(id: Int)
    case createPerson

    // Reminders
    case reminders
    case reminder(id: Int)
    case createReminder

    // Documents
    case documents
    case insurancePolicy(id: Int)
    case taxReturn(id: Int)
    case createInsurancePolicy
    case createTaxReturn

    // Member Documents - View
    case memberDriversLicense(circleId: Int, memberId: Int, document: MemberDocument?)
    case memberPassport(circleId: Int, memberId: Int, document: MemberDocument?)
    case memberSocialSecurity(circleId: Int, memberId: Int, document: MemberDocument?)
    case memberBirthCertificate(circleId: Int, memberId: Int, document: MemberDocument?)

    // Member Documents - Edit/Create
    case editDriversLicense(circleId: Int, memberId: Int, document: MemberDocument?)
    case editPassport(circleId: Int, memberId: Int, document: MemberDocument?)
    case editSocialSecurity(circleId: Int, memberId: Int, document: MemberDocument?)
    case editBirthCertificate(circleId: Int, memberId: Int, document: MemberDocument?)

    // Member Medical & Emergency Contacts - Edit
    case editMedicalInfo(circleId: Int, memberId: Int, medicalInfo: MedicalInfo?)
    case editEmergencyContact(circleId: Int, memberId: Int, contact: MemberContact?)
    case addEmergencyContact(circleId: Int, memberId: Int)

    // Member Health & Medical (comprehensive view)
    case memberMedicalInfo(circleId: Int, memberId: Int)

    // Resources
    case resources
    case resource(id: Int)
    case familyResource(circleId: Int, resourceId: Int)

    // Legal Documents
    case legalDocument(circleId: Int, documentId: Int)

    // Assets
    case asset(id: Int)

    // Co-Parenting
    case coparenting
    case coparentingSchedule
    case coparentingActivities
    case coparentingChild(id: Int)
    case coparentingMessages
    case coparentingMessageThread(id: Int)

    // Settings
    case settings
    case editProfile
}

@Observable
final class AppRouter {
    var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func goToRoot() {
        path = NavigationPath()
    }
}

// MARK: - Environment Key

struct AppRouterKey: EnvironmentKey {
    static let defaultValue = AppRouter()
}

extension EnvironmentValues {
    var router: AppRouter {
        get { self[AppRouterKey.self] }
        set { self[AppRouterKey.self] = newValue }
    }
}
