import Foundation

struct CreateGoalRequest: Encodable {
    let title: String
    let description: String?
    let category: String
    let goalType: String
    let habitFrequency: String?
    let milestoneTarget: Int?
    let milestoneUnit: String?
    let checkInFrequency: String?
    let rewardsEnabled: Bool
    let rewardType: String?
    let rewardCustom: String?
    let isKidGoal: Bool
    let visibleToKids: Bool
    let kidsCanUpdate: Bool
    let assignmentType: String
    let assignedMembers: [Int]?

    enum CodingKeys: String, CodingKey {
        case title, description, category
        case goalType = "goal_type"
        case habitFrequency = "habit_frequency"
        case milestoneTarget = "milestone_target"
        case milestoneUnit = "milestone_unit"
        case checkInFrequency = "check_in_frequency"
        case rewardsEnabled = "rewards_enabled"
        case rewardType = "reward_type"
        case rewardCustom = "reward_custom"
        case isKidGoal = "is_kid_goal"
        case visibleToKids = "visible_to_kids"
        case kidsCanUpdate = "kids_can_update"
        case assignmentType = "assignment_type"
        case assignedMembers = "assigned_members"
    }
}

struct CreateGoalResponse: Decodable {
    let goal: Goal
    let message: String?
}

struct CreateTaskRequest: Encodable {
    let title: String
    let description: String?
    let category: String
    let priority: String
    let dueDate: String?
    let dueTime: String?
    let goalId: Int?
    let countTowardGoal: Bool
    let assignees: [Int]?
    let isRecurring: Bool
    let recurrenceFrequency: String?
    let recurrenceInterval: Int?
    let sendReminder: Bool
    let reminderType: String?

    enum CodingKeys: String, CodingKey {
        case title, description, category, priority, assignees
        case dueDate = "due_date"
        case dueTime = "due_time"
        case goalId = "goal_id"
        case countTowardGoal = "count_toward_goal"
        case isRecurring = "is_recurring"
        case recurrenceFrequency = "recurrence_frequency"
        case recurrenceInterval = "recurrence_interval"
        case sendReminder = "send_reminder"
        case reminderType = "reminder_type"
    }
}

struct CreateTaskResponse: Decodable {
    let task: GoalTask
    let message: String?
}

@Observable
final class GoalsViewModel {
    var goals: [Goal] = []
    var tasks: [GoalTask] = []
    var selectedGoal: Goal?
    var selectedGoalTasks: [GoalTask] = []
    var selectedTask: GoalTask?

    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var successMessage: String?

    // Form fields - Basic
    var title = ""
    var description = ""
    var targetDate = Date()
    var priority: String = "medium"
    var dueDate = Date()
    var dueTime = Date()
    var hasDueDate = false
    var hasDueTime = false

    // Form fields - Task Creation
    var taskCategory: String = "home_chores"
    var taskGoalId: Int? = nil
    var countTowardGoal: Bool = true
    var taskAssignees: Set<Int> = []
    var isRecurring: Bool = false
    var recurrenceFrequency: String = "daily"
    var recurrenceInterval: Int = 1
    var sendReminder: Bool = false
    var reminderType: String = "at_time"

    // Form fields - Goal Creation
    var category: String = "personal_growth"
    var goalType: String = "one_time"
    var habitFrequency: String = ""
    var milestoneTarget: String = ""
    var milestoneUnit: String = ""
    var checkInFrequency: String = ""
    var rewardsEnabled: Bool = false
    var rewardType: String = ""
    var rewardCustom: String = ""
    var isKidGoal: Bool = false
    var visibleToKids: Bool = true
    var kidsCanUpdate: Bool = false
    var assignmentType: String = "individual"
    var selectedMembers: Set<Int> = []

    // MARK: - Computed Properties

    var hasGoals: Bool { !goals.isEmpty }
    var hasTasks: Bool { !tasks.isEmpty }

    var activeGoals: [Goal] { goals.filter { $0.status == "active" } }
    var completedGoals: [Goal] { goals.filter { $0.status == "completed" } }
    var pendingTasks: [GoalTask] { tasks.filter { $0.status == "open" || $0.status == "in_progress" } }

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
            selectedGoalTasks = response.tasks
            print("🎯 Successfully loaded goal: \(response.goal.title) with \(response.tasks.count) tasks")
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
        errorMessage = nil

        print("DEBUG: Creating goal with title: \(title)")

        do {
            let body = CreateGoalRequest(
                title: title,
                description: description.isEmpty ? nil : description,
                category: category,
                goalType: goalType,
                habitFrequency: goalType == "habit" && !habitFrequency.isEmpty ? habitFrequency : nil,
                milestoneTarget: goalType == "milestone" && !milestoneTarget.isEmpty ? Int(milestoneTarget) : nil,
                milestoneUnit: goalType == "milestone" && !milestoneUnit.isEmpty ? milestoneUnit : nil,
                checkInFrequency: !checkInFrequency.isEmpty ? checkInFrequency : nil,
                rewardsEnabled: rewardsEnabled,
                rewardType: rewardsEnabled && !rewardType.isEmpty ? rewardType : nil,
                rewardCustom: rewardsEnabled && rewardType == "custom" && !rewardCustom.isEmpty ? rewardCustom : nil,
                isKidGoal: isKidGoal,
                visibleToKids: visibleToKids,
                kidsCanUpdate: kidsCanUpdate,
                assignmentType: assignmentType,
                assignedMembers: selectedMembers.isEmpty ? nil : Array(selectedMembers)
            )

            print("DEBUG: Sending request to create goal...")
            let response: CreateGoalResponse = try await APIClient.shared.request(.createGoal, body: body)
            print("DEBUG: Goal created successfully with id: \(response.goal.id)")
            clearForm()
            isLoading = false
            return true
        } catch let error as APIError {
            print("DEBUG: APIError creating goal: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("DEBUG: Error creating goal: \(error)")
            errorMessage = "Failed to create goal: \(error.localizedDescription)"
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
        errorMessage = nil

        print("DEBUG: Creating task with title: \(title)")

        do {
            // Format time as HH:mm
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            let body = CreateTaskRequest(
                title: title,
                description: description.isEmpty ? nil : description,
                category: taskCategory,
                priority: priority,
                dueDate: hasDueDate ? dueDate.apiDateString : nil,
                dueTime: hasDueTime ? timeFormatter.string(from: dueTime) : nil,
                goalId: taskGoalId,
                countTowardGoal: taskGoalId != nil && countTowardGoal,
                assignees: taskAssignees.isEmpty ? nil : Array(taskAssignees),
                isRecurring: isRecurring,
                recurrenceFrequency: isRecurring ? recurrenceFrequency : nil,
                recurrenceInterval: isRecurring ? recurrenceInterval : nil,
                sendReminder: sendReminder,
                reminderType: sendReminder ? reminderType : nil
            )

            print("DEBUG: Sending request to create task...")
            let response: CreateTaskResponse = try await APIClient.shared.request(.createTask, body: body)
            print("DEBUG: Task created successfully with id: \(response.task.id)")
            clearForm()
            isLoading = false
            return true
        } catch let error as APIError {
            print("DEBUG: APIError creating task: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("DEBUG: Error creating task: \(error)")
            errorMessage = "Failed to create task: \(error.localizedDescription)"
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
        hasDueDate = false
        hasDueTime = false
        category = "personal_growth"
        goalType = "one_time"
        habitFrequency = ""
        milestoneTarget = ""
        milestoneUnit = ""
        checkInFrequency = ""
        rewardsEnabled = false
        rewardType = ""
        rewardCustom = ""
        isKidGoal = false
        visibleToKids = true
        kidsCanUpdate = false
        assignmentType = "individual"
        selectedMembers = []
        // Task fields
        taskCategory = "home_chores"
        taskGoalId = nil
        countTowardGoal = true
        taskAssignees = []
        isRecurring = false
        recurrenceFrequency = "daily"
        recurrenceInterval = 1
        sendReminder = false
        reminderType = "at_time"
    }

    func clearError() { errorMessage = nil }
}
