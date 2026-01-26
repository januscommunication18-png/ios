import Foundation
import SwiftData
import Combine

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

    // Offline mode support
    var isOffline: Bool { !NetworkMonitor.shared.isConnected }
    private var modelContext: ModelContext?
    private var networkCancellable: AnyCancellable?

    init() {
        modelContext = OfflineDataContainer.shared.mainContext

        // Listen for network changes to sync when back online
        networkCancellable = NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] notification in
                if let isConnected = notification.userInfo?["isConnected"] as? Bool, isConnected {
                    Task { @MainActor in
                        await self?.syncPendingOperations()
                    }
                }
            }
    }

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

        // Load from cache first for instant display
        loadGoalsFromCache()

        // If offline, don't try server
        guard !isOffline else {
            isLoading = false
            return
        }

        do {
            let response: GoalsResponse = try await APIClient.shared.request(.goals)
            goals = response.goals ?? []
            tasks = response.tasks ?? []
            // Cache to local storage
            cacheGoalsToLocal(goals: goals, tasks: tasks)
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

        // If offline, just load from cache
        guard !isOffline else {
            loadGoalsFromCache()
            isRefreshing = false
            return
        }

        do {
            let response: GoalsResponse = try await APIClient.shared.request(.goals)
            goals = response.goals ?? []
            tasks = response.tasks ?? []
            cacheGoalsToLocal(goals: goals, tasks: tasks)
        } catch { }
        isRefreshing = false
    }

    @MainActor
    func loadGoal(id: Int) async {
        print("🎯 Loading goal with id: \(id)")
        isLoading = true
        errorMessage = nil

        // Load from cache first
        loadGoalFromCache(id: id)

        // If offline, don't try server
        guard !isOffline else {
            isLoading = false
            return
        }

        do {
            let response: GoalDetailResponse = try await APIClient.shared.request(.goal(id: id))
            selectedGoal = response.goal
            selectedGoalTasks = response.tasks
            print("🎯 Successfully loaded goal: \(response.goal.title) with \(response.tasks.count) tasks")
            // Cache to local storage
            cacheGoalDetailToLocal(goal: response.goal, tasks: response.tasks)
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

        // If offline, create locally and queue for sync
        if isOffline {
            let success = createGoalOffline()
            clearForm()
            isLoading = false
            return success
        }

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
            // On error, create offline
            let success = createGoalOffline()
            if success {
                clearForm()
                isLoading = false
                return true
            }
            errorMessage = error.localizedDescription
        } catch {
            print("DEBUG: Error creating goal: \(error)")
            // On error, create offline
            let success = createGoalOffline()
            if success {
                clearForm()
                isLoading = false
                return true
            }
            errorMessage = "Failed to create goal: \(error.localizedDescription)"
        }
        isLoading = false
        return false
    }

    @MainActor
    func deleteGoal(id: Int) async -> Bool {
        isLoading = true

        // If offline, queue and update cache
        if isOffline {
            queueDeleteGoal(id: id)
            deleteGoalFromCache(id: id)
            goals.removeAll { $0.id == id }
            isLoading = false
            return true
        }

        do {
            try await APIClient.shared.requestEmpty(.deleteGoal(id: id))
            goals.removeAll { $0.id == id }
            deleteGoalFromCache(id: id)
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
        // If offline, queue and update cache
        if isOffline {
            queueCompleteGoal(id: id)
            completeGoalInCache(id: id)
            // Update in-memory
            if let index = goals.firstIndex(where: { $0.id == id }) {
                var updatedGoal = goals[index]
                // Note: Goal struct would need to be updated for this to work
                // For now, just reload from cache
            }
            if selectedGoal?.id == id {
                loadGoalFromCache(id: id)
            }
            return
        }

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

        // If offline, create locally and queue for sync
        if isOffline {
            let success = createTaskOffline()
            clearForm()
            isLoading = false
            return success
        }

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
            // On error, create offline
            let success = createTaskOffline()
            if success {
                clearForm()
                isLoading = false
                return true
            }
            errorMessage = error.localizedDescription
        } catch {
            print("DEBUG: Error creating task: \(error)")
            // On error, create offline
            let success = createTaskOffline()
            if success {
                clearForm()
                isLoading = false
                return true
            }
            errorMessage = "Failed to create task: \(error.localizedDescription)"
        }
        isLoading = false
        return false
    }

    @MainActor
    func toggleTask(id: Int) async {
        // If offline, queue and update cache
        if isOffline {
            queueToggleTask(id: id)
            toggleTaskInCache(id: id)
            // Update in-memory
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                var updatedTask = tasks[index]
                let newStatus = updatedTask.status == "completed" ? "open" : "completed"
                // Note: GoalTask struct would need mutation support
            }
            if let index = selectedGoalTasks.firstIndex(where: { $0.id == id }) {
                // Update selected goal tasks from cache
                loadGoalFromCache(id: selectedGoal?.id ?? 0)
            }
            if selectedTask?.id == id {
                loadTaskFromCache(id: id)
            }
            return
        }

        do {
            let _: GoalTask = try await APIClient.shared.request(.toggleTask(id: id))
            await loadTask(id: id)
        } catch { }
    }

    @MainActor
    func deleteTask(id: Int) async -> Bool {
        // If offline, queue and update cache
        if isOffline {
            queueDeleteTask(id: id)
            deleteTaskFromCache(id: id)
            tasks.removeAll { $0.id == id }
            selectedGoalTasks.removeAll { $0.id == id }
            return true
        }

        do {
            try await APIClient.shared.requestEmpty(.deleteTask(id: id))
            tasks.removeAll { $0.id == id }
            selectedGoalTasks.removeAll { $0.id == id }
            deleteTaskFromCache(id: id)
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

    // MARK: - Cache Methods

    private func loadGoalsFromCache() {
        guard let context = modelContext else { return }

        do {
            let deletedStatus = SyncStatus.pendingDelete.rawValue
            let goalsDescriptor = FetchDescriptor<CachedGoal>(
                predicate: #Predicate<CachedGoal> { goal in
                    goal.syncStatus != deletedStatus
                },
                sortBy: [SortDescriptor(\CachedGoal.localUpdatedAt, order: .reverse)]
            )
            let cachedGoals = try context.fetch(goalsDescriptor)

            let tasksDescriptor = FetchDescriptor<CachedGoalTask>(
                predicate: #Predicate<CachedGoalTask> { task in
                    task.syncStatus != deletedStatus
                },
                sortBy: [SortDescriptor(\CachedGoalTask.localUpdatedAt, order: .reverse)]
            )
            let cachedTasks = try context.fetch(tasksDescriptor)

            if goals.isEmpty {
                goals = cachedGoals.map { $0.toGoal() }
            }
            if tasks.isEmpty {
                tasks = cachedTasks.map { $0.toGoalTask() }
            }
        } catch {
            print("Failed to load goals from cache: \(error)")
        }
    }

    private func cacheGoalsToLocal(goals: [Goal], tasks: [GoalTask]) {
        guard let context = modelContext else { return }

        do {
            // Cache goals
            for goal in goals {
                let goalId = goal.id
                let descriptor = FetchDescriptor<CachedGoal>(
                    predicate: #Predicate<CachedGoal> { cached in
                        cached.serverId == goalId
                    }
                )
                if let existingGoal = try context.fetch(descriptor).first {
                    existingGoal.update(from: goal)
                } else {
                    let cachedGoal = CachedGoal(from: goal)
                    context.insert(cachedGoal)
                }
            }

            // Cache tasks
            for task in tasks {
                let taskId = task.id
                let descriptor = FetchDescriptor<CachedGoalTask>(
                    predicate: #Predicate<CachedGoalTask> { cached in
                        cached.serverId == taskId
                    }
                )
                if let existingTask = try context.fetch(descriptor).first {
                    existingTask.update(from: task)
                } else {
                    let cachedTask = CachedGoalTask(from: task)
                    context.insert(cachedTask)
                }
            }

            try context.save()
        } catch {
            print("Failed to cache goals: \(error)")
        }
    }

    private func loadGoalFromCache(id: Int) {
        guard let context = modelContext else { return }

        do {
            let goalId = id
            let goalDescriptor = FetchDescriptor<CachedGoal>(
                predicate: #Predicate<CachedGoal> { cached in
                    cached.serverId == goalId
                }
            )
            if let cachedGoal = try context.fetch(goalDescriptor).first {
                selectedGoal = cachedGoal.toGoal()

                // Load associated tasks
                let deletedStatus = SyncStatus.pendingDelete.rawValue
                let tasksDescriptor = FetchDescriptor<CachedGoalTask>(
                    predicate: #Predicate<CachedGoalTask> { cachedTask in
                        cachedTask.goalServerId == goalId && cachedTask.syncStatus != deletedStatus
                    },
                    sortBy: [SortDescriptor(\CachedGoalTask.localUpdatedAt, order: .reverse)]
                )
                let cachedTasks = try context.fetch(tasksDescriptor)
                selectedGoalTasks = cachedTasks.map { $0.toGoalTask() }
            }
        } catch {
            print("Failed to load goal from cache: \(error)")
        }
    }

    private func cacheGoalDetailToLocal(goal: Goal, tasks: [GoalTask]) {
        guard let context = modelContext else { return }

        do {
            // Cache goal
            let goalId = goal.id
            let goalDescriptor = FetchDescriptor<CachedGoal>(
                predicate: #Predicate<CachedGoal> { cached in
                    cached.serverId == goalId
                }
            )
            if let existingGoal = try context.fetch(goalDescriptor).first {
                existingGoal.update(from: goal)
            } else {
                let cachedGoal = CachedGoal(from: goal)
                context.insert(cachedGoal)
            }

            // Cache tasks
            for task in tasks {
                let taskId = task.id
                let taskDescriptor = FetchDescriptor<CachedGoalTask>(
                    predicate: #Predicate<CachedGoalTask> { cached in
                        cached.serverId == taskId
                    }
                )
                if let existingTask = try context.fetch(taskDescriptor).first {
                    existingTask.update(from: task)
                } else {
                    let cachedTask = CachedGoalTask(from: task)
                    context.insert(cachedTask)
                }
            }

            try context.save()
        } catch {
            print("Failed to cache goal detail: \(error)")
        }
    }

    private func loadTaskFromCache(id: Int) {
        guard let context = modelContext else { return }

        do {
            let taskId = id
            let descriptor = FetchDescriptor<CachedGoalTask>(
                predicate: #Predicate<CachedGoalTask> { cached in
                    cached.serverId == taskId
                }
            )
            if let cachedTask = try context.fetch(descriptor).first {
                selectedTask = cachedTask.toGoalTask()
            }
        } catch {
            print("Failed to load task from cache: \(error)")
        }
    }

    private func deleteGoalFromCache(id: Int) {
        guard let context = modelContext else { return }

        do {
            let goalId = id
            let descriptor = FetchDescriptor<CachedGoal>(
                predicate: #Predicate<CachedGoal> { cached in
                    cached.serverId == goalId
                }
            )
            if let cachedGoal = try context.fetch(descriptor).first {
                cachedGoal.syncStatus = SyncStatus.pendingDelete.rawValue
                cachedGoal.localUpdatedAt = Date()
                try context.save()
            }
        } catch {
            print("Failed to delete goal from cache: \(error)")
        }
    }

    private func completeGoalInCache(id: Int) {
        guard let context = modelContext else { return }

        do {
            let goalId = id
            let descriptor = FetchDescriptor<CachedGoal>(
                predicate: #Predicate<CachedGoal> { cached in
                    cached.serverId == goalId
                }
            )
            if let cachedGoal = try context.fetch(descriptor).first {
                cachedGoal.status = "completed"
                cachedGoal.syncStatus = SyncStatus.pendingUpdate.rawValue
                cachedGoal.localUpdatedAt = Date()
                try context.save()
            }
        } catch {
            print("Failed to complete goal in cache: \(error)")
        }
    }

    private func toggleTaskInCache(id: Int) {
        guard let context = modelContext else { return }

        do {
            let taskId = id
            let descriptor = FetchDescriptor<CachedGoalTask>(
                predicate: #Predicate<CachedGoalTask> { cached in
                    cached.serverId == taskId
                }
            )
            if let cachedTask = try context.fetch(descriptor).first {
                cachedTask.status = cachedTask.status == "completed" ? "open" : "completed"
                cachedTask.syncStatus = SyncStatus.pendingUpdate.rawValue
                cachedTask.localUpdatedAt = Date()
                try context.save()
            }
        } catch {
            print("Failed to toggle task in cache: \(error)")
        }
    }

    private func deleteTaskFromCache(id: Int) {
        guard let context = modelContext else { return }

        do {
            let taskId = id
            let descriptor = FetchDescriptor<CachedGoalTask>(
                predicate: #Predicate<CachedGoalTask> { cached in
                    cached.serverId == taskId
                }
            )
            if let cachedTask = try context.fetch(descriptor).first {
                cachedTask.syncStatus = SyncStatus.pendingDelete.rawValue
                cachedTask.localUpdatedAt = Date()
                try context.save()
            }
        } catch {
            print("Failed to delete task from cache: \(error)")
        }
    }

    // MARK: - Queue Methods

    private func queueDeleteGoal(id: Int) {
        guard let context = modelContext else { return }

        do {
            let goalId = id
            let descriptor = FetchDescriptor<CachedGoal>(
                predicate: #Predicate<CachedGoal> { cached in
                    cached.serverId == goalId
                }
            )
            if let cachedGoal = try context.fetch(descriptor).first {
                try OutboxManager.shared.queueDelete(
                    entityType: .goal,
                    localEntityId: cachedGoal.localId,
                    serverId: id,
                    endpoint: "/api/v1/goals/\(id)"
                )
            }
        } catch {
            print("Failed to queue delete goal: \(error)")
        }
    }

    private func queueCompleteGoal(id: Int) {
        guard let context = modelContext else { return }

        do {
            let goalId = id
            let descriptor = FetchDescriptor<CachedGoal>(
                predicate: #Predicate<CachedGoal> { cached in
                    cached.serverId == goalId
                }
            )
            if let cachedGoal = try context.fetch(descriptor).first {
                try OutboxManager.shared.queueUpdate(
                    entityType: .goal,
                    localEntityId: cachedGoal.localId,
                    serverId: id,
                    endpoint: "/api/v1/goals/\(id)/complete",
                    payload: ["status": "completed"]
                )
            }
        } catch {
            print("Failed to queue complete goal: \(error)")
        }
    }

    private func queueToggleTask(id: Int) {
        guard let context = modelContext else { return }

        do {
            let taskId = id
            let descriptor = FetchDescriptor<CachedGoalTask>(
                predicate: #Predicate<CachedGoalTask> { cached in
                    cached.serverId == taskId
                }
            )
            if let cachedTask = try context.fetch(descriptor).first {
                try OutboxManager.shared.queueToggle(
                    entityType: .goalTask,
                    localEntityId: cachedTask.localId,
                    serverId: id,
                    endpoint: "/api/v1/tasks/\(id)/toggle"
                )
            }
        } catch {
            print("Failed to queue toggle task: \(error)")
        }
    }

    private func queueDeleteTask(id: Int) {
        guard let context = modelContext else { return }

        do {
            let taskId = id
            let descriptor = FetchDescriptor<CachedGoalTask>(
                predicate: #Predicate<CachedGoalTask> { cached in
                    cached.serverId == taskId
                }
            )
            if let cachedTask = try context.fetch(descriptor).first {
                try OutboxManager.shared.queueDelete(
                    entityType: .goalTask,
                    localEntityId: cachedTask.localId,
                    serverId: id,
                    endpoint: "/api/v1/tasks/\(id)"
                )
            }
        } catch {
            print("Failed to queue delete task: \(error)")
        }
    }

    // MARK: - Offline Creation Methods

    private func createGoalOffline() -> Bool {
        guard let context = modelContext else { return false }

        let newGoal = CachedGoal(
            title: title,
            goalDescription: description.isEmpty ? nil : description,
            status: "active",
            priority: "medium"
        )

        newGoal.category = category
        newGoal.goalType = goalType
        newGoal.habitFrequency = goalType == "habit" && !habitFrequency.isEmpty ? habitFrequency : nil
        newGoal.milestoneTarget = goalType == "milestone" && !milestoneTarget.isEmpty ? Int(milestoneTarget) : nil
        newGoal.milestoneUnit = goalType == "milestone" && !milestoneUnit.isEmpty ? milestoneUnit : nil
        newGoal.assignmentType = assignmentType
        newGoal.isKidGoal = isKidGoal
        newGoal.rewardsEnabled = rewardsEnabled
        newGoal.rewardType = rewardsEnabled && !rewardType.isEmpty ? rewardType : nil
        newGoal.rewardCustom = rewardsEnabled && rewardType == "custom" && !rewardCustom.isEmpty ? rewardCustom : nil

        context.insert(newGoal)

        // Queue for sync
        do {
            try OutboxManager.shared.queueCreate(
                entityType: .goal,
                localEntityId: newGoal.localId,
                endpoint: "/api/v1/goals",
                payload: newGoal.toCreateRequest()
            )
            try context.save()

            // Add to in-memory list
            goals.append(newGoal.toGoal())
            return true
        } catch {
            print("Failed to create goal offline: \(error)")
            return false
        }
    }

    private func createTaskOffline() -> Bool {
        guard let context = modelContext else { return false }

        let newTask = CachedGoalTask(
            title: title,
            taskDescription: description.isEmpty ? nil : description,
            dueDate: hasDueDate ? dueDate : nil,
            status: "open",
            priority: priority,
            goalServerId: taskGoalId
        )

        newTask.isRecurring = isRecurring
        newTask.recurrencePattern = isRecurring ? recurrenceFrequency : nil
        newTask.countTowardGoal = taskGoalId != nil && countTowardGoal

        context.insert(newTask)

        // Queue for sync
        do {
            try OutboxManager.shared.queueCreate(
                entityType: .goalTask,
                localEntityId: newTask.localId,
                endpoint: "/api/v1/tasks",
                payload: newTask.toCreateRequest()
            )
            try context.save()

            // Add to in-memory list
            tasks.append(newTask.toGoalTask())
            return true
        } catch {
            print("Failed to create task offline: \(error)")
            return false
        }
    }

    // MARK: - Sync Methods

    @MainActor
    private func syncPendingOperations() async {
        // Trigger sync manager to process pending operations
        await SyncManager.shared.syncNow()
        // Refresh data after sync
        await refreshGoals()
    }
}
