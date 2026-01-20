import Foundation
import SwiftUI

struct JournalEntry: Codable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let content: String?
    let type: String?
    let typeLabel: String?
    let mood: String?
    let moodEmoji: String?
    let moodLabel: String?
    let date: String?
    let time: String?
    let formattedDate: String?
    let isPinned: Bool?
    let isDraft: Bool?
    let status: String?
    let visibility: String?
    let visibilityLabel: String?
    let tags: [JournalTag]?
    let photos: [String]?
    let attachments: [JournalAttachment]?
    let author: JournalAuthor?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, content, type, mood, date, time, tags, photos, attachments, author, status, visibility
        case typeLabel = "type_label"
        case moodEmoji = "mood_emoji"
        case moodLabel = "mood_label"
        case formattedDate = "formatted_date"
        case isPinned = "is_pinned"
        case isDraft = "is_draft"
        case visibilityLabel = "visibility_label"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool { lhs.id == rhs.id }
}

struct JournalAttachment: Codable, Identifiable {
    let id: Int
    let type: String?
    let filePath: String?
    let fileName: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id, type, url
        case filePath = "file_path"
        case fileName = "file_name"
    }
}

struct JournalAuthor: Codable {
    let id: Int
    let name: String?
    let avatar: String?
}

struct JournalTag: Codable, Identifiable {
    let id: Int
    let name: String
}

struct JournalStats: Codable {
    let total: Int?
    let drafts: Int?
    let thisMonth: Int?

    enum CodingKeys: String, CodingKey {
        case total, drafts
        case thisMonth = "this_month"
    }
}

struct JournalResponse: Codable {
    let entries: [JournalEntry]?
    let pinnedEntries: [JournalEntry]?
    let stats: JournalStats?
    let tags: [JournalTag]?

    enum CodingKeys: String, CodingKey {
        case entries, stats, tags
        case pinnedEntries = "pinned_entries"
    }
}

struct JournalEntryDetailResponse: Codable {
    let entry: JournalEntry
}
