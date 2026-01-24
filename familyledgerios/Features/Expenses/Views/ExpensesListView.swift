import SwiftUI

struct ExpensesListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ExpensesViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading expenses...")
            } else {
                expensesContent
            }
        }
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.navigate(to: .createBudget)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.refreshExpenses()
        }
        .task {
            await viewModel.loadExpenses()
            await viewModel.loadBudgets()
        }
    }

    private var expensesContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // My Budgets Section
                if !viewModel.budgets.isEmpty {
                    myBudgetsSection
                } else {
                    // Empty state when no budgets
                    VStack(spacing: 16) {
                        Text("💰")
                            .font(.system(size: 64))

                        Text("No Budgets Yet")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Create your first budget to start tracking expenses")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            router.navigate(to: .createBudget)
                        } label: {
                            Text("Create Budget")
                                .font(AppTypography.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(AppColors.primary)
                                .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(48)
                }

                // Spending by Category Section
                if !viewModel.spendingByCategory.isEmpty {
                    spendingByCategorySection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Budget Summary Section

    private var budgetSummarySection: some View {
        VStack(spacing: 12) {
            // Total Budget Card (Main)
            VStack(spacing: 8) {
                Text("Total Budget")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Text(viewModel.stats?.formattedTotalBudget ?? "$0.00")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Monthly budget")
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(AppColors.background)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)

            // Spent and Remaining Cards
            HStack(spacing: 12) {
                // Total Spent Card
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)

                    Text(viewModel.stats?.formattedTotalSpent ?? "$0.00")
                        .font(AppTypography.numberMedium)
                        .foregroundColor(AppColors.error)

                    if let stats = viewModel.stats {
                        Text("\(Int(stats.spentPercentage))%")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.error)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColors.error.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)
                .overlay(
                    Rectangle()
                        .fill(AppColors.error)
                        .frame(width: 4)
                        .cornerRadius(2),
                    alignment: .leading
                )
                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)

                // Remaining Card
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remaining")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)

                    Text(viewModel.stats?.formattedRemaining ?? "$0.00")
                        .font(AppTypography.numberMedium)
                        .foregroundColor(AppColors.success)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)
                .overlay(
                    Rectangle()
                        .fill(AppColors.success)
                        .frame(width: 4)
                        .cornerRadius(2),
                    alignment: .leading
                )
                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
            }
        }
    }

    // MARK: - Overall Progress Bar

    private func overallProgressBar(stats: ExpenseStats) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.secondaryBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(stats.spentPercentage > 80 ? AppColors.warning : AppColors.success)
                        .frame(width: geometry.size.width * min(stats.spentPercentage / 100, 1), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(Int(stats.spentPercentage))% of budget used")
                .font(AppTypography.captionSmall)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - My Budgets Section

    private var myBudgetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Budgets")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(viewModel.budgets.count) budget\(viewModel.budgets.count != 1 ? "s" : "")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            ForEach(viewModel.budgets) { budget in
                BudgetListCard(budget: budget) {
                    router.navigate(to: .budget(id: budget.id))
                }
            }
        }
    }

    // MARK: - Spending by Category Section

    private var spendingByCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.spendingByCategory) { category in
                        CategorySpendingCard(category: category)
                    }
                }
            }
        }
    }

    // MARK: - Recent Expenses Section

    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(viewModel.expenses.count) total")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            if viewModel.expenses.isEmpty {
                VStack(spacing: 12) {
                    Text("📝")
                        .font(.system(size: 64))

                    Text("No Expenses")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Start tracking your expenses")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(48)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.expenses) { expense in
                        ExpenseCard(expense: expense) {
                            router.navigate(to: .expense(id: expense.id))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Budget List Card (Mobile App Style)

struct BudgetListCard: View {
    let budget: Budget
    let action: () -> Void

    var progressColor: Color {
        if budget.isOverBudget == true {
            return AppColors.error
        } else if budget.percentageUsed > 80 {
            return AppColors.warning
        }
        return AppColors.success
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Header Row
                HStack(alignment: .center, spacing: 12) {
                    // Icon
                    Text(budget.displayIcon)
                        .font(.system(size: 22))
                        .frame(width: 48, height: 48)
                        .background(budget.displayColor.opacity(0.2))
                        .cornerRadius(14)

                    // Name and Subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text(budget.name)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text("\(budget.formattedSpent ?? "$0") of \(budget.formattedAmount ?? budget.formattedTotalAmount ?? "$0")")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    // Remaining Amount
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(budget.isOverBudget == true ? "-\(budget.formattedRemaining ?? "$0")" : (budget.formattedRemaining ?? "$0"))
                            .font(AppTypography.headline)
                            .foregroundColor(budget.isOverBudget == true ? AppColors.error : AppColors.success)

                        Text(budget.isOverBudget == true ? "over budget" : "remaining")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                }

                // Progress Bar Row
                HStack(spacing: 10) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.secondaryBackground)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(width: geometry.size.width * min(budget.percentageUsed / 100, 1), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(budget.percentageUsed))%")
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
        .buttonStyle(.plain)
    }
}

// MARK: - Category Spending Card

struct CategorySpendingCard: View {
    let category: SpendingByCategory

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Text(category.categoryIcon ?? "")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(category.displayColor.opacity(0.2))
                .cornerRadius(12)

            // Amount
            Text(category.formattedTotal ?? "$0")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            // Name
            Text(category.categoryName)
                .font(AppTypography.captionSmall)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)

            // Count
            Text("\(category.count) expense\(category.count != 1 ? "s" : "")")
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(width: 120)
        .padding(16)
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Expense Card

struct ExpenseCard: View {
    let expense: Expense
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Category Icon
                Text(expense.category?.icon ?? "")
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background((expense.category?.displayColor ?? AppColors.expenses).opacity(0.2))
                    .cornerRadius(12)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description ?? "Expense")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    Text(expense.date ?? "")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textTertiary)

                    if let category = expense.category {
                        Text(category.name)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(category.displayColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(category.displayColor.opacity(0.15))
                            .cornerRadius(6)
                    }
                }

                Spacer()

                // Amount and Budget
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.formattedAmount ?? "$0.00")
                        .font(AppTypography.numberSmall)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)

                    if let budget = expense.budget {
                        Text(budget.name)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            .padding(16)
            .background(AppColors.background)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Budget Expense Group (for By Budget view)

struct BudgetExpenseGroup: View {
    let budget: Budget
    let expenses: [Expense]
    let onExpenseTap: (Expense) -> Void
    let onBudgetTap: () -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Budget Header
            Button(action: onBudgetTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                                .foregroundColor(AppColors.expenses)

                            Text(budget.name)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.secondaryBackground)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill((budget.isOverBudget ?? false) ? AppColors.error : AppColors.expenses)
                                    .frame(width: geometry.size.width * min(budget.percentageUsed / 100, 1), height: 8)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("\(budget.formattedSpent ?? "$0") of \(budget.formattedAmount ?? "$0")")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)

                            Spacer()

                            Text("\(Int(budget.percentageUsed))%")
                                .font(AppTypography.caption)
                                .foregroundColor((budget.isOverBudget ?? false) ? AppColors.error : AppColors.textSecondary)
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Expenses
            if isExpanded {
                LazyVStack(spacing: 8) {
                    ForEach(expenses) { expense in
                        ExpenseCard(expense: expense) {
                            onExpenseTap(expense)
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Budget Card (for Budgets-only view)

struct BudgetCard: View {
    let budget: Budget
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(budget.name)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text((budget.period ?? "monthly").capitalized)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    // Percentage Badge
                    Text("\(Int(budget.percentageUsed))%")
                        .font(AppTypography.numberSmall)
                        .foregroundColor((budget.isOverBudget ?? false) ? .white : AppColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background((budget.isOverBudget ?? false) ? AppColors.error : AppColors.secondaryBackground)
                        .cornerRadius(8)
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.secondaryBackground)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill((budget.isOverBudget ?? false) ? AppColors.error : AppColors.expenses)
                            .frame(width: geometry.size.width * min(budget.percentageUsed / 100, 1), height: 12)
                    }
                }
                .frame(height: 12)

                // Amounts
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)

                        Text(budget.formattedSpent ?? "$0")
                            .font(AppTypography.numberSmall)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 2) {
                        Text("Remaining")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)

                        Text(budget.formattedRemaining ?? "$0")
                            .font(AppTypography.numberSmall)
                            .foregroundColor((budget.isOverBudget ?? false) ? AppColors.error : AppColors.success)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Budget")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)

                        Text(budget.formattedAmount ?? "$0")
                            .font(AppTypography.numberSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ExpensesListView()
            .environment(AppRouter())
    }
}
