import Foundation

struct CreateGoalRequest: Encodable {
    let title: String
    let description: String
    let targetDate: String
    let priority: String

    enum CodingKeys: String, CodingKey {
        case title, description, priority
        case targetDate = "target_date"
    }
}

struct CreateTaskRequest: Encodable {
    let title: String
    let description: String
    let dueDate: String
    let priority: String

    enum CodingKeys: String, CodingKey {
        case title, description, priority
        case dueDate = "due_date"
    }
}

@Observable
final class GoalsViewModel {
    var goals: [Goal] = []
    var tasks: [GoalTask] = []
    var selectedGoal: Goal?
    var selectedTask: GoalTask?

    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var successMessage: String?

    // Form fields
    var title = ""
    var description = ""
    var targetDate = Date()
    var priority: String = "medium"
    var dueDate = Date()
    var dueTime = Date()

    // MARK: - Computed Properties

    var hasGoals: Bool { !goals.isEmpty }
    var hasTasks: Bool { !tasks.isEmpty }

    var activeGoals: [Goal] { goals.filter { $0.status == "active" } }
    var completedGoals: [Goal] { goals.filter { $0.status == "completed" } }
    var pendingTasks: [GoalTask] { tasks.filter { $0.status == "pending" || $0.status == "in_progress" } }

    // MARK: - Goals Methods

    @MainActor
    func loadGoals() async {
        isLoading = goals.isEmpty && tasks.isEmpty
        errorMessage = nil

        do {
            let response: GoalsResponse = try await APIClient.shared.request(.goals)
            goals = response.goals ?? []
            tasks = response.tasks ?? []
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load goals"
        }

        isLoading = false
    }

    @MainActor
    func refreshGoals() async {
        isRefreshing = true
        do {
            let response: GoalsResponse = try await APIClient.shared.request(.goals)
            goals = response.goals ?? []
            tasks = response.tasks ?? []
        } catch { }
        isRefreshing = false
    }

    @MainActor
    func loadGoal(id: Int) async {
        print("🎯 Loading goal with id: \(id)")
        isLoading = true
        errorMessage = nil
        do {
            let response: GoalDetailResponse = try await APIClient.shared.request(.goal(id: id))
            selectedGoal = response.goal
            print("🎯 Successfully loaded goal: \(response.goal.title)")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("🎯 APIError loading goal: \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load goal: \(error.localizedDescription)"
            print("🎯 Error loading goal: \(error)")
        }
        isLoading = false
    }

    @MainActor
    func createGoal() async -> Bool {
        isLoading = true
        do {
            let body = CreateGoalRequest(
                title: title,
                description: description,
                targetDate: targetDate.apiDateString,
                priority: priority
            )
            let _: Goal = try await APIClient.shared.request(.createGoal, body: body)
            clearForm()
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create goal"
        }
        isLoading = false
        return false
    }

    @MainActor
    func deleteGoal(id: Int) async -> Bool {
        isLoading = true
        do {
            try await APIClient.shared.requestEmpty(.deleteGoal(id: id))
            goals.removeAll { $0.id == id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete goal"
        }
        isLoading = false
        return false
    }

    @MainActor
    func completeGoal(id: Int) async {
        do {
            let _: Goal = try await APIClient.shared.request(.completeGoal(id: id))
            await loadGoal(id: id)
        } catch { }
    }

    // MARK: - Tasks Methods

    @MainActor
    func loadTask(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let response: TaskDetailResponse = try await APIClient.shared.request(.task(id: id))
            selectedTask = response.task
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load task"
        }
        isLoading = false
    }

    @MainActor
    func createTask() async -> Bool {
        isLoading = true
        do {
            let body = CreateTaskRequest(
                title: title,
                description: description,
                dueDate: dueDate.apiDateString,
                priority: priority
            )
            let _: GoalTask = try await APIClient.shared.request(.createTask, body: body)
            clearForm()
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create task"
        }
        isLoading = false
        return false
    }

    @MainActor
    func toggleTask(id: Int) async {
        do {
            let _: GoalTask = try await APIClient.shared.request(.toggleTask(id: id))
            await loadTask(id: id)
        } catch { }
    }

    @MainActor
    func deleteTask(id: Int) async -> Bool {
        do {
            try await APIClient.shared.requestEmpty(.deleteTask(id: id))
            tasks.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "Failed to delete task"
        }
        return false
    }

    func clearForm() {
        title = ""
        description = ""
        targetDate = Date()
        priority = "medium"
        dueDate = Date()
        dueTime = Date()
    }

    func clearError() { errorMessage = nil }
}
