import SwiftData
import Foundation

@Model
final class CachedGoal {
    // Identifiers
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Goal data
    var title: String
    var goalDescription: String?
    var targetDate: Date?
    var progress: Int
    var status: String?
    var priority: String?
    var category: String?
    var categoryEmoji: String?
    var categoryColor: String?

    // Goal type
    var goalType: String?
    var habitFrequency: String?
    var milestoneTarget: Int?
    var milestoneCurrent: Int?
    var milestoneUnit: String?

    // Assignment
    var assignmentType: String?
    var isKidGoal: Bool

    // Rewards
    var rewardsEnabled: Bool
    var rewardType: String?
    var rewardCustom: String?
    var rewardClaimed: Bool

    // Sync metadata
    var syncStatus: String  // SyncStatus raw value
    var version: Int
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Tasks relationship
    @Relationship(deleteRule: .cascade, inverse: \CachedGoalTask.goal)
    var tasks: [CachedGoalTask]?

    init(
        serverId: Int? = nil,
        title: String,
        goalDescription: String? = nil,
        targetDate: Date? = nil,
        status: String? = "active",
        priority: String? = "medium"
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.title = title
        self.goalDescription = goalDescription
        self.targetDate = targetDate
        self.progress = 0
        self.status = status
        self.priority = priority
        self.isKidGoal = false
        self.rewardsEnabled = false
        self.rewardClaimed = false
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

    var activeTasksCount: Int {
        tasks?.filter { $0.status != "completed" }.count ?? 0
    }

    var completedTasksCount: Int {
        tasks?.filter { $0.status == "completed" }.count ?? 0
    }

    var totalTasksCount: Int {
        tasks?.count ?? 0
    }

    var isCompleted: Bool {
        status == "done" || status == "completed"
    }

    var statusEmoji: String {
        switch status {
        case "done", "completed": return "done"
        case "archived", "paused": return "paused"
        case "in_progress": return "in_progress"
        default: return "active"
        }
    }

    // MARK: - Convert from API Model

    static func from(_ apiModel: Goal) -> CachedGoal {
        let cached = CachedGoal(
            serverId: apiModel.id,
            title: apiModel.title,
            goalDescription: apiModel.description,
            status: apiModel.status,
            priority: apiModel.priority
        )

        cached.progress = apiModel.progress ?? 0
        cached.category = apiModel.category
        cached.categoryEmoji = apiModel.categoryEmoji
        cached.categoryColor = apiModel.categoryColor
        cached.goalType = apiModel.goalType
        cached.habitFrequency = apiModel.habitFrequency
        cached.milestoneTarget = apiModel.milestoneTarget
        cached.milestoneCurrent = apiModel.milestoneCurrent
        cached.milestoneUnit = apiModel.milestoneUnit
        cached.assignmentType = apiModel.assignmentType
        cached.isKidGoal = apiModel.isKidGoal ?? false
        cached.rewardsEnabled = apiModel.rewardsEnabled ?? false
        cached.rewardType = apiModel.rewardType
        cached.rewardCustom = apiModel.rewardCustom
        cached.rewardClaimed = apiModel.rewardClaimed ?? false
        cached.syncStatus = SyncStatus.synced.rawValue
        cached.lastSyncedAt = Date()

        // Parse target date
        if let dateStr = apiModel.targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            cached.targetDate = formatter.date(from: dateStr)
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

        if let desc = goalDescription { request["description"] = desc }
        if let targetDate = targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            request["target_date"] = formatter.string(from: targetDate)
        }
        if let status = status { request["status"] = status }
        if let priority = priority { request["priority"] = priority }
        if let category = category { request["category"] = category }
        if let goalType = goalType { request["goal_type"] = goalType }
        if let habitFrequency = habitFrequency { request["habit_frequency"] = habitFrequency }
        if let milestoneTarget = milestoneTarget { request["milestone_target"] = milestoneTarget }
        if let milestoneUnit = milestoneUnit { request["milestone_unit"] = milestoneUnit }
        if let assignmentType = assignmentType { request["assignment_type"] = assignmentType }

        request["is_kid_goal"] = isKidGoal
        request["rewards_enabled"] = rewardsEnabled

        if let rewardType = rewardType { request["reward_type"] = rewardType }
        if let rewardCustom = rewardCustom { request["reward_custom"] = rewardCustom }

        return request
    }

    func toUpdateRequest() -> [String: Any] {
        var request = toCreateRequest()
        request["progress"] = progress
        request["milestone_current"] = milestoneCurrent
        request["reward_claimed"] = rewardClaimed
        request["version"] = version
        return request
    }

    // MARK: - Update from Server

    func updateFromServer(_ apiModel: Goal) {
        self.title = apiModel.title
        self.goalDescription = apiModel.description
        self.progress = apiModel.progress ?? 0
        self.status = apiModel.status
        self.priority = apiModel.priority
        self.category = apiModel.category
        self.categoryEmoji = apiModel.categoryEmoji
        self.categoryColor = apiModel.categoryColor
        self.goalType = apiModel.goalType
        self.habitFrequency = apiModel.habitFrequency
        self.milestoneTarget = apiModel.milestoneTarget
        self.milestoneCurrent = apiModel.milestoneCurrent
        self.milestoneUnit = apiModel.milestoneUnit
        self.assignmentType = apiModel.assignmentType
        self.isKidGoal = apiModel.isKidGoal ?? false
        self.rewardsEnabled = apiModel.rewardsEnabled ?? false
        self.rewardType = apiModel.rewardType
        self.rewardCustom = apiModel.rewardCustom
        self.rewardClaimed = apiModel.rewardClaimed ?? false
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let dateStr = apiModel.targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.targetDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }
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

    // MARK: - Progress Update

    func updateProgress(_ newProgress: Int) {
        self.progress = min(100, max(0, newProgress))
        markAsUpdated()
    }

    // MARK: - Convenience Initializer from API Model

    convenience init(from apiModel: Goal) {
        self.init(
            serverId: apiModel.id,
            title: apiModel.title,
            goalDescription: apiModel.description,
            status: apiModel.status,
            priority: apiModel.priority
        )

        self.progress = apiModel.progress ?? 0
        self.category = apiModel.category
        self.categoryEmoji = apiModel.categoryEmoji
        self.categoryColor = apiModel.categoryColor
        self.goalType = apiModel.goalType
        self.habitFrequency = apiModel.habitFrequency
        self.milestoneTarget = apiModel.milestoneTarget
        self.milestoneCurrent = apiModel.milestoneCurrent
        self.milestoneUnit = apiModel.milestoneUnit
        self.assignmentType = apiModel.assignmentType
        self.isKidGoal = apiModel.isKidGoal ?? false
        self.rewardsEnabled = apiModel.rewardsEnabled ?? false
        self.rewardType = apiModel.rewardType
        self.rewardCustom = apiModel.rewardCustom
        self.rewardClaimed = apiModel.rewardClaimed ?? false
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let dateStr = apiModel.targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.targetDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }
    }

    // MARK: - Convert to API Model

    func toGoal() -> Goal {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let targetDateStr = targetDate.map { formatter.string(from: $0) }

        return Goal(
            id: serverId ?? 0,
            title: title,
            description: goalDescription,
            targetDate: targetDateStr,
            progress: progress,
            status: status,
            priority: priority,
            category: category,
            categoryEmoji: categoryEmoji,
            categoryColor: categoryColor,
            goalType: goalType,
            habitFrequency: habitFrequency,
            milestoneTarget: milestoneTarget,
            milestoneCurrent: milestoneCurrent,
            milestoneUnit: milestoneUnit,
            milestoneProgress: milestoneTarget != nil && milestoneTarget! > 0 ? Double(milestoneCurrent ?? 0) / Double(milestoneTarget!) * 100 : nil,
            assignmentType: assignmentType,
            isKidGoal: isKidGoal,
            checkInFrequency: nil,
            rewardsEnabled: rewardsEnabled,
            rewardType: rewardType,
            rewardCustom: rewardCustom,
            rewardClaimed: rewardClaimed,
            activeTasksCount: activeTasksCount,
            completedTasksCount: completedTasksCount,
            totalTasksCount: totalTasksCount,
            createdAt: nil,
            updatedAt: serverUpdatedAt.map { ISO8601DateFormatter().string(from: $0) }
        )
    }

    // MARK: - Update from API Model (alias for updateFromServer)

    func update(from apiModel: Goal) {
        updateFromServer(apiModel)
    }
}
