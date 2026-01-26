import Foundation
import SwiftUI

struct Goal: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String?
    let targetDate: String?
    let progress: Int?
    let status: String?
    let priority: String?
    let category: String?
    let categoryEmoji: String?
    let categoryColor: String?
    // Goal type info
    let goalType: String?
    let habitFrequency: String?
    let milestoneTarget: Int?
    let milestoneCurrent: Int?
    let milestoneUnit: String?
    let milestoneProgress: Double?
    // Assignment
    let assignmentType: String?
    let isKidGoal: Bool?
    // Check-in & Rewards
    let checkInFrequency: String?
    let rewardsEnabled: Bool?
    let rewardType: String?
    let rewardCustom: String?
    let rewardClaimed: Bool?
    // Stats
    let activeTasksCount: Int?
    let completedTasksCount: Int?
    let totalTasksCount: Int?
    // Dates
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, progress, status, priority, category
        case targetDate = "target_date"
        case categoryEmoji = "category_emoji"
        case categoryColor = "category_color"
        case goalType = "goal_type"
        case habitFrequency = "habit_frequency"
        case milestoneTarget = "milestone_target"
        case milestoneCurrent = "milestone_current"
        case milestoneUnit = "milestone_unit"
        case milestoneProgress = "milestone_progress"
        case assignmentType = "assignment_type"
        case isKidGoal = "is_kid_goal"
        case checkInFrequency = "check_in_frequency"
        case rewardsEnabled = "rewards_enabled"
        case rewardType = "reward_type"
        case rewardCustom = "reward_custom"
        case rewardClaimed = "reward_claimed"
        case activeTasksCount = "active_tasks_count"
        case completedTasksCount = "completed_tasks_count"
        case totalTasksCount = "total_tasks_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        targetDate = try container.decodeIfPresent(String.self, forKey: .targetDate)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        categoryEmoji = try container.decodeIfPresent(String.self, forKey: .categoryEmoji)
        categoryColor = try container.decodeIfPresent(String.self, forKey: .categoryColor)
        goalType = try container.decodeIfPresent(String.self, forKey: .goalType)
        habitFrequency = try container.decodeIfPresent(String.self, forKey: .habitFrequency)
        milestoneTarget = try container.decodeIfPresent(Int.self, forKey: .milestoneTarget)
        milestoneCurrent = try container.decodeIfPresent(Int.self, forKey: .milestoneCurrent)
        milestoneUnit = try container.decodeIfPresent(String.self, forKey: .milestoneUnit)
        milestoneProgress = try container.decodeIfPresent(Double.self, forKey: .milestoneProgress)
        assignmentType = try container.decodeIfPresent(String.self, forKey: .assignmentType)
        isKidGoal = try container.decodeIfPresent(Bool.self, forKey: .isKidGoal)
        checkInFrequency = try container.decodeIfPresent(String.self, forKey: .checkInFrequency)
        rewardsEnabled = try container.decodeIfPresent(Bool.self, forKey: .rewardsEnabled)
        rewardType = try container.decodeIfPresent(String.self, forKey: .rewardType)
        rewardCustom = try container.decodeIfPresent(String.self, forKey: .rewardCustom)
        rewardClaimed = try container.decodeIfPresent(Bool.self, forKey: .rewardClaimed)
        activeTasksCount = try container.decodeIfPresent(Int.self, forKey: .activeTasksCount)
        completedTasksCount = try container.decodeIfPresent(Int.self, forKey: .completedTasksCount)
        totalTasksCount = try container.decodeIfPresent(Int.self, forKey: .totalTasksCount)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        // Handle progress as either Int or Double from API
        if let progressDouble = try? container.decodeIfPresent(Double.self, forKey: .progress) {
            progress = Int(progressDouble)
        } else {
            progress = try container.decodeIfPresent(Int.self, forKey: .progress)
        }
    }

    // Memberwise initializer for creating from cache
    init(
        id: Int,
        title: String,
        description: String? = nil,
        targetDate: String? = nil,
        progress: Int? = nil,
        status: String? = nil,
        priority: String? = nil,
        category: String? = nil,
        categoryEmoji: String? = nil,
        categoryColor: String? = nil,
        goalType: String? = nil,
        habitFrequency: String? = nil,
        milestoneTarget: Int? = nil,
        milestoneCurrent: Int? = nil,
        milestoneUnit: String? = nil,
        milestoneProgress: Double? = nil,
        assignmentType: String? = nil,
        isKidGoal: Bool? = nil,
        checkInFrequency: String? = nil,
        rewardsEnabled: Bool? = nil,
        rewardType: String? = nil,
        rewardCustom: String? = nil,
        rewardClaimed: Bool? = nil,
        activeTasksCount: Int? = nil,
        completedTasksCount: Int? = nil,
        totalTasksCount: Int? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.progress = progress
        self.status = status
        self.priority = priority
        self.category = category
        self.categoryEmoji = categoryEmoji
        self.categoryColor = categoryColor
        self.goalType = goalType
        self.habitFrequency = habitFrequency
        self.milestoneTarget = milestoneTarget
        self.milestoneCurrent = milestoneCurrent
        self.milestoneUnit = milestoneUnit
        self.milestoneProgress = milestoneProgress
        self.assignmentType = assignmentType
        self.isKidGoal = isKidGoal
        self.checkInFrequency = checkInFrequency
        self.rewardsEnabled = rewardsEnabled
        self.rewardType = rewardType
        self.rewardCustom = rewardCustom
        self.rewardClaimed = rewardClaimed
        self.activeTasksCount = activeTasksCount
        self.completedTasksCount = completedTasksCount
        self.totalTasksCount = totalTasksCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    var statusEmoji: String {
        switch status {
        case "done", "completed": return "✅"
        case "archived", "paused": return "📦"
        case "in_progress": return "🔄"
        default: return "🎯"
        }
    }

    var goalTypeEmoji: String {
        switch goalType {
        case "habit": return "🔁"
        case "milestone": return "📊"
        default: return "🎯"
        }
    }

    var goalTypeLabel: String {
        switch goalType {
        case "habit": return "Habit"
        case "milestone": return "Milestone"
        default: return "One-time"
        }
    }

    var assignmentEmoji: String {
        switch assignmentType {
        case "family": return "👨‍👩‍👧‍👦"
        case "parents": return "👫"
        case "kids": return "👧"
        case "individual": return "👤"
        default: return "👨‍👩‍👧‍👦"
        }
    }

    var assignmentLabel: String {
        switch assignmentType {
        case "family": return "Entire Family"
        case "parents": return "Parents Only"
        case "kids": return "All Kids"
        case "individual": return "Individual"
        default: return "Entire Family"
        }
    }

    var rewardEmoji: String {
        switch rewardType {
        case "sticker": return "⭐"
        case "points": return "🏆"
        case "treat": return "🍪"
        case "outing": return "🎉"
        case "custom": return "🎁"
        default: return "🎁"
        }
    }

    var rewardLabel: String {
        switch rewardType {
        case "sticker": return "Sticker"
        case "points": return "Points"
        case "treat": return "Special Treat"
        case "outing": return "Fun Outing"
        case "custom": return rewardCustom ?? "Custom Reward"
        default: return "Reward"
        }
    }
}

struct GoalTask: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String?
    let dueDate: String?
    let dueTime: String?
    let priority: String?
    let status: String?
    let isRecurring: Bool?
    let recurrencePattern: String?
    let assignedTo: String?
    let goalId: Int?
    let listName: String?
    let countTowardGoal: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, priority, status
        case dueDate = "due_date"
        case dueTime = "due_time"
        case isRecurring = "is_recurring"
        case recurrencePattern = "recurrence_pattern"
        case assignedTo = "assigned_to"
        case goalId = "goal_id"
        case listName = "list_name"
        case countTowardGoal = "count_toward_goal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Memberwise initializer for creating from cache
    init(
        id: Int,
        title: String,
        description: String? = nil,
        dueDate: String? = nil,
        dueTime: String? = nil,
        priority: String? = nil,
        status: String? = nil,
        isRecurring: Bool? = nil,
        recurrencePattern: String? = nil,
        assignedTo: String? = nil,
        goalId: Int? = nil,
        listName: String? = nil,
        countTowardGoal: Bool? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.priority = priority
        self.status = status
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
        self.assignedTo = assignedTo
        self.goalId = goalId
        self.listName = listName
        self.countTowardGoal = countTowardGoal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: GoalTask, rhs: GoalTask) -> Bool {
        lhs.id == rhs.id
    }

    var isCompleted: Bool {
        status == "completed"
    }

    var isOpen: Bool {
        status == "open" || status == "in_progress"
    }
}

struct GoalsResponse: Codable {
    let goals: [Goal]?
    let tasks: [GoalTask]?
    let openTasksCount: Int?
    let activeGoalsCount: Int?

    enum CodingKeys: String, CodingKey {
        case goals, tasks
        case openTasksCount = "open_tasks_count"
        case activeGoalsCount = "active_goals_count"
    }
}

struct GoalDetailResponse: Codable {
    let goal: Goal
    let tasks: [GoalTask]
    let milestones: [Milestone]?
}

struct Milestone: Codable {
    let id: Int?
    let title: String?
    let completed: Bool?
}

struct TaskDetailResponse: Codable {
    let task: GoalTask
}

// MARK: - Goal Template

struct GoalTemplate: Identifiable {
    let id: Int
    let title: String
    let description: String?
    let emoji: String
    let category: String
    let goalType: String
    let habitFrequency: String?
    let milestoneTarget: Int?
    let milestoneUnit: String?
    let isKidGoal: Bool
    let suggestedReward: Bool
    let rewardType: String?

    init(
        id: Int,
        title: String,
        description: String? = nil,
        emoji: String,
        category: String,
        goalType: String,
        habitFrequency: String? = nil,
        milestoneTarget: Int? = nil,
        milestoneUnit: String? = nil,
        isKidGoal: Bool = false,
        suggestedReward: Bool = false,
        rewardType: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.emoji = emoji
        self.category = category
        self.goalType = goalType
        self.habitFrequency = habitFrequency
        self.milestoneTarget = milestoneTarget
        self.milestoneUnit = milestoneUnit
        self.isKidGoal = isKidGoal
        self.suggestedReward = suggestedReward
        self.rewardType = rewardType
    }
}
