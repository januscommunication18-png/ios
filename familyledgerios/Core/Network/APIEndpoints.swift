import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

enum APIEndpoint {
    // MARK: - Auth
    case login
    case otpRequest
    case otpVerify
    case otpResend
    case getUser
    case logout
    case refreshToken
    case forgotPassword
    case resetPassword
    case resendResetCode

    // MARK: - Dashboard
    case dashboard
    case dashboardStats

    // MARK: - Family Circles
    case familyCircles
    case familyCircle(id: Int)
    case familyCircleMembers(circleId: Int)
    case familyCircleMember(circleId: Int, memberId: Int)
    case familyCircleResources(circleId: Int)
    case familyCircleLegalDocuments(circleId: Int)

    // MARK: - Expenses
    case expenses
    case expense(id: Int)
    case expenseCategories
    case createExpense
    case updateExpense(id: Int)
    case deleteExpense(id: Int)
    case settleExpense(id: Int)

    // MARK: - Budgets
    case budgets
    case budget(id: Int)

    // MARK: - Assets
    case assets
    case assetsByCategory(category: String)
    case asset(id: Int)

    // MARK: - Goals
    case goals
    case goal(id: Int)
    case createGoal
    case updateGoal(id: Int)
    case deleteGoal(id: Int)
    case goalProgress(id: Int)
    case pauseGoal(id: Int)
    case resumeGoal(id: Int)
    case completeGoal(id: Int)

    // MARK: - Tasks
    case tasks
    case task(id: Int)
    case createTask
    case updateTask(id: Int)
    case deleteTask(id: Int)
    case toggleTask(id: Int)
    case snoozeTask(id: Int)

    // MARK: - Journal
    case journal
    case journalEntry(id: Int)
    case createJournalEntry
    case updateJournalEntry(id: Int)
    case deleteJournalEntry(id: Int)
    case togglePinJournalEntry(id: Int)

    // MARK: - Shopping
    case shoppingLists
    case shoppingList(id: Int)
    case createShoppingList
    case updateShoppingList(id: Int)
    case deleteShoppingList(id: Int)
    case addShoppingItem(listId: Int)
    case updateShoppingItem(listId: Int, itemId: Int)
    case deleteShoppingItem(listId: Int, itemId: Int)
    case toggleShoppingItem(listId: Int, itemId: Int)
    case clearCheckedItems(listId: Int)

    // MARK: - Pets
    case pets
    case pet(id: Int)
    case createPet
    case updatePet(id: Int)
    case deletePet(id: Int)
    case addVaccination(petId: Int)
    case updateVaccination(petId: Int, vaccinationId: Int)
    case deleteVaccination(petId: Int, vaccinationId: Int)
    case addMedication(petId: Int)
    case updateMedication(petId: Int, medicationId: Int)
    case deleteMedication(petId: Int, medicationId: Int)

    // MARK: - People
    case people
    case person(id: Int)
    case searchPeople
    case peopleByRelationship(type: String)
    case createPerson
    case updatePerson(id: Int)
    case deletePerson(id: Int)

    // MARK: - Reminders
    case reminders
    case reminder(id: Int)
    case createReminder
    case updateReminder(id: Int)
    case deleteReminder(id: Int)
    case completeReminder(id: Int)
    case snoozeReminder(id: Int)
    case pauseReminder(id: Int)
    case resumeReminder(id: Int)

    // MARK: - Documents
    case documents
    case insurancePolicies
    case insurancePolicy(id: Int)
    case createInsurancePolicy
    case updateInsurancePolicy(id: Int)
    case deleteInsurancePolicy(id: Int)
    case taxReturns
    case taxReturn(id: Int)
    case createTaxReturn
    case updateTaxReturn(id: Int)
    case deleteTaxReturn(id: Int)

    // MARK: - Resources
    case resources
    case resource(id: Int)
    case resourcesByType(type: String)
    case createResource
    case updateResource(id: Int)
    case deleteResource(id: Int)

    // MARK: - Legal Documents
    case legalDocuments
    case legalDocument(id: Int)

    // MARK: - Co-Parenting
    case coparenting
    case coparentingChildren
    case coparentingChild(id: Int)
    case coparentingSchedule
    case coparentingActivities
    case coparentingActualTime
    case coparentingConversations
    case coparentingConversation(id: Int)
    case createCoparentingConversation
    case sendCoparentingMessage(conversationId: Int)

    // MARK: - Onboarding
    case updateOnboarding

    var path: String {
        switch self {
        // Auth
        case .login: return "/auth/login"
        case .otpRequest: return "/auth/otp/request"
        case .otpVerify: return "/auth/otp/verify"
        case .otpResend: return "/auth/otp/resend"
        case .getUser: return "/auth/user"
        case .logout: return "/auth/logout"
        case .refreshToken: return "/auth/refresh"
        case .forgotPassword: return "/auth/password/forgot"
        case .resetPassword: return "/auth/password/reset"
        case .resendResetCode: return "/auth/password/resend"

        // Dashboard
        case .dashboard: return "/dashboard"
        case .dashboardStats: return "/dashboard/stats"

        // Family Circles
        case .familyCircles: return "/family-circles"
        case .familyCircle(let id): return "/family-circles/\(id)"
        case .familyCircleMembers(let circleId): return "/family-circles/\(circleId)/members"
        case .familyCircleMember(let circleId, let memberId): return "/family-circles/\(circleId)/members/\(memberId)"
        case .familyCircleResources(let circleId): return "/family-circles/\(circleId)/resources"
        case .familyCircleLegalDocuments(let circleId): return "/family-circles/\(circleId)/legal-documents"

        // Expenses
        case .expenses, .createExpense: return "/expenses"
        case .expense(let id), .updateExpense(let id), .deleteExpense(let id): return "/expenses/\(id)"
        case .expenseCategories: return "/expenses/categories"
        case .settleExpense(let id): return "/expenses/\(id)/settle"

        // Budgets
        case .budgets: return "/budgets"
        case .budget(let id): return "/budgets/\(id)"

        // Assets
        case .assets: return "/assets"
        case .assetsByCategory(let category): return "/assets/category/\(category)"
        case .asset(let id): return "/assets/\(id)"

        // Goals
        case .goals, .createGoal: return "/goals"
        case .goal(let id), .updateGoal(let id), .deleteGoal(let id): return "/goals/\(id)"
        case .goalProgress(let id): return "/goals/\(id)/progress"
        case .pauseGoal(let id): return "/goals/\(id)/pause"
        case .resumeGoal(let id): return "/goals/\(id)/resume"
        case .completeGoal(let id): return "/goals/\(id)/complete"

        // Tasks
        case .tasks, .createTask: return "/tasks"
        case .task(let id), .updateTask(let id), .deleteTask(let id): return "/tasks/\(id)"
        case .toggleTask(let id): return "/tasks/\(id)/toggle"
        case .snoozeTask(let id): return "/tasks/\(id)/snooze"

        // Journal
        case .journal, .createJournalEntry: return "/journal"
        case .journalEntry(let id), .updateJournalEntry(let id), .deleteJournalEntry(let id): return "/journal/\(id)"
        case .togglePinJournalEntry(let id): return "/journal/\(id)/toggle-pin"

        // Shopping
        case .shoppingLists, .createShoppingList: return "/shopping"
        case .shoppingList(let id), .updateShoppingList(let id), .deleteShoppingList(let id): return "/shopping/\(id)"
        case .addShoppingItem(let listId): return "/shopping/\(listId)/items"
        case .updateShoppingItem(let listId, let itemId), .deleteShoppingItem(let listId, let itemId): return "/shopping/\(listId)/items/\(itemId)"
        case .toggleShoppingItem(let listId, let itemId): return "/shopping/\(listId)/items/\(itemId)/toggle"
        case .clearCheckedItems(let listId): return "/shopping/\(listId)/clear-checked"

        // Pets
        case .pets, .createPet: return "/pets"
        case .pet(let id), .updatePet(let id), .deletePet(let id): return "/pets/\(id)"
        case .addVaccination(let petId): return "/pets/\(petId)/vaccinations"
        case .updateVaccination(let petId, let vaccinationId), .deleteVaccination(let petId, let vaccinationId): return "/pets/\(petId)/vaccinations/\(vaccinationId)"
        case .addMedication(let petId): return "/pets/\(petId)/medications"
        case .updateMedication(let petId, let medicationId), .deleteMedication(let petId, let medicationId): return "/pets/\(petId)/medications/\(medicationId)"

        // People
        case .people, .createPerson: return "/people"
        case .person(let id), .updatePerson(let id), .deletePerson(let id): return "/people/\(id)"
        case .searchPeople: return "/people/search"
        case .peopleByRelationship(let type): return "/people/relationship/\(type)"

        // Reminders
        case .reminders, .createReminder: return "/reminders"
        case .reminder(let id), .updateReminder(let id), .deleteReminder(let id): return "/reminders/\(id)"
        case .completeReminder(let id): return "/reminders/\(id)/complete"
        case .snoozeReminder(let id): return "/reminders/\(id)/snooze"
        case .pauseReminder(let id): return "/reminders/\(id)/pause"
        case .resumeReminder(let id): return "/reminders/\(id)/resume"

        // Documents
        case .documents: return "/documents"
        case .insurancePolicies, .createInsurancePolicy: return "/documents/insurance"
        case .insurancePolicy(let id), .updateInsurancePolicy(let id), .deleteInsurancePolicy(let id): return "/documents/insurance/\(id)"
        case .taxReturns, .createTaxReturn: return "/documents/tax-returns"
        case .taxReturn(let id), .updateTaxReturn(let id), .deleteTaxReturn(let id): return "/documents/tax-returns/\(id)"

        // Resources
        case .resources, .createResource: return "/resources"
        case .resource(let id), .updateResource(let id), .deleteResource(let id): return "/resources/\(id)"
        case .resourcesByType(let type): return "/resources/type/\(type)"

        // Legal Documents
        case .legalDocuments: return "/legal-documents"
        case .legalDocument(let id): return "/legal-documents/\(id)"

        // Co-Parenting
        case .coparenting: return "/coparenting"
        case .coparentingChildren: return "/coparenting/children"
        case .coparentingChild(let id): return "/coparenting/children/\(id)"
        case .coparentingSchedule: return "/coparenting/schedule"
        case .coparentingActivities: return "/coparenting/activities"
        case .coparentingActualTime: return "/coparenting/actual-time"
        case .coparentingConversations, .createCoparentingConversation: return "/coparenting/conversations"
        case .coparentingConversation(let id): return "/coparenting/conversations/\(id)"
        case .sendCoparentingMessage(let conversationId): return "/coparenting/conversations/\(conversationId)/messages"

        // Onboarding
        case .updateOnboarding: return "/onboarding"
        }
    }

    var method: HTTPMethod {
        switch self {
        // GET requests
        case .getUser, .dashboard, .dashboardStats,
             .familyCircles, .familyCircle, .familyCircleMembers, .familyCircleMember,
             .familyCircleResources, .familyCircleLegalDocuments,
             .expenses, .expense, .expenseCategories,
             .budgets, .budget,
             .assets, .assetsByCategory, .asset,
             .goals, .goal,
             .tasks, .task,
             .journal, .journalEntry,
             .shoppingLists, .shoppingList,
             .pets, .pet,
             .people, .person, .searchPeople, .peopleByRelationship,
             .reminders, .reminder,
             .documents, .insurancePolicies, .insurancePolicy, .taxReturns, .taxReturn,
             .resources, .resource, .resourcesByType,
             .legalDocuments, .legalDocument,
             .coparenting, .coparentingChildren, .coparentingChild,
             .coparentingSchedule, .coparentingActivities, .coparentingActualTime,
             .coparentingConversations, .coparentingConversation:
            return .GET

        // POST requests
        case .login, .otpRequest, .otpVerify, .otpResend, .logout, .refreshToken,
             .forgotPassword, .resetPassword, .resendResetCode,
             .createExpense, .settleExpense,
             .createGoal, .goalProgress, .pauseGoal, .resumeGoal, .completeGoal,
             .createTask, .toggleTask, .snoozeTask,
             .createJournalEntry, .togglePinJournalEntry,
             .createShoppingList, .addShoppingItem, .toggleShoppingItem, .clearCheckedItems,
             .createPet, .addVaccination, .addMedication,
             .createPerson,
             .createReminder, .completeReminder, .snoozeReminder, .pauseReminder, .resumeReminder,
             .createInsurancePolicy, .createTaxReturn,
             .createResource,
             .createCoparentingConversation, .sendCoparentingMessage,
             .updateOnboarding:
            return .POST

        // PUT requests
        case .updateExpense, .updateGoal, .updateTask, .updateJournalEntry,
             .updateShoppingList, .updateShoppingItem,
             .updatePet, .updateVaccination, .updateMedication,
             .updatePerson, .updateReminder,
             .updateInsurancePolicy, .updateTaxReturn, .updateResource:
            return .PUT

        // DELETE requests
        case .deleteExpense, .deleteGoal, .deleteTask, .deleteJournalEntry,
             .deleteShoppingList, .deleteShoppingItem,
             .deletePet, .deleteVaccination, .deleteMedication,
             .deletePerson, .deleteReminder,
             .deleteInsurancePolicy, .deleteTaxReturn, .deleteResource:
            return .DELETE
        }
    }
}
