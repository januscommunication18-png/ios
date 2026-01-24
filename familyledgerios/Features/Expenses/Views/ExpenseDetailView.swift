import SwiftUI

struct ExpenseDetailView: View {
    let expenseId: Int

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ExpensesViewModel()
    @State private var showDeleteAlert = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading expense...")
            } else if let expense = viewModel.selectedExpense {
                expenseContent(expense: expense)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadExpense(id: expenseId)
                    }
                }
            } else {
                // Default state - still loading or initial state
                VStack {
                    ProgressView()
                    Text("Loading expense \(expenseId)...")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if viewModel.selectedExpense?.status == .pending {
                        Button {
                            Task {
                                if await viewModel.settleExpense(id: expenseId) {
                                    await viewModel.loadExpense(id: expenseId)
                                }
                            }
                        } label: {
                            Label("Mark as Settled", systemImage: "checkmark.circle")
                        }
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadExpense(id: expenseId)
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteExpense(id: expenseId) {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }

    private func expenseContent(expense: Expense) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Amount Header
                amountHeader(expense: expense)

                // Details Section
                detailsSection(expense: expense)

                // Notes Section
                if let notes = expense.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }

                // Receipt Section - check receiptUrl first (from API), then receiptPath
                if let receiptUrl = expense.receiptUrl, !receiptUrl.isEmpty {
                    receiptSection(path: receiptUrl)
                } else if expense.hasReceipt == true, let receiptPath = expense.receiptPath, !receiptPath.isEmpty {
                    receiptSection(path: receiptPath)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func amountHeader(expense: Expense) -> some View {
        VStack(spacing: 16) {
            // Category Icon (emoji from API)
            Text(expense.category?.icon ?? "💰")
                .font(.system(size: 32))
                .frame(width: 70, height: 70)
                .background((expense.category?.displayColor ?? AppColors.expenses).opacity(0.2))
                .clipShape(Circle())

            VStack(spacing: 8) {
                // Format amount - use formattedAmount or format the raw amount
                if let formattedAmount = expense.formattedAmount {
                    Text(formattedAmount)
                        .font(AppTypography.displayLarge)
                        .foregroundColor(AppColors.textPrimary)
                } else if let amount = expense.amount {
                    Text(String(format: "$%.2f", amount))
                        .font(AppTypography.displayLarge)
                        .foregroundColor(AppColors.textPrimary)
                }

                Text(expense.description ?? "Expense")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textSecondary)

                // Category badge
                if let category = expense.category {
                    Text(category.name)
                        .font(AppTypography.caption)
                        .foregroundColor(category.displayColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(category.displayColor.opacity(0.15))
                        .cornerRadius(16)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    private func detailsSection(expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 0) {
                // Date
                DetailRow(label: "Date", value: expense.displayDate)
                Divider()

                // Payee
                if let payee = expense.payee, !payee.isEmpty {
                    DetailRow(label: "Payee", value: payee)
                    Divider()
                }

                // Type badge row
                HStack {
                    Text("Type")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("Expense")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.error)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
                Divider()

                // Budget
                if let budget = expense.budget {
                    DetailRow(label: "Budget", value: budget.name)
                    Divider()
                }

                // Category
                if let category = expense.category {
                    DetailRow(label: "Category", value: "\(category.icon ?? "") \(category.name)")
                    Divider()
                }

                // Payment Method
                if let paymentMethod = expense.paymentMethod, !paymentMethod.isEmpty {
                    DetailRow(label: "Payment Method", value: paymentMethodDisplayName(paymentMethod))
                    Divider()
                }

                // Recurring
                if expense.isRecurring == true {
                    HStack {
                        Text("Recurring")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 12))
                            Text(recurringFrequencyDisplayName(expense.recurringFrequency))
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                    Divider()
                }

                // Source
                if let sourceLabel = expense.sourceLabel, !sourceLabel.isEmpty {
                    HStack {
                        Text("Source")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: expense.source == "mobile" ? "iphone" : "desktopcomputer")
                                .font(.system(size: 12))
                            Text(sourceLabel)
                                .font(AppTypography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(12)
                    }
                    .padding()
                    Divider()
                }

                // Created At
                if let createdAt = expense.createdAt, !createdAt.isEmpty {
                    DetailRow(label: "Created", value: createdAt)
                }
            }
            .background(AppColors.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }

    private func paymentMethodDisplayName(_ method: String) -> String {
        switch method {
        case "cash": return "Cash"
        case "credit_card": return "Credit Card"
        case "debit_card": return "Debit Card"
        case "bank_transfer": return "Bank Transfer"
        case "check": return "Check"
        default: return method.capitalized
        }
    }

    private func recurringFrequencyDisplayName(_ frequency: String?) -> String {
        guard let frequency = frequency else { return "Recurring" }
        switch frequency {
        case "daily": return "Daily"
        case "weekly": return "Weekly"
        case "biweekly": return "Bi-weekly"
        case "monthly": return "Monthly"
        case "quarterly": return "Quarterly"
        case "yearly": return "Yearly"
        default: return frequency.capitalized
        }
    }

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(notes)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.background)
                .cornerRadius(12)
        }
    }

    private func receiptSection(path: String) -> some View {
        // Use the URL directly - API should return full Digital Ocean Spaces URL
        let fullUrl = path

        return VStack(alignment: .leading, spacing: 12) {
            Text("Receipt")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            if let url = URL(string: fullUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading receipt...")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    case .failure(let error):
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.warning)
                            Text("Unable to load receipt")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                            Text("The image may have restricted access")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)

                            // Show link to open in browser
                            Link(destination: url) {
                                Text("Open in Browser")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)
            } else {
                Text("Invalid receipt URL")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
            }
        }
    }
}

// MARK: - Create Expense View

struct CreateExpenseView: View {
    var preselectedBudgetId: Int? = nil

    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ExpensesViewModel()
    @State private var showImagePicker = false
    @State private var budgetCategories: [BudgetCategoryAllocation] = []

    // Helper to load budget-specific categories
    private func loadBudgetCategories(budgetId: Int) async {
        do {
            let response: BudgetDetailResponse = try await APIClient.shared.request(.budget(id: budgetId))
            if let cats = response.categories {
                budgetCategories = cats
            }
        } catch {
            // Ignore errors for category loading
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Amount Section
                amountSection

                // Details Section
                detailsSection

                // Budget & Category Section
                budgetCategorySection

                // Payment Section
                paymentSection

                // Recurring Section
                recurringSection

                // Notes Section
                notesSection

                // Receipt Section
                receiptSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Add Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if await viewModel.createExpense() {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.description.isEmpty || viewModel.amount.isEmpty)
                .fontWeight(.semibold)
            }
        }
        .task {
            await viewModel.loadBudgets()
            await viewModel.loadCategories()
            // Set preselected budget after budgets are loaded
            if let budgetId = preselectedBudgetId {
                // Find the budget in the loaded list to ensure it exists
                if viewModel.budgets.contains(where: { $0.id == budgetId }) {
                    viewModel.budgetId = budgetId
                    // Also load categories for this budget if it's an envelope budget
                    await loadBudgetCategories(budgetId: budgetId)
                }
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $viewModel.receiptData)
        }
    }

    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(spacing: 16) {
            // Amount Input
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("$")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                TextField("0", text: $viewModel.amount)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 180)
            }
            .frame(maxWidth: .infinity)

            // Quick Amount Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach([10, 25, 50, 100, 200, 500], id: \.self) { amount in
                        Button {
                            viewModel.amount = String(format: "%.2f", Double(amount))
                        } label: {
                            Text("$\(amount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [AppColors.primary.opacity(0.05), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.primary.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 0) {
                // Description
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24)

                    TextField("Description", text: $viewModel.description)
                }
                .padding()

                Divider().padding(.leading, 48)

                // Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24)

                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                        .labelsHidden()

                    Spacer()
                }
                .padding()
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Budget & Category Section
    private var budgetCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget & Category")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 0) {
                // Budget Picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)

                        Text("Budget")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        // Budget dropdown
                        Menu {
                            Button("No Budget") {
                                viewModel.budgetId = nil
                                budgetCategories = []
                            }
                            ForEach(viewModel.budgets) { budget in
                                Button(budget.name) {
                                    viewModel.budgetId = budget.id
                                    Task {
                                        await loadBudgetCategories(budgetId: budget.id)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedBudgetName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }

                    // Show budget info if selected
                    if let budgetId = viewModel.budgetId,
                       let budget = viewModel.budgets.first(where: { $0.id == budgetId }) {
                        HStack(spacing: 12) {
                            Text("Remaining: \(budget.formattedRemaining ?? "$\(String(format: "%.2f", budget.remaining))")")
                                .font(.system(size: 12))
                                .foregroundColor(budget.isOverBudget == true ? AppColors.error : AppColors.success)

                            Text("•")
                                .foregroundColor(AppColors.textTertiary)

                            Text("\(Int(budget.percentageUsed))% used")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.leading, 32)
                    }
                }
                .padding()

                Divider().padding(.leading, 48)

                // Category Picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(AppColors.warning)
                            .frame(width: 24)

                        Text("Category")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        // Category dropdown - shows budget categories if available, otherwise general categories
                        Menu {
                            Button("No Category") {
                                viewModel.categoryId = nil
                            }

                            if !budgetCategories.isEmpty {
                                // Show budget-specific categories
                                ForEach(budgetCategories) { category in
                                    Button("\(category.icon ?? "📦") \(category.name)") {
                                        viewModel.categoryId = category.id
                                    }
                                }
                            } else if !viewModel.categories.isEmpty {
                                // Show general categories
                                ForEach(viewModel.categories) { category in
                                    Button(category.name) {
                                        viewModel.categoryId = category.id
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedCategoryName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    private var selectedBudgetName: String {
        if let budgetId = viewModel.budgetId,
           let budget = viewModel.budgets.first(where: { $0.id == budgetId }) {
            return budget.name
        }
        return "Select Budget"
    }

    private var selectedCategoryName: String {
        if let categoryId = viewModel.categoryId {
            // Check budget categories first
            if let category = budgetCategories.first(where: { $0.id == categoryId }) {
                return "\(category.icon ?? "📦") \(category.name)"
            }
            // Then check general categories
            if let category = viewModel.categories.first(where: { $0.id == categoryId }) {
                return category.name
            }
        }
        return "Select Category"
    }

    // MARK: - Payment Section
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        PaymentMethodChip(
                            method: method,
                            isSelected: viewModel.paymentMethod == method
                        ) {
                            if viewModel.paymentMethod == method {
                                viewModel.paymentMethod = nil
                            } else {
                                viewModel.paymentMethod = method
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recurring Section
    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recurring")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 0) {
                // Toggle
                HStack {
                    Image(systemName: "repeat")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24)

                    Toggle("Make this a recurring expense", isOn: $viewModel.isRecurring)
                }
                .padding()

                if viewModel.isRecurring {
                    Divider().padding(.leading, 48)

                    // Frequency
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 24)

                        Picker("Frequency", selection: $viewModel.recurringFrequency) {
                            Text("Select Frequency").tag(nil as RecurringFrequency?)
                            ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency as RecurringFrequency?)
                            }
                        }
                        .pickerStyle(.menu)

                        Spacer()
                    }
                    .padding()
                }
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack {
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24)
                        .padding(.top, 8)

                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                }
                .padding()
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Receipt Section
    private var receiptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receipt")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Button {
                showImagePicker = true
            } label: {
                HStack {
                    Image(systemName: "camera")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Receipt Photo")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Take a photo or choose from library")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(12)
            }

            if viewModel.receiptData != nil {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)

                    Text("Receipt added")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.success)

                    Spacer()

                    Button("Remove") {
                        viewModel.receiptData = nil
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Payment Method Chip

struct PaymentMethodChip: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)

                Text(method.displayName)
                    .font(AppTypography.captionSmall)
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            }
            .frame(width: 80, height: 70)
            .background(isSelected ? AppColors.primary : AppColors.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Create Budget Wizard

struct CreateBudgetRequest: Encodable {
    let name: String
    let type: String
    let period: String
    let totalAmount: Double
    let startDate: String
    let categories: [BudgetCategoryRequest]?

    enum CodingKeys: String, CodingKey {
        case name, type, period, categories
        case totalAmount = "total_amount"
        case startDate = "start_date"
    }
}

struct BudgetCategoryRequest: Encodable {
    let name: String
    let icon: String
    let color: String
    let allocatedAmount: Double

    enum CodingKeys: String, CodingKey {
        case name, icon, color
        case allocatedAmount = "allocated_amount"
    }
}

struct CreateBudgetResponse: Decodable {
    let budget: Budget?
    let message: String?
}

// MARK: - Budget Category Input Model

struct BudgetCategoryInput: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var color: String
    var allocatedAmount: String
}

// MARK: - Budget Wizard ViewModel

@Observable
final class BudgetWizardViewModel {
    var currentStep = 1

    // Dynamic total steps based on budget type
    var totalSteps: Int {
        budgetType == "envelope" ? 4 : 3
    }

    // Step titles for progress indicator
    var stepTitles: [String] {
        if budgetType == "envelope" {
            return ["Type", "Details", "Envelopes", "Review"]
        } else {
            return ["Type", "Details", "Review"]
        }
    }

    // Step 1: Budget Type
    var budgetType = "envelope"

    // Step 2: Budget Details
    var name = ""
    var period = "monthly"
    var startDate = Date()
    var totalAmount = ""

    // Step 3 (Envelope only): Categories
    var categories: [BudgetCategoryInput] = []

    var isLoading = false
    var errorMessage: String?

    // Budget types
    let budgetTypes: [(id: String, title: String, description: String, icon: String)] = [
        ("envelope", "Envelope Budgeting", "Divide your income into spending categories (envelopes). Each envelope gets a fixed amount.", "tray.2.fill"),
        ("traditional", "Traditional Budget", "Set a total budget amount and track your spending against it.", "chart.line.uptrend.xyaxis")
    ]

    // Periods
    let periods: [(id: String, name: String)] = [
        ("weekly", "Weekly"),
        ("biweekly", "Bi-weekly"),
        ("monthly", "Monthly"),
        ("yearly", "Yearly")
    ]

    // Default categories
    let defaultCategories: [BudgetCategoryInput] = [
        BudgetCategoryInput(name: "Housing", icon: "🏠", color: "#ef4444", allocatedAmount: ""),
        BudgetCategoryInput(name: "Utilities", icon: "💡", color: "#f97316", allocatedAmount: ""),
        BudgetCategoryInput(name: "Groceries", icon: "🛒", color: "#22c55e", allocatedAmount: ""),
        BudgetCategoryInput(name: "Transportation", icon: "🚗", color: "#3b82f6", allocatedAmount: ""),
        BudgetCategoryInput(name: "Healthcare", icon: "🏥", color: "#ec4899", allocatedAmount: ""),
        BudgetCategoryInput(name: "Entertainment", icon: "🎬", color: "#8b5cf6", allocatedAmount: ""),
        BudgetCategoryInput(name: "Dining Out", icon: "🍽️", color: "#f59e0b", allocatedAmount: ""),
        BudgetCategoryInput(name: "Shopping", icon: "🛍️", color: "#06b6d4", allocatedAmount: ""),
        BudgetCategoryInput(name: "Savings", icon: "💰", color: "#10b981", allocatedAmount: ""),
        BudgetCategoryInput(name: "Other", icon: "📦", color: "#6b7280", allocatedAmount: "")
    ]

    var periodLabel: String {
        periods.first { $0.id == period }?.name ?? "Monthly"
    }

    var budgetAmount: Double {
        Double(totalAmount) ?? 0
    }

    var totalAllocated: Double {
        categories.reduce(0) { $0 + (Double($1.allocatedAmount) ?? 0) }
    }

    var remainingToAllocate: Double {
        budgetAmount - totalAllocated
    }

    var canProceed: Bool {
        switch currentStep {
        case 1: return true // Type is pre-selected
        case 2: return !name.isEmpty && !totalAmount.isEmpty
        case 3:
            if budgetType == "envelope" {
                // At least one category with name and amount
                return categories.contains { !$0.name.isEmpty && (Double($0.allocatedAmount) ?? 0) > 0 }
            } else {
                return true // Review step for traditional
            }
        case 4: return true // Review step for envelope
        default: return false
        }
    }

    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }

    func initializeCategories() {
        if categories.isEmpty {
            categories = defaultCategories
        }
    }

    func addCategory() {
        let icons = ["🏠", "💡", "🛒", "🚗", "🏥", "🎬", "🍽️", "🛍️", "💰", "📦"]
        let colors = ["#ef4444", "#f97316", "#22c55e", "#3b82f6", "#ec4899", "#8b5cf6", "#f59e0b", "#06b6d4", "#10b981", "#6b7280"]
        let index = categories.count % icons.count

        categories.append(BudgetCategoryInput(
            name: "",
            icon: icons[index],
            color: colors[index],
            allocatedAmount: ""
        ))
    }

    func removeCategory(_ category: BudgetCategoryInput) {
        if categories.count > 1 {
            categories.removeAll { $0.id == category.id }
        }
    }

    @MainActor
    func createBudget() async -> Bool {
        isLoading = true
        errorMessage = nil

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let categoryRequests: [BudgetCategoryRequest]? = budgetType == "envelope" ? categories.compactMap { cat in
            guard !cat.name.isEmpty else { return nil }
            return BudgetCategoryRequest(
                name: cat.name,
                icon: cat.icon,
                color: cat.color,
                allocatedAmount: Double(cat.allocatedAmount) ?? 0
            )
        } : nil

        let request = CreateBudgetRequest(
            name: name,
            type: budgetType,
            period: period,
            totalAmount: Double(totalAmount) ?? 0,
            startDate: dateFormatter.string(from: startDate),
            categories: categoryRequests
        )

        do {
            let _: CreateBudgetResponse = try await APIClient.shared.request(.createBudget, body: request)
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create budget"
        }

        isLoading = false
        return false
    }
}

// MARK: - Create Budget View (Wizard Container)

struct CreateBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BudgetWizardViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            BudgetWizardProgressBar(
                currentStep: viewModel.currentStep,
                totalSteps: viewModel.totalSteps,
                stepTitles: viewModel.stepTitles
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Step content
            TabView(selection: $viewModel.currentStep) {
                BudgetStep1TypeView(viewModel: viewModel).tag(1)
                BudgetStep2DetailsView(viewModel: viewModel).tag(2)

                if viewModel.budgetType == "envelope" {
                    BudgetStep3EnvelopesView(viewModel: viewModel).tag(3)
                    BudgetStep4ReviewView(viewModel: viewModel, dismiss: dismiss).tag(4)
                } else {
                    BudgetStepReviewView(viewModel: viewModel, dismiss: dismiss).tag(3)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // Navigation buttons
            HStack {
                if viewModel.currentStep > 1 {
                    Button {
                        viewModel.previousStep()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Button {
                    if viewModel.currentStep == viewModel.totalSteps {
                        Task {
                            if await viewModel.createBudget() {
                                dismiss()
                            }
                        }
                    } else {
                        viewModel.nextStep()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text(viewModel.currentStep == viewModel.totalSteps ? "Create Budget" : "Continue")
                            .fontWeight(.semibold)
                        if viewModel.currentStep < viewModel.totalSteps {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(viewModel.canProceed ? AppColors.primary : AppColors.primary.opacity(0.5))
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canProceed || viewModel.isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Create Budget")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.initializeCategories()
        }
    }
}

// MARK: - Progress Bar

struct BudgetWizardProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]

    var body: some View {
        VStack(spacing: 8) {
            // Step indicators
            HStack(spacing: 0) {
                ForEach(1...totalSteps, id: \.self) { step in
                    HStack(spacing: 0) {
                        // Circle
                        ZStack {
                            Circle()
                                .fill(step <= currentStep ? AppColors.primary : Color(.systemGray4))
                                .frame(width: 32, height: 32)

                            if step < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(step)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(step == currentStep ? .white : Color(.systemGray))
                            }
                        }

                        // Line (except for last step)
                        if step < totalSteps {
                            Rectangle()
                                .fill(step < currentStep ? AppColors.primary : Color(.systemGray4))
                                .frame(height: 3)
                        }
                    }
                }
            }

            // Step labels
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Text(stepTitles[index])
                        .font(.system(size: 11, weight: index + 1 == currentStep ? .semibold : .regular))
                        .foregroundColor(index + 1 <= currentStep ? AppColors.primary : Color(.systemGray))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Step 1: Budget Type

struct BudgetStep1TypeView: View {
    @Bindable var viewModel: BudgetWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose Your Budgeting Method")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Select how you want to manage your money")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Budget type options
                VStack(spacing: 16) {
                    ForEach(viewModel.budgetTypes, id: \.id) { type in
                        BudgetTypeSelectionCard(
                            type: type,
                            isSelected: viewModel.budgetType == type.id,
                            isRecommended: type.id == "envelope"
                        ) {
                            viewModel.budgetType = type.id
                            // Reset step if switching types
                            if viewModel.currentStep > 2 {
                                viewModel.currentStep = 2
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct BudgetTypeSelectionCard: View {
    let type: (id: String, title: String, description: String, icon: String)
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : AppColors.primary)
                        .frame(width: 56, height: 56)
                        .background(isSelected ? AppColors.primary : AppColors.primary.opacity(0.1))
                        .cornerRadius(16)

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(type.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)

                            if isRecommended {
                                Text("Recommended")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppColors.success)
                                    .cornerRadius(8)
                            }
                        }

                        Text(type.description)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? AppColors.primary : Color(.systemGray4))
                }
            }
            .padding(16)
            .background(isSelected ? AppColors.primary.opacity(0.05) : AppColors.background)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primary : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Budget Details

struct BudgetStep2DetailsView: View {
    @Bindable var viewModel: BudgetWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget Details")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Name your budget and set the time period")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Form fields
                VStack(spacing: 20) {
                    // Budget Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Budget Name")
                                .font(.system(size: 14, weight: .medium))
                            Text("*")
                                .foregroundColor(.red)
                        }
                        .foregroundColor(AppColors.textPrimary)

                        TextField("e.g., Family Budget, Monthly Expenses", text: $viewModel.name)
                            .padding()
                            .background(AppColors.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }

                    // Budget Period
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Period")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        Menu {
                            ForEach(viewModel.periods, id: \.id) { period in
                                Button(period.name) {
                                    viewModel.period = period.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.periodLabel)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color(.systemGray))
                            }
                            .padding()
                            .background(AppColors.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }

                        Text("How often do you want to reset your budget?")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.systemGray))
                    }

                    // Start Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }

                    // Amount / Income
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(viewModel.budgetType == "envelope" ? "\(viewModel.periodLabel) Income" : "Total Budget")
                                .font(.system(size: 14, weight: .medium))
                            Text("*")
                                .foregroundColor(.red)
                        }
                        .foregroundColor(AppColors.textPrimary)

                        HStack {
                            Text("$")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            TextField("0.00", text: $viewModel.totalAmount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 18))
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )

                        // Quick amount buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([2000, 3000, 4000, 5000, 6000, 8000, 10000], id: \.self) { amount in
                                    Button {
                                        viewModel.totalAmount = String(format: "%.2f", Double(amount))
                                    } label: {
                                        Text("$\(amount.formatted())")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(AppColors.secondaryBackground)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        if viewModel.budgetType == "envelope" {
                            Text("Enter your total income for this budget period. This will be the amount you allocate to your envelopes.")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.systemGray))
                        }
                    }
                }

                // Info box for envelope budgeting
                if viewModel.budgetType == "envelope" {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppColors.success)
                            .font(.system(size: 18))

                        Text("With envelope budgeting, your income is divided into \"envelopes\" for different spending categories. Each envelope gets a fixed amount, helping you control where your money goes.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.success.opacity(0.9))
                    }
                    .padding(16)
                    .background(AppColors.success.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Step 3: Envelopes (Envelope Budget Only)

struct BudgetStep3EnvelopesView: View {
    @Bindable var viewModel: BudgetWizardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set Up Your Envelopes")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Divide your income into spending categories")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(viewModel.periodLabel) Income: \(String(format: "$%.2f", viewModel.budgetAmount))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.success)
                }

                // Allocation Summary Card
                VStack(spacing: 12) {
                    HStack {
                        Text("Total Allocated")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(String(format: "$%.2f", viewModel.totalAllocated))
                            .font(.system(size: 16, weight: .semibold))
                    }

                    HStack {
                        Text("\(viewModel.periodLabel) Income")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(String(format: "$%.2f", viewModel.budgetAmount))
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Divider()

                    HStack {
                        Text("Unallocated")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(String(format: "$%.2f", viewModel.remainingToAllocate))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.remainingToAllocate >= 0 ? AppColors.success : AppColors.error)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.remainingToAllocate >= 0 ? AppColors.success : AppColors.error)
                                .frame(width: viewModel.budgetAmount > 0 ? geometry.size.width * min(viewModel.totalAllocated / viewModel.budgetAmount, 1) : 0, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(16)
                .background(AppColors.background)
                .cornerRadius(12)

                // Categories
                VStack(spacing: 12) {
                    ForEach($viewModel.categories) { $category in
                        EnvelopeCategoryRow(category: $category) {
                            viewModel.removeCategory(category)
                        }
                    }

                    // Add category button
                    Button {
                        viewModel.addCategory()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add Envelope")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct EnvelopeCategoryRow: View {
    @Binding var category: BudgetCategoryInput
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(category.icon)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(Color(hex: category.color).opacity(0.2))
                .cornerRadius(12)

            // Name
            TextField("Category name", text: $category.name)
                .font(.system(size: 15))

            // Amount
            HStack(spacing: 2) {
                Text("$")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)

                TextField("0", text: $category.allocatedAmount)
                    .font(.system(size: 15, weight: .medium))
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Delete
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.error.opacity(0.7))
            }
        }
        .padding(12)
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

// MARK: - Step 4: Review (Envelope Budget)

struct BudgetStep4ReviewView: View {
    @Bindable var viewModel: BudgetWizardViewModel
    let dismiss: DismissAction

    var body: some View {
        BudgetReviewContent(viewModel: viewModel)
    }
}

// MARK: - Review Step (Traditional Budget - Step 3)

struct BudgetStepReviewView: View {
    @Bindable var viewModel: BudgetWizardViewModel
    let dismiss: DismissAction

    var body: some View {
        BudgetReviewContent(viewModel: viewModel)
    }
}

// MARK: - Shared Review Content

struct BudgetReviewContent: View {
    @Bindable var viewModel: BudgetWizardViewModel

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review Your Budget")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Make sure everything looks good before creating")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Budget Details Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Budget Details")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    VStack(spacing: 12) {
                        ReviewRow(label: "Name", value: viewModel.name)
                        ReviewRow(label: "Type", value: viewModel.budgetType == "envelope" ? "Envelope Budgeting" : "Traditional Budget")
                        ReviewRow(label: "Period", value: viewModel.periodLabel)
                        ReviewRow(label: "Start Date", value: dateFormatter.string(from: viewModel.startDate))
                        ReviewRow(
                            label: viewModel.budgetType == "envelope" ? "\(viewModel.periodLabel) Income" : "Total Budget",
                            value: String(format: "$%.2f", viewModel.budgetAmount),
                            valueColor: AppColors.success
                        )
                    }
                }
                .padding(16)
                .background(AppColors.background)
                .cornerRadius(12)

                // Categories (for envelope only)
                if viewModel.budgetType == "envelope" {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Envelopes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            Text("\(viewModel.categories.filter { !$0.name.isEmpty }.count) categories")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        VStack(spacing: 8) {
                            ForEach(viewModel.categories.filter { !$0.name.isEmpty }) { category in
                                HStack {
                                    Text(category.icon)
                                        .font(.system(size: 18))

                                    Text(category.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textPrimary)

                                    Spacer()

                                    Text(String(format: "$%.2f", Double(category.allocatedAmount) ?? 0))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .padding(.vertical, 8)

                                if category.id != viewModel.categories.filter({ !$0.name.isEmpty }).last?.id {
                                    Divider()
                                }
                            }

                            Divider()
                                .padding(.vertical, 4)

                            HStack {
                                Text("Total Allocated")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                Text(String(format: "$%.2f", viewModel.totalAllocated))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(viewModel.totalAllocated <= viewModel.budgetAmount ? AppColors.success : AppColors.error)
                            }
                        }
                    }
                    .padding(16)
                    .background(AppColors.background)
                    .cornerRadius(12)
                }

                // Success message
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                        .font(.system(size: 20))

                    Text("Your budget is ready to be created. You can edit it anytime from the budget details screen.")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(16)
                .background(AppColors.success.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(24)
        }
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    var valueColor: Color = AppColors.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Budget Detail View

struct BudgetDetailView: View {
    let budgetId: Int

    @Environment(AppRouter.self) private var router
    @State private var viewModel = ExpensesViewModel()
    @State private var showAddExpense = false

    private var progressColor: Color {
        guard let budget = viewModel.budgetDetail else { return AppColors.success }
        if budget.isOverBudget == true { return AppColors.error }
        if budget.percentageUsed > 80 { return AppColors.warning }
        return AppColors.success
    }

    var body: some View {
        ZStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading budget...")
                } else if let budget = viewModel.budgetDetail {
                    budgetContent(budget: budget)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadBudget(id: budgetId)
                        }
                    }
                } else {
                    VStack {
                        ProgressView()
                        Text("Loading budget \(budgetId)...")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            // Floating Add Expense Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showAddExpense = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Add Expense")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(AppColors.primary)
                        .cornerRadius(28)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(viewModel.budgetDetail?.name ?? "Budget")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBudget(id: budgetId)
        }
        .sheet(isPresented: $showAddExpense) {
            NavigationStack {
                CreateExpenseView(preselectedBudgetId: budgetId)
            }
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showAddExpense) { _, isPresented in
            // Reload budget when expense sheet is dismissed
            if !isPresented {
                Task {
                    await viewModel.loadBudget(id: budgetId)
                }
            }
        }
    }

    private func budgetContent(budget: BudgetDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Summary Card
                budgetHeader(budget: budget)

                VStack(spacing: 20) {
                    // Categories Section
                    if !viewModel.budgetCategories.isEmpty {
                        categoriesSection
                    }

                    // Transactions Section
                    transactionsSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Budget Header

    private func budgetHeader(budget: BudgetDetail) -> some View {
        VStack(spacing: 16) {
            // Period Label
            Text("\(budget.periodLabel ?? budget.period?.capitalized ?? "Monthly") Budget")
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.8))

            // Summary Row
            HStack(spacing: 0) {
                // Budget
                VStack(spacing: 4) {
                    Text("Budget")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(.white.opacity(0.8))
                    Text(budget.formattedAmount ?? budget.formattedTotalAmount ?? "$0")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 40)

                // Spent
                VStack(spacing: 4) {
                    Text("Spent")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(.white.opacity(0.8))
                    Text(budget.formattedSpent ?? "$0")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 40)

                // Remaining
                VStack(spacing: 4) {
                    Text(budget.isOverBudget == true ? "Over" : "Left")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(.white.opacity(0.8))
                    Text(budget.formattedRemaining ?? "$0")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)

            // Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * min(budget.percentageUsed / 100, 1), height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(Int(budget.percentageUsed))% used")
                    .font(AppTypography.captionSmall)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: budget.isOverBudget == true ? [Color.red, Color.red.opacity(0.8)] : [AppColors.primary, AppColors.primary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            ForEach(viewModel.budgetCategories) { category in
                CategoryAllocationCard(category: category)
            }
        }
    }

    // MARK: - Transactions Section

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transactions")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(viewModel.budgetExpenses.count) this month")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            if viewModel.budgetExpenses.isEmpty {
                VStack(spacing: 12) {
                    Text("📝")
                        .font(.system(size: 48))

                    Text("No Transactions")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("No expenses recorded for this budget this month")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(AppColors.background)
                .cornerRadius(16)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.budgetExpenses) { expense in
                        BudgetTransactionRow(expense: expense) {
                            router.navigate(to: .expense(id: expense.id))
                        }

                        if expense.id != viewModel.budgetExpenses.last?.id {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(AppColors.background)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Category Allocation Card

struct CategoryAllocationCard: View {
    let category: BudgetCategoryAllocation

    private var progressColor: Color {
        if category.isOverBudget == true { return AppColors.error }
        if category.percentageUsed > 80 { return AppColors.warning }
        return AppColors.success
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                Text(category.icon ?? "📁")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(category.displayColor.opacity(0.2))
                    .cornerRadius(12)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("\(category.formattedSpent ?? "$0") of \(category.formattedAllocated ?? "$0")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // Remaining
                VStack(alignment: .trailing, spacing: 2) {
                    Text(category.formattedRemaining ?? "$0")
                        .font(AppTypography.headline)
                        .foregroundColor(category.isOverBudget == true ? AppColors.error : AppColors.success)

                    Text(category.isOverBudget == true ? "over" : "left")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            // Progress Bar
            HStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.secondaryBackground)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * min(category.percentageUsed / 100, 1), height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(Int(category.percentageUsed))%")
                    .font(AppTypography.captionSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(16)
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Budget Transaction Row

struct BudgetTransactionRow: View {
    let expense: Expense
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Text(expense.category?.icon ?? "💰")
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background((expense.category?.displayColor ?? AppColors.expenses).opacity(0.2))
                    .cornerRadius(10)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.description ?? "Expense")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    Text(expense.date ?? "")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                // Amount
                Text(expense.formattedAmount ?? "$0.00")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Image Picker

import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                guard let uiImage = image as? UIImage else { return }

                // Compress image to reduce size
                let maxSize: CGFloat = 1024
                let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
                let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)

                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                if let data = resizedImage?.jpegData(compressionQuality: 0.7) {
                    DispatchQueue.main.async {
                        self?.parent.imageData = data
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExpenseDetailView(expenseId: 1)
            .environment(AppRouter())
    }
}
