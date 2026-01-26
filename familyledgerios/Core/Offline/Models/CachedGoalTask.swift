import SwiftData
import Foundation

@Model
final class CachedGoalTask {
    // Identifiers
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Task data
    var title: String
    var taskDescription: String?
    var dueDate: Date?
    var dueTime: String?
    var priority: String?
    var status: String?
    var isRecurring: Bool
    var recurrencePattern: String?
    var assignedTo: String?
    var listName: String?
    var countTowardGoal: Bool

    // Parent reference
    var goalServerId: Int?

    // Sync metadata
    var syncStatus: String  // SyncStatus raw value
    var version: Int
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Relationship
    var goal: CachedGoal?

    init(
        serverId: Int? = nil,
        title: String,
        taskDescription: String? = nil,
        dueDate: Date? = nil,
        status: String? = "open",
        priority: String? = "medium",
        goalServerId: Int? = nil
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.title = title
        self.taskDescription = taskDescription
        self.dueDate = dueDate
        self.status = status
        self.priority = priority
        self.goalServerId = goalServerId
        self.isRecurring = false
        self.countTowardGoal = true
        self.syncStatus = serverId != nil ? SyncStatus.synced.rawValue : SyncStatus.pendingCreate.rawValue
        self.version = 1
        self.localUpdatedAt = Date()
    }

    // MARK: - Computed Properties

    var currentSyncStatus: SyncStatus {
        SyncStatus(rawValue: syncStatus) ?? .synced
    }

    var isPendingSync: Bool {
        currentSyncStatus != .synced
    }

    var isCompleted: Bool {
        status == "completed"
    }

    var isOpen: Bool {
        status == "open" || status == "in_progress"
    }

    var priorityLevel: Int {
        switch priority?.lowercased() {
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 2
        }
    }

    // Alias for goalServerId (for ViewModel compatibility)
    var goalId: Int? {
        get { goalServerId }
        set { goalServerId = newValue }
    }

    // MARK: - Convert from API Model

    static func from(_ apiModel: GoalTask, goalServerId: Int?) -> CachedGoalTask {
        let cached = CachedGoalTask(
            serverId: apiModel.id,
            title: apiModel.title,
            taskDescription: apiModel.description,
            status: apiModel.status,
            priority: apiModel.priority,
            goalServerId: goalServerId ?? apiModel.goalId
        )

        cached.dueTime = apiModel.dueTime
        cached.isRecurring = apiModel.isRecurring ?? false
        cached.recurrencePattern = apiModel.recurrencePattern
        cached.assignedTo = apiModel.assignedTo
        cached.listName = apiModel.listName
        cached.countTowardGoal = apiModel.countTowardGoal ?? true
        cached.syncStatus = SyncStatus.synced.rawValue
        cached.lastSyncedAt = Date()

        // Parse due date
        if let dateStr = apiModel.dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            cached.dueDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            cached.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }

        return cached
    }

    // MARK: - Convert to API Request

    func toCreateRequest() -> [String: Any] {
        var request: [String: Any] = [
            "title": title
        ]

        if let desc = taskDescription { request["description"] = desc }
        if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            request["due_date"] = formatter.string(from: dueDate)
        }
        if let dueTime = dueTime { request["due_time"] = dueTime }
        if let status = status { request["status"] = status }
        if let priority = priority { request["priority"] = priority }
        if let assignedTo = assignedTo { request["assigned_to"] = assignedTo }
        if let recurrencePattern = recurrencePattern { request["recurrence_pattern"] = recurrencePattern }
        if let goalServerId = goalServerId { request["goal_id"] = goalServerId }

        request["is_recurring"] = isRecurring
        request["count_toward_goal"] = countTowardGoal

        return request
    }

    func toUpdateRequest() -> [String: Any] {
        var request = toCreateRequest()
        request["version"] = version
        return request
    }

    // MARK: - Update from Server

    func updateFromServer(_ apiModel: GoalTask) {
        self.title = apiModel.title
        self.taskDescription = apiModel.description
        self.dueTime = apiModel.dueTime
        self.priority = apiModel.priority
        self.status = apiModel.status
        self.isRecurring = apiModel.isRecurring ?? false
        self.recurrencePattern = apiModel.recurrencePattern
        self.assignedTo = apiModel.assignedTo
        self.listName = apiModel.listName
        self.countTowardGoal = apiModel.countTowardGoal ?? true
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let dateStr = apiModel.dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.dueDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }
    }

    // MARK: - Toggle Completion

    func toggle() {
        if isCompleted {
            self.status = "open"
        } else {
            self.status = "completed"
        }
        self.syncStatus = SyncStatus.pendingUpdate.rawValue
        self.localUpdatedAt = Date()
    }

    // MARK: - Mark for Sync

    func markAsUpdated() {
        self.syncStatus = SyncStatus.pendingUpdate.rawValue
        self.localUpdatedAt = Date()
    }

    func markAsDeleted() {
        self.syncStatus = SyncStatus.pendingDelete.rawValue
        self.localUpdatedAt = Date()
    }

    func markAsSynced(serverId: Int, version: Int) {
        self.serverId = serverId
        self.version = version
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()
    }

    // MARK: - Convenience Initializer from API Model

    convenience init(from apiModel: GoalTask) {
        self.init(
            serverId: apiModel.id,
            title: apiModel.title,
            taskDescription: apiModel.description,
            status: apiModel.status,
            priority: apiModel.priority,
            goalServerId: apiModel.goalId
        )

        self.dueTime = apiModel.dueTime
        self.isRecurring = apiModel.isRecurring ?? false
        self.recurrencePattern = apiModel.recurrencePattern
        self.assignedTo = apiModel.assignedTo
        self.listName = apiModel.listName
        self.countTowardGoal = apiModel.countTowardGoal ?? true
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let dateStr = apiModel.dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.dueDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }
    }

    // MARK: - Convert to API Model

    func toGoalTask() -> GoalTask {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dueDateStr = dueDate.map { formatter.string(from: $0) }

        return GoalTask(
            id: serverId ?? 0,
            title: title,
            description: taskDescription,
            dueDate: dueDateStr,
            dueTime: dueTime,
            priority: priority,
            status: status,
            isRecurring: isRecurring,
            recurrencePattern: recurrencePattern,
            assignedTo: assignedTo,
            goalId: goalServerId,
            listName: listName,
            countTowardGoal: countTowardGoal,
            createdAt: nil,
            updatedAt: serverUpdatedAt.map { ISO8601DateFormatter().string(from: $0) }
        )
    }

    // MARK: - Update from API Model (alias for updateFromServer)

    func update(from apiModel: GoalTask) {
        updateFromServer(apiModel)
    }
}
