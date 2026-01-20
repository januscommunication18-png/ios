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
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, progress, status, priority, category
        case targetDate = "target_date"
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
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        // Handle progress as either Int or Double from API
        if let progressDouble = try? container.decodeIfPresent(Double.self, forKey: .progress) {
            progress = Int(progressDouble)
        } else {
            progress = try container.decodeIfPresent(Int.self, forKey: .progress)
        }
    }

    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: GoalTask, rhs: GoalTask) -> Bool {
        lhs.id == rhs.id
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
    let tasks: [GoalTask]?
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
