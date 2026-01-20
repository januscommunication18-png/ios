import Foundation
import SwiftUI

struct Reminder: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String?
    let dueDate: String?
    let dueDateFormatted: String?
    let dueDateDay: String?
    let dueText: String?
    let dueTime: String?
    let dueTimeFormatted: String?
    let priority: String?
    let status: String?
    let isRecurring: Bool?
    let recurrencePattern: String?
    let category: String?
    let categoryIcon: String?
    let assignedTo: String?
    let completedAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, priority, status, category
        case dueDate = "due_date"
        case dueDateFormatted = "due_date_formatted"
        case dueDateDay = "due_date_day"
        case dueText = "due_text"
        case dueTime = "due_time"
        case dueTimeFormatted = "due_time_formatted"
        case isRecurring = "is_recurring"
        case recurrencePattern = "recurrence_pattern"
        case categoryIcon = "category_icon"
        case assignedTo = "assigned_to"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: Reminder, rhs: Reminder) -> Bool { lhs.id == rhs.id }
}

struct BirthdayReminder: Codable, Identifiable {
    let id: String
    let personId: Int
    let personName: String
    let personInitials: String?
    let personImageUrl: String?
    let relationship: String?
    let birthdayDate: String?
    let birthdayDateFull: String?
    let daysUntil: Int
    let daysUntilText: String?
    let turningAge: Int?

    enum CodingKeys: String, CodingKey {
        case id, relationship
        case personId = "person_id"
        case personName = "person_name"
        case personInitials = "person_initials"
        case personImageUrl = "person_image_url"
        case birthdayDate = "birthday_date"
        case birthdayDateFull = "birthday_date_full"
        case daysUntil = "days_until"
        case daysUntilText = "days_until_text"
        case turningAge = "turning_age"
    }
}

struct ImportantDateReminder: Codable, Identifiable {
    let id: String
    let label: String?
    let personId: Int
    let personName: String
    let personInitials: String?
    let personImageUrl: String?
    let nextDate: String?
    let daysUntil: Int
    let daysUntilText: String?
    let isRecurring: Bool?

    enum CodingKeys: String, CodingKey {
        case id, label
        case personId = "person_id"
        case personName = "person_name"
        case personInitials = "person_initials"
        case personImageUrl = "person_image_url"
        case nextDate = "next_date"
        case daysUntil = "days_until"
        case daysUntilText = "days_until_text"
        case isRecurring = "is_recurring"
    }
}

struct ReminderStats: Codable {
    let total: Int?
    let overdue: Int?
    let today: Int?
    let completed: Int?
    let highPriority: Int?

    enum CodingKeys: String, CodingKey {
        case total, overdue, today, completed
        case highPriority = "high_priority"
    }
}

struct RemindersResponse: Codable {
    let reminders: [Reminder]?
    let overdue: [Reminder]?
    let today: [Reminder]?
    let tomorrow: [Reminder]?
    let thisWeek: [Reminder]?
    let upcoming: [Reminder]?
    let completed: [Reminder]?
    let birthdayReminders: [BirthdayReminder]?
    let importantDateReminders: [ImportantDateReminder]?
    let stats: ReminderStats?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case reminders, overdue, today, tomorrow, upcoming, completed, stats, total
        case thisWeek = "this_week"
        case birthdayReminders = "birthday_reminders"
        case importantDateReminders = "important_date_reminders"
    }
}
