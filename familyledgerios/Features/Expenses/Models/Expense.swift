import Foundation

struct Expense: Codable, Identifiable, Equatable {
    let id: Int
    let description: String?
    let amountValue: StringOrDouble?
    let formattedAmount: String?
    let categoryId: Int?
    let category: ExpenseCategory?
    let budgetId: Int?
    let budget: Budget?
    let date: String?
    let transactionDate: String?
    let payee: String?
    let paidBy: String?
    let paidById: Int?
    let splitWith: [ExpenseSplit]?
    let paymentMethod: String?
    let isRecurring: Bool?
    let recurringFrequency: String?
    let status: ExpenseStatus?
    let receiptUrl: String?
    let receiptPath: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?

    var amount: Double? {
        amountValue?.doubleValue
    }

    // Display date - prefer formatted date, fallback to transaction_date
    var displayDate: String {
        if let date = date, !date.isEmpty {
            return date
        }
        if let txDate = transactionDate {
            // Format the ISO date string
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let dateObj = formatter.date(from: txDate) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                return displayFormatter.string(from: dateObj)
            }
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let dateObj = formatter.date(from: txDate) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                return displayFormatter.string(from: dateObj)
            }
        }
        return "Unknown date"
    }

    enum CodingKeys: String, CodingKey {
        case id, description, category, date, status, notes, budget, payee
        case amountValue = "amount"
        case formattedAmount = "formatted_amount"
        case categoryId = "category_id"
        case budgetId = "budget_id"
        case transactionDate = "transaction_date"
        case paidBy = "paid_by"
        case paidById = "paid_by_id"
        case splitWith = "split_with"
        case paymentMethod = "payment_method"
        case isRecurring = "is_recurring"
        case recurringFrequency = "recurring_frequency"
        case receiptUrl = "receipt_url"
        case receiptPath = "receipt_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: Expense, rhs: Expense) -> Bool {
        lhs.id == rhs.id
    }
}

struct ExpenseSplit: Codable, Identifiable {
    let id: Int
    let memberId: Int?
    let memberName: String?
    let amount: StringOrDouble?
    let percentage: StringOrDouble?
    let isPaid: Bool?

    enum CodingKeys: String, CodingKey {
        case id, amount, percentage
        case memberId = "member_id"
        case memberName = "member_name"
        case isPaid = "is_paid"
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case bankTransfer = "bank_transfer"
    case check
    case other

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .bankTransfer: return "Bank Transfer"
        case .check: return "Check"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "banknote"
        case .creditCard: return "creditcard"
        case .debitCard: return "creditcard.fill"
        case .bankTransfer: return "building.columns"
        case .check: return "doc.text"
        case .other: return "ellipsis.circle"
        }
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

enum ExpenseStatus: String, Codable, CaseIterable {
    case pending
    case settled

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .settled: return "Settled"
        }
    }

    var color: Color {
        switch self {
        case .pending: return AppColors.warning
        case .settled: return AppColors.success
        }
    }
}

struct ExpenseCategory: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let icon: String?
    let color: String?

    var displayIcon: String {
        icon ?? "dollarsign.circle"
    }

    var displayColor: Color {
        if let hexColor = color {
            return Color(hex: hexColor)
        }
        return AppColors.expenses
    }

    static func == (lhs: ExpenseCategory, rhs: ExpenseCategory) -> Bool {
        lhs.id == rhs.id
    }
}

struct ExpenseStats: Codable {
    let thisMonthValue: StringOrDouble?
    let lastMonthValue: StringOrDouble?
    let pendingValue: StringOrDouble?
    let owedToYouValue: StringOrDouble?
    let formattedThisMonth: String?
    let formattedLastMonth: String?
    let formattedPending: String?
    let formattedOwedToYou: String?
    // Budget stats
    let totalBudgetValue: StringOrDouble?
    let totalSpentValue: StringOrDouble?
    let remainingValue: StringOrDouble?
    let spentPercentageValue: StringOrDouble?
    let formattedTotalBudget: String?
    let formattedTotalSpent: String?
    let formattedRemaining: String?

    var thisMonth: Double? { thisMonthValue?.doubleValue }
    var lastMonth: Double? { lastMonthValue?.doubleValue }
    var pending: Double? { pendingValue?.doubleValue }
    var owedToYou: Double? { owedToYouValue?.doubleValue }
    var totalBudget: Double? { totalBudgetValue?.doubleValue }
    var totalSpent: Double? { totalSpentValue?.doubleValue }
    var remaining: Double? { remainingValue?.doubleValue }
    var spentPercentage: Double { spentPercentageValue?.doubleValue ?? 0 }

    enum CodingKeys: String, CodingKey {
        case thisMonthValue = "this_month"
        case lastMonthValue = "last_month"
        case pendingValue = "pending"
        case owedToYouValue = "owed_to_you"
        case formattedThisMonth = "formatted_this_month"
        case formattedLastMonth = "formatted_last_month"
        case formattedPending = "formatted_pending"
        case formattedOwedToYou = "formatted_owed_to_you"
        case totalBudgetValue = "total_budget"
        case totalSpentValue = "total_spent"
        case remainingValue = "remaining"
        case spentPercentageValue = "spent_percentage"
        case formattedTotalBudget = "formatted_total_budget"
        case formattedTotalSpent = "formatted_total_spent"
        case formattedRemaining = "formatted_remaining"
    }
}

struct ExpensesResponse: Codable {
    let expenses: [Expense]?
    let stats: ExpenseStats?
    let categories: [ExpenseCategory]?
    let budgets: [Budget]?
    let spendingByCategory: [SpendingByCategory]?

    enum CodingKeys: String, CodingKey {
        case expenses, stats, categories, budgets
        case spendingByCategory = "spending_by_category"
    }
}

struct ExpenseDetailResponse: Codable {
    let expense: Expense
}

struct SpendingByCategory: Codable, Identifiable {
    let categoryId: Int?
    let categoryName: String
    let categoryIcon: String?
    let categoryColor: String?
    let total: StringOrDouble?
    let formattedTotal: String?
    let count: Int

    var id: Int { categoryId ?? 0 }

    var displayColor: Color {
        if let hexColor = categoryColor {
            return Color(hex: hexColor)
        }
        return AppColors.expenses
    }

    enum CodingKeys: String, CodingKey {
        case count
        case categoryId = "category_id"
        case categoryName = "category_name"
        case categoryIcon = "category_icon"
        case categoryColor = "category_color"
        case total
        case formattedTotal = "formatted_total"
    }
}

struct Budget: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String?
    let icon: String?
    let color: String?
    let amountValue: StringOrDouble?
    let formattedAmount: String?
    let totalAmountValue: StringOrDouble?
    let formattedTotalAmount: String?
    let spentValue: StringOrDouble?
    let formattedSpent: String?
    let remainingValue: StringOrDouble?
    let formattedRemaining: String?
    let percentageUsedValue: StringOrDouble?
    let spentPercentage: StringOrDouble?
    let categoryId: Int?
    let category: ExpenseCategory?
    let period: String?
    let startDate: String?
    let endDate: String?
    let isOverBudget: Bool?

    var amount: Double { amountValue?.doubleValue ?? totalAmountValue?.doubleValue ?? 0 }
    var spent: Double { spentValue?.doubleValue ?? 0 }
    var remaining: Double { remainingValue?.doubleValue ?? 0 }
    var percentageUsed: Double { percentageUsedValue?.doubleValue ?? spentPercentage?.doubleValue ?? 0 }

    var displayIcon: String {
        icon ?? "📊"
    }

    var displayColor: Color {
        if let hexColor = color {
            return Color(hex: hexColor)
        }
        return AppColors.expenses
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color, period, category
        case amountValue = "amount"
        case totalAmountValue = "total_amount"
        case formattedTotalAmount = "formatted_total_amount"
        case spentValue = "spent"
        case remainingValue = "remaining"
        case formattedAmount = "formatted_amount"
        case formattedSpent = "formatted_spent"
        case formattedRemaining = "formatted_remaining"
        case percentageUsedValue = "percentage_used"
        case spentPercentage = "spent_percentage"
        case categoryId = "category_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case isOverBudget = "is_over_budget"
    }

    static func == (lhs: Budget, rhs: Budget) -> Bool {
        lhs.id == rhs.id
    }
}

enum BudgetPeriod: String, Codable, CaseIterable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Budget Detail Response

struct BudgetDetailResponse: Codable {
    let budget: BudgetDetail?
    let categories: [BudgetCategoryAllocation]?
    let expenses: [Expense]?
}

struct BudgetDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let icon: String?
    let color: String?
    let period: String?
    let periodLabel: String?
    let amountValue: StringOrDouble?
    let formattedAmount: String?
    let totalAmountValue: StringOrDouble?
    let formattedTotalAmount: String?
    let spentValue: StringOrDouble?
    let formattedSpent: String?
    let remainingValue: StringOrDouble?
    let formattedRemaining: String?
    let spentPercentage: StringOrDouble?
    let isOverBudget: Bool?
    let startDate: String?
    let endDate: String?

    var amount: Double { amountValue?.doubleValue ?? totalAmountValue?.doubleValue ?? 0 }
    var spent: Double { spentValue?.doubleValue ?? 0 }
    var remaining: Double { remainingValue?.doubleValue ?? 0 }
    var percentageUsed: Double { spentPercentage?.doubleValue ?? 0 }

    var displayIcon: String { icon ?? "📊" }

    var displayColor: Color {
        if let hexColor = color {
            return Color(hex: hexColor)
        }
        return AppColors.expenses
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color, period
        case periodLabel = "period_label"
        case amountValue = "amount"
        case totalAmountValue = "total_amount"
        case formattedAmount = "formatted_amount"
        case formattedTotalAmount = "formatted_total_amount"
        case spentValue = "spent"
        case formattedSpent = "formatted_spent"
        case remainingValue = "remaining"
        case formattedRemaining = "formatted_remaining"
        case spentPercentage = "spent_percentage"
        case isOverBudget = "is_over_budget"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct BudgetCategoryAllocation: Codable, Identifiable {
    let id: Int
    let name: String
    let icon: String?
    let color: String?
    let allocatedAmountValue: StringOrDouble?
    let formattedAllocated: String?
    let spentValue: StringOrDouble?
    let formattedSpent: String?
    let remainingValue: StringOrDouble?
    let formattedRemaining: String?
    let spentPercentage: StringOrDouble?
    let isOverBudget: Bool?

    var allocatedAmount: Double { allocatedAmountValue?.doubleValue ?? 0 }
    var spent: Double { spentValue?.doubleValue ?? 0 }
    var remaining: Double { remainingValue?.doubleValue ?? 0 }
    var percentageUsed: Double { spentPercentage?.doubleValue ?? 0 }

    var displayColor: Color {
        if let hexColor = color {
            return Color(hex: hexColor)
        }
        return AppColors.expenses
    }

    enum CodingKeys: String, CodingKey {
        case id, name, icon, color
        case allocatedAmountValue = "allocated_amount"
        case formattedAllocated = "formatted_allocated"
        case spentValue = "spent"
        case formattedSpent = "formatted_spent"
        case remainingValue = "remaining"
        case formattedRemaining = "formatted_remaining"
        case spentPercentage = "spent_percentage"
        case isOverBudget = "is_over_budget"
    }
}

import SwiftUI
