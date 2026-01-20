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

                // Receipt Section
                if let receiptPath = expense.receiptPath, !receiptPath.isEmpty {
                    receiptSection(path: receiptPath)
                } else if let receiptUrl = expense.receiptUrl, !receiptUrl.isEmpty {
                    receiptSection(path: receiptUrl)
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
                    DetailRow(label: "Category", value: category.name)
                }
            }
            .background(AppColors.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
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
        // Construct full URL - if it's already a full URL, use it; otherwise construct from base
        let fullUrl: String
        if path.starts(with: "http") {
            fullUrl = path
        } else {
            // Construct URL from base (remove /api/v1 and add /storage/)
            let baseUrl = "http://localhost:8000"
            fullUrl = "\(baseUrl)/storage/\(path)"
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Receipt")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            AsyncImage(url: URL(string: fullUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 200)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text("Failed to load receipt")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(height: 200)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Create Expense View

struct CreateExpenseView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ExpensesViewModel()
    @State private var showImagePicker = false

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
            await viewModel.loadCategories()
            await viewModel.loadBudgets()
        }
        .loadingOverlay(viewModel.isLoading)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("Amount")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                TextField("0.00", text: $viewModel.amount)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        .cornerRadius(16)
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
                // Budget
                HStack {
                    Image(systemName: "chart.pie")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24)

                    Picker("Budget", selection: $viewModel.budgetId) {
                        Text("No Budget").tag(nil as Int?)
                        ForEach(viewModel.budgets) { budget in
                            Text(budget.name).tag(budget.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()
                }
                .padding()

                Divider().padding(.leading, 48)

                // Category
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24)

                    Picker("Category", selection: $viewModel.categoryId) {
                        Text("No Category").tag(nil as Int?)
                        ForEach(viewModel.categories) { category in
                            HStack {
                                Image(systemName: category.displayIcon)
                                Text(category.name)
                            }
                            .tag(category.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()
                }
                .padding()
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
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

// MARK: - Budget Detail View

struct BudgetDetailView: View {
    let budgetId: Int

    @Environment(AppRouter.self) private var router
    @State private var viewModel = ExpensesViewModel()

    private var progressColor: Color {
        guard let budget = viewModel.budgetDetail else { return AppColors.success }
        if budget.isOverBudget == true { return AppColors.error }
        if budget.percentageUsed > 80 { return AppColors.warning }
        return AppColors.success
    }

    var body: some View {
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
        .navigationTitle(viewModel.budgetDetail?.name ?? "Budget")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBudget(id: budgetId)
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

#Preview {
    NavigationStack {
        ExpenseDetailView(expenseId: 1)
            .environment(AppRouter())
    }
}
