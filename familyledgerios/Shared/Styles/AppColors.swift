import SwiftUI

struct AppColors {
    // MARK: - Primary Colors
    static let primary = Color(hex: "6366f1")        // Indigo
    static let primaryDark = Color(hex: "4f46e5")
    static let primaryLight = Color(hex: "818cf8")

    // MARK: - Feature Colors
    static let expenses = Color(hex: "059669")       // Green
    static let expensesLight = Color(hex: "10b981")

    static let coparenting = Color(hex: "7c3aed")    // Purple
    static let coparentingLight = Color(hex: "8b5cf6")

    static let goals = Color(hex: "f59e0b")          // Amber
    static let goalsLight = Color(hex: "fbbf24")

    static let family = Color(hex: "3b82f6")         // Blue
    static let familyLight = Color(hex: "60a5fa")

    static let journal = Color(hex: "ec4899")        // Pink
    static let journalLight = Color(hex: "f472b6")

    static let shopping = Color(hex: "14b8a6")       // Teal
    static let shoppingLight = Color(hex: "2dd4bf")

    static let pets = Color(hex: "f97316")           // Orange
    static let petsLight = Color(hex: "fb923c")

    static let reminders = Color(hex: "ef4444")      // Red
    static let remindersLight = Color(hex: "f87171")

    static let assets = Color(hex: "06b6d4")         // Cyan
    static let assetsLight = Color(hex: "22d3ee")

    // MARK: - Status Colors
    static let success = Color(hex: "22c55e")
    static let warning = Color(hex: "f59e0b")
    static let error = Color(hex: "ef4444")
    static let info = Color(hex: "3b82f6")

    // MARK: - Priority Colors
    static let priorityHigh = Color(hex: "ef4444")
    static let priorityMedium = Color(hex: "f59e0b")
    static let priorityLow = Color(hex: "22c55e")

    // MARK: - Mood Colors
    static let moodHappy = Color(hex: "fbbf24")
    static let moodSad = Color(hex: "60a5fa")
    static let moodNeutral = Color(hex: "9ca3af")
    static let moodExcited = Color(hex: "f472b6")
    static let moodAnxious = Color(hex: "a78bfa")
    static let moodGrateful = Color(hex: "34d399")

    // MARK: - Background Colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)

    // MARK: - Text Colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Border & Divider
    static let border = Color(.separator)
    static let divider = Color(.separator)

    // MARK: - Gradient Presets
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coparentingGradient = LinearGradient(
        colors: [coparenting, coparentingLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let expensesGradient = LinearGradient(
        colors: [expenses, expensesLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Category Colors

extension AppColors {
    static func forCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "expenses", "finance", "money": return expenses
        case "family", "members": return family
        case "goals", "tasks": return goals
        case "journal", "memories": return journal
        case "shopping", "lists": return shopping
        case "pets", "animals": return pets
        case "reminders", "calendar": return reminders
        case "assets", "property": return assets
        case "coparenting", "custody": return coparenting
        default: return primary
        }
    }

    static func forPriority(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return priorityHigh
        case "medium": return priorityMedium
        case "low": return priorityLow
        default: return textSecondary
        }
    }

    static func forMood(_ mood: String) -> Color {
        switch mood.lowercased() {
        case "happy": return moodHappy
        case "sad": return moodSad
        case "neutral": return moodNeutral
        case "excited": return moodExcited
        case "anxious": return moodAnxious
        case "grateful": return moodGrateful
        default: return moodNeutral
        }
    }
}
