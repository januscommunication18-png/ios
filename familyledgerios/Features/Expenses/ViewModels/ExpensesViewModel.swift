import Foundation

struct CreateExpenseRequest: Encodable {
    let description: String
    let amount: Double
    let categoryId: Int?
    let budgetId: Int?
    let transactionDate: String
    let paymentMethod: String?
    let isRecurring: Bool
    let recurringFrequency: String?
    let notes: String
    let receipt: String?

    enum CodingKeys: String, CodingKey {
        case description, amount, notes, receipt
        case categoryId = "category_id"
        case budgetId = "budget_id"
        case transactionDate = "transaction_date"
        case paymentMethod = "payment_method"
        case isRecurring = "is_recurring"
        case recurringFrequency = "recurring_frequency"
    }
}

@Observable
final class ExpensesViewModel {
    var expenses: [Expense] = []
    var stats: ExpenseStats?
    var categories: [ExpenseCategory] = []
    var budgets: [Budget] = []
    var spendingByCategory: [SpendingByCategory] = []
    var selectedExpense: Expense?
    var selectedBudget: Budget?
    var budgetDetail: BudgetDetail?
    var budgetCategories: [BudgetCategoryAllocation] = []
    var budgetExpenses: [Expense] = []

    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var successMessage: String?

    // MARK: - Form Fields
    var description = ""
    var amount = ""
    var categoryId: Int?
    var budgetId: Int?
    var date = Date()
    var paymentMethod: PaymentMethod?
    var isRecurring = false
    var recurringFrequency: RecurringFrequency?
    var notes = ""
    var receiptData: Data?

    // For budget-wise grouping
    var expensesByBudget: [Int?: [Expense]] {
        Dictionary(grouping: expenses) { $0.budgetId }
    }

    // MARK: - Computed Properties

    var hasExpenses: Bool {
        !expenses.isEmpty
    }

    var hasBudgets: Bool {
        !budgets.isEmpty
    }

    // MARK: - Expenses Methods

    @MainActor
    func loadExpenses() async {
        isLoading = expenses.isEmpty
        errorMessage = nil

        do {
            let response: ExpensesResponse = try await APIClient.shared.request(.expenses)
            expenses = response.expenses ?? []
            stats = response.stats
            categories = response.categories ?? []
            spendingByCategory = response.spendingByCategory ?? []
            // Load budgets from response if available
            if let responseBudgets = response.budgets, !responseBudgets.isEmpty {
                budgets = responseBudgets
            }
            print("Loaded \(expenses.count) expenses, \(budgets.count) budgets, \(spendingByCategory.count) categories")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("Expenses API Error: \(error)")
        } catch {
            errorMessage = "Failed to load expenses"
            print("Expenses Error: \(error)")
        }

        isLoading = false
    }

    @MainActor
    func refreshExpenses() async {
        isRefreshing = true

        do {
            let response: ExpensesResponse = try await APIClient.shared.request(.expenses)
            expenses = response.expenses ?? []
            stats = response.stats
        } catch {
            // Silently fail on refresh
        }

        isRefreshing = false
    }

    @MainActor
    func loadExpense(id: Int) async {
        isLoading = true
        errorMessage = nil
        selectedExpense = nil

        do {
            let response: ExpenseDetailResponse = try await APIClient.shared.request(.expense(id: id))
            selectedExpense = response.expense
        } catch let error as DecodingError {
            errorMessage = "Failed to parse expense data"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load expense details"
        }

        isLoading = false
    }

    @MainActor
    func loadCategories() async {
        do {
            // Try wrapped response first
            let response: CategoriesListResponse = try await APIClient.shared.request(.expenseCategories)
            categories = response.categories
        } catch {
            // Try array response as fallback
            do {
                let response: [ExpenseCategory] = try await APIClient.shared.request(.expenseCategories)
                categories = response
            } catch {
                // Categories loading is optional
                print("Failed to load categories: \(error)")
            }
        }
    }

    @MainActor
    func createExpense() async -> Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return false
        }

        guard !description.isEmpty else {
            errorMessage = "Please enter a description"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            // Convert receipt data to base64 if available
            var receiptBase64: String? = nil
            if let data = receiptData {
                receiptBase64 = "data:image/jpeg;base64," + data.base64EncodedString()
            }

            let body = CreateExpenseRequest(
                description: description,
                amount: amountValue,
                categoryId: categoryId,
                budgetId: budgetId,
                transactionDate: date.apiDateString,
                paymentMethod: paymentMethod?.rawValue,
                isRecurring: isRecurring,
                recurringFrequency: isRecurring ? recurringFrequency?.rawValue : nil,
                notes: notes,
                receipt: receiptBase64
            )

            let _: CreateExpenseResponse = try await APIClient.shared.request(.createExpense, body: body)
            successMessage = "Expense created successfully"
            clearForm()
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create expense: \(error.localizedDescription)"
        }

        isLoading = false
        return false
    }

    @MainActor
    func deleteExpense(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await APIClient.shared.requestEmpty(.deleteExpense(id: id))
            expenses.removeAll { $0.id == id }
            successMessage = "Expense deleted successfully"
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to delete expense"
        }

        isLoading = false
        return false
    }

    @MainActor
    func settleExpense(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _: Expense = try await APIClient.shared.request(.settleExpense(id: id))
            if let index = expenses.firstIndex(where: { $0.id == id }) {
                await loadExpense(id: id)
                if let updated = selectedExpense {
                    expenses[index] = updated
                }
            }
            successMessage = "Expense settled"
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to settle expense"
        }

        isLoading = false
        return false
    }

    // MARK: - Budget Methods

    @MainActor
    func loadBudgets() async {
        do {
            // Try wrapped response first (API returns {budgets: [...], total: n})
            let response: BudgetsListResponse = try await APIClient.shared.request(.budgets)
            budgets = response.budgets
            print("Loaded \(budgets.count) budgets from wrapped response")
        } catch {
            // Try array response as fallback
            do {
                let response: [Budget] = try await APIClient.shared.request(.budgets)
                budgets = response
                print("Loaded \(budgets.count) budgets from array response")
            } catch {
                // Budgets loading is optional
                print("Failed to load budgets: \(error)")
            }
        }
    }

    @MainActor
    func loadBudget(id: Int) async {
        isLoading = true
        errorMessage = nil
        budgetDetail = nil
        budgetCategories = []
        budgetExpenses = []

        do {
            let response: BudgetDetailResponse = try await APIClient.shared.request(.budget(id: id))
            budgetDetail = response.budget
            budgetCategories = response.categories ?? []
            budgetExpenses = response.expenses ?? []
        } catch let error as DecodingError {
            errorMessage = "Failed to parse budget data"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load budget details"
        }

        isLoading = false
    }

    // MARK: - Filtering

    func filterExpenses(by status: ExpenseStatus?) -> [Expense] {
        guard let status = status else { return expenses }
        return expenses.filter { $0.status == status }
    }

    func filterExpenses(by category: ExpenseCategory?) -> [Expense] {
        guard let category = category else { return expenses }
        return expenses.filter { $0.categoryId == category.id }
    }

    func searchExpenses(query: String) -> [Expense] {
        guard !query.isEmpty else { return expenses }
        let lowercasedQuery = query.lowercased()
        return expenses.filter {
            $0.description?.lowercased().contains(lowercasedQuery) == true ||
            $0.category?.name.lowercased().contains(lowercasedQuery) == true
        }
    }

    // MARK: - Helper Methods

    func clearForm() {
        description = ""
        amount = ""
        categoryId = nil
        budgetId = nil
        date = Date()
        paymentMethod = nil
        isRecurring = false
        recurringFrequency = nil
        notes = ""
        receiptData = nil
    }

    func clearError() {
        errorMessage = nil
    }

    func clearSuccess() {
        successMessage = nil
    }
}
