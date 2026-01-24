import SwiftUI

// Notification names for goal/task creation
extension Notification.Name {
    static let goalCreated = Notification.Name("goalCreated")
    static let taskCreated = Notification.Name("taskCreated")
    static let taskCompleted = Notification.Name("taskCompleted")
}

struct GoalsListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = GoalsViewModel()
    @State private var selectedTab = 1  // Default to Tasks tab
    @State private var showSuccessMessage = false
    @State private var successMessage = ""

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading goals...")
            } else {
                goalsContent
            }
        }
        .navigationTitle("Goals & Tasks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        router.navigate(to: .createGoal)
                    } label: {
                        Label("New Goal", systemImage: "target")
                    }

                    Button {
                        router.navigate(to: .createTask(goalId: nil))
                    } label: {
                        Label("New Task", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable { await viewModel.refreshGoals() }
        .task { await viewModel.loadGoals() }
        .onReceive(NotificationCenter.default.publisher(for: .goalCreated)) { _ in
            showGoalAddedSuccess()
            Task { await viewModel.refreshGoals() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskCompleted)) { _ in
            successMessage = "Task completed successfully!"
            showSuccessMessage = true
            Task { await viewModel.refreshGoals() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showSuccessMessage = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskCreated)) { _ in
            showTaskAddedSuccess()
            Task { await viewModel.refreshGoals() }
        }
    }

    private var goalsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success Message Banner
                if showSuccessMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text(successMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            withAnimation { showSuccessMessage = false }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(AppColors.success)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("Goals").tag(0)
                    Text("Tasks").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == 0 {
                    goalsSection
                } else {
                    tasksSection
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    func showGoalAddedSuccess() {
        successMessage = "Goal added successfully!"
        withAnimation { showSuccessMessage = true }
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showSuccessMessage = false }
        }
    }

    func showTaskAddedSuccess() {
        successMessage = "Task added successfully!"
        withAnimation { showSuccessMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showSuccessMessage = false }
        }
    }

    private var goalsSection: some View {
        VStack(spacing: 12) {
            if viewModel.goals.isEmpty {
                EmptyStateView.noGoals { router.navigate(to: .createGoal) }
            } else {
                ForEach(viewModel.goals) { goal in
                    GoalCard(goal: goal) { router.navigate(to: .goal(id: goal.id)) }
                }
            }
        }
        .padding(.horizontal)
    }

    private var tasksSection: some View {
        VStack(spacing: 16) {
            if viewModel.tasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No Tasks Yet")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Create a goal first, then add tasks to it")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        router.navigate(to: .createGoal)
                    } label: {
                        Text("Create a Goal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(AppColors.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.vertical, 40)
            } else {
                // Task Stats Row
                taskStatsRow

                // Open Tasks
                let openTasks = viewModel.tasks.filter { $0.isOpen }
                let completedTasks = viewModel.tasks.filter { $0.isCompleted }

                VStack(spacing: 12) {
                    ForEach(openTasks) { task in
                        TaskCard(task: task) { router.navigate(to: .task(id: task.id)) }
                    }
                }

                // Completed Tasks (Collapsible)
                if !completedTasks.isEmpty {
                    completedTasksSection(tasks: completedTasks)
                }
            }
        }
        .padding(.horizontal)
    }

    private var taskStatsRow: some View {
        let openCount = viewModel.tasks.filter { $0.isOpen }.count
        let completedCount = viewModel.tasks.filter { $0.isCompleted }.count
        let recurringCount = viewModel.tasks.filter { $0.isRecurring == true }.count

        return HStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("\(openCount)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("to do")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }

            if recurringCount > 0 {
                HStack(spacing: 4) {
                    Text("\(recurringCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                    Text("recurring")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            HStack(spacing: 4) {
                Text("\(completedCount)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.success)
                Text("completed")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }

    @State private var showCompletedTasksInList = false

    private func completedTasksSection(tasks: [GoalTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Button {
                withAnimation {
                    showCompletedTasksInList.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showCompletedTasksInList ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                    Text("Completed (\(tasks.count))")
                        .font(.system(size: 14))
                }
                .foregroundColor(AppColors.textSecondary)
            }

            if showCompletedTasksInList {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(10)) { task in
                        Button {
                            router.navigate(to: .task(id: task.id))
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.success)

                                Text(task.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textTertiary)
                                    .strikethrough()
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .opacity(0.6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)

                        if let date = goal.targetDate {
                            Text("Target: \(date)")
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    Spacer()
                    Badge(text: statusDisplayName(goal.status), color: statusColor(goal.status))
                }

                ProgressView(value: Double(goal.progress ?? 0) / 100)
                    .tint(AppColors.goals)

                HStack {
                    Text("\(goal.progress ?? 0)% complete")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Badge(text: priorityDisplayName(goal.priority), color: priorityColor(goal.priority))
                }
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func statusDisplayName(_ status: String?) -> String {
        (status ?? "active").replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "completed": return AppColors.success
        case "paused": return AppColors.warning
        default: return AppColors.primary
        }
    }

    private func priorityDisplayName(_ priority: String?) -> String {
        (priority ?? "medium").capitalized
    }

    private func priorityColor(_ priority: String?) -> Color {
        switch priority?.lowercased() {
        case "high": return AppColors.error
        case "low": return AppColors.textSecondary
        default: return AppColors.warning
        }
    }
}

struct TaskCard: View {
    let task: GoalTask
    let action: () -> Void

    private let categoryInfo: [String: (emoji: String, name: String, color: Color)] = [
        "home_chores": ("🏠", "Home", Color.blue.opacity(0.1)),
        "bills": ("💵", "Bills", Color.green.opacity(0.1)),
        "health": ("💊", "Health", Color.red.opacity(0.1)),
        "kids": ("👶", "Kids", Color.purple.opacity(0.1)),
        "car": ("🚗", "Car", Color.orange.opacity(0.1)),
        "pet_care": ("🐾", "Pet Care", Color.brown.opacity(0.1)),
        "family_rituals": ("👨‍👩‍👧‍👦", "Family", Color.pink.opacity(0.1)),
        "admin": ("📋", "Admin", Color.gray.opacity(0.1))
    ]

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Title and badges row
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Title
                        Text(task.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Badges row
                        HStack(spacing: 6) {
                            // Category badge
                            if let info = categoryInfo[task.listName ?? "home_chores"] ?? categoryInfo["home_chores"] {
                                HStack(spacing: 4) {
                                    Text(info.emoji)
                                        .font(.system(size: 11))
                                    Text(info.name)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(info.color)
                                .cornerRadius(12)
                            }

                            // Priority badge (only show high/urgent)
                            if task.priority == "urgent" {
                                Text("Urgent")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                            } else if task.priority == "high" {
                                Text("High")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                            }

                            // Recurring badge
                            if task.isRecurring == true {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 10))
                                    Text("Recurring")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                }

                // Description (if any)
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }

                // Due date and meta info
                HStack(spacing: 12) {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(formatDueDate(dueDate))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(isOverdue(dueDate) ? .red : AppColors.textSecondary)
                    }

                    if let dueTime = task.dueTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(dueTime)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()
                }
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDueDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInTomorrow(date) {
                return "Tomorrow"
            } else if isOverdue(dateString) {
                formatter.dateFormat = "MMM d"
                return "Overdue (\(formatter.string(from: date)))"
            } else {
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
        return dateString
    }

    private func isOverdue(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            return date < Calendar.current.startOfDay(for: Date())
        }
        return false
    }
}

struct GoalDetailView: View {
    let goalId: Int
    @Environment(AppRouter.self) private var router
    @State private var viewModel = GoalsViewModel()
    @State private var showCompletedTasks = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading goal...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadGoal(id: goalId) }
                }
            } else if let goal = viewModel.selectedGoal {
                goalContent(goal: goal)
            } else {
                LoadingView(message: "Loading goal...")
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.navigate(to: .createTask(goalId: goalId))
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        .task { await viewModel.loadGoal(id: goalId) }
    }

    private func goalContent(goal: Goal) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                headerCard(goal: goal)

                // Progress Section (for milestone goals)
                if goal.goalType == "milestone" {
                    milestoneProgressCard(goal: goal)
                }

                // Reward Section (if rewards enabled)
                if goal.rewardsEnabled == true {
                    rewardCard(goal: goal)
                }

                // Stats Grid
                statsGrid(goal: goal)

                // Linked Tasks Section
                linkedTasksCard(goal: goal)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header Card

    private func headerCard(goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Category Emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(categoryColor(goal.categoryColor).opacity(0.15))
                        .frame(width: 64, height: 64)

                    Text(goal.categoryEmoji ?? "🎯")
                        .font(.system(size: 32))
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Title and Badges
                    HStack(spacing: 8) {
                        Text(goal.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()
                    }

                    // Status and Kid Goal badges
                    HStack(spacing: 8) {
                        Badge(text: "\(goal.statusEmoji) \(statusDisplayName(goal.status))", color: statusColor(goal.status))

                        if goal.isKidGoal == true {
                            Badge(text: "Kid Goal", color: .orange)
                        }
                    }

                    // Description
                    if let description = goal.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, 4)
                    }
                }
            }

            // Meta Info Row
            HStack(spacing: 16) {
                // Goal Type
                HStack(spacing: 4) {
                    Text(goal.goalTypeEmoji)
                    Text(goal.goalTypeLabel)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                    if goal.goalType == "habit", let freq = goal.habitFrequency {
                        Text("(\(freq.capitalized))")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                // Assignment
                HStack(spacing: 4) {
                    Text(goal.assignmentEmoji)
                    Text(goal.assignmentLabel)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Check-in frequency
                if let checkIn = goal.checkInFrequency {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 12))
                        Text("\(checkIn.capitalized) check-ins")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Milestone Progress Card

    private func milestoneProgressCard(goal: Goal) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(goal.milestoneCurrent ?? 0) / \(goal.milestoneTarget ?? 0) \(goal.milestoneUnit ?? "units")")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer()
                Text("\(Int(goal.milestoneProgress ?? 0))%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(goal.status == "done" ? AppColors.success : AppColors.goals)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(categoryColor(goal.categoryColor))
                        .frame(width: geometry.size.width * CGFloat(min(100, goal.milestoneProgress ?? 0)) / 100, height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }

    // MARK: - Reward Card

    private func rewardCard(goal: Goal) -> some View {
        HStack(spacing: 12) {
            Text(goal.rewardEmoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text("Reward: \(goal.rewardLabel)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                if let custom = goal.rewardCustom, !custom.isEmpty, goal.rewardType == "custom" {
                    Text(custom)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            if goal.status == "done" && goal.rewardClaimed != true {
                Button("Claim!") {
                    // TODO: Claim reward
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            } else if goal.rewardClaimed == true {
                Badge(text: "Claimed!", color: AppColors.success)
            } else {
                Text("Complete goal to claim")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding()
        .background(goal.rewardClaimed == true ? AppColors.success.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Stats Grid

    private func statsGrid(goal: Goal) -> some View {
        HStack(spacing: 12) {
            StatBox(title: "Active Tasks", value: "\(goal.activeTasksCount ?? 0)", color: .blue)
            StatBox(title: "Completed", value: "\(goal.completedTasksCount ?? 0)", color: .purple)
        }
    }

    // MARK: - Linked Tasks Card

    private func linkedTasksCard(goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Linked Tasks")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button {
                    router.navigate(to: .createTask(goalId: goalId))
                } label: {
                    Label("Add Task", systemImage: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.primary)
                        .cornerRadius(8)
                }
            }

            if viewModel.selectedGoalTasks.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 48, height: 48)
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    Text("No tasks linked to this goal yet.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                    Button {
                        router.navigate(to: .createTask(goalId: goalId))
                    } label: {
                        Text("Add First Task")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.primary, lineWidth: 1)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Open Tasks
                let openTasks = viewModel.selectedGoalTasks.filter { $0.isOpen }
                let completedTasks = viewModel.selectedGoalTasks.filter { $0.isCompleted }

                VStack(spacing: 8) {
                    ForEach(openTasks) { task in
                        taskRow(task: task)
                    }
                }

                // Completed Tasks (Collapsible)
                if !completedTasks.isEmpty {
                    Divider()
                        .padding(.vertical, 8)

                    Button {
                        withAnimation {
                            showCompletedTasks.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showCompletedTasks ? "chevron.down" : "chevron.right")
                                .font(.system(size: 12))
                            Text("Completed (\(completedTasks.count))")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    if showCompletedTasks {
                        VStack(spacing: 8) {
                            ForEach(completedTasks) { task in
                                completedTaskRow(task: task)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Task Row

    private func taskRow(task: GoalTask) -> some View {
        Button {
            router.navigate(to: .task(id: task.id))
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(task.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        if task.isRecurring == true {
                            Badge(text: "Recurring", color: .blue)
                        }

                        if task.countTowardGoal == true {
                            Image(systemName: "target")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.primary)
                        }
                    }

                    if let dueDate = task.dueDate {
                        Text("Due: \(formatDate(dueDate))")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func completedTaskRow(task: GoalTask) -> some View {
        Button {
            router.navigate(to: .task(id: task.id))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.success)

                Text(task.title)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
                    .strikethrough()

                Spacer()
            }
            .padding(8)
            .opacity(0.6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Functions

    private func statusDisplayName(_ status: String?) -> String {
        switch status?.lowercased() {
        case "active", "in_progress": return "Active"
        case "done", "completed": return "Completed"
        case "paused", "archived": return "Paused"
        default: return (status ?? "active").capitalized
        }
    }

    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "done", "completed": return AppColors.success
        case "paused", "archived": return AppColors.warning
        default: return AppColors.primary
        }
    }

    private func categoryColor(_ color: String?) -> Color {
        switch color {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        default: return AppColors.goals
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Helper Views

private struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

struct TaskDetailView: View {
    let taskId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GoalsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading task...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadTask(id: taskId) }
                }
            } else if let task = viewModel.selectedTask {
                taskContent(task: task)
            } else {
                LoadingView(message: "Loading task...")
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadTask(id: taskId) }
    }

    private func taskContent(task: GoalTask) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(task.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .strikethrough(task.status == "completed")

                        Spacer()

                        Badge(text: statusDisplayName(task.status), color: statusColor(task.status))
                    }

                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Meta Info
                    HStack(spacing: 16) {
                        if let priority = task.priority {
                            Label(priority.capitalized, systemImage: "flag.fill")
                                .font(.system(size: 13))
                                .foregroundColor(priorityColor(priority))
                        }

                        if task.isRecurring == true {
                            Label("Recurring", systemImage: "repeat")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.info)
                        }

                        if let dueDate = task.dueDate {
                            Label(formatDate(dueDate), systemImage: "calendar")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Details Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("DETAILS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(0.5)

                    VStack(spacing: 0) {
                        DetailRow(label: "Status", value: statusDisplayName(task.status))
                        Divider()
                        if let priority = task.priority {
                            DetailRow(label: "Priority", value: priority.capitalized)
                            Divider()
                        }
                        if let dueDate = task.dueDate {
                            DetailRow(label: "Due Date", value: formatDate(dueDate))
                            Divider()
                        }
                        if let dueTime = task.dueTime {
                            DetailRow(label: "Due Time", value: dueTime)
                            Divider()
                        }
                        if task.isRecurring == true, let pattern = task.recurrencePattern {
                            DetailRow(label: "Recurrence", value: pattern.capitalized)
                            Divider()
                        }
                        if let listName = task.listName {
                            DetailRow(label: "List", value: listName)
                            Divider()
                        }
                        if let createdAt = task.createdAt {
                            DetailRow(label: "Created", value: formatDateTime(createdAt))
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Mark as Complete Button
                if task.status != "completed" {
                    Button {
                        Task {
                            await viewModel.toggleTask(id: taskId)
                            NotificationCenter.default.post(name: .taskCompleted, object: nil)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Mark as Complete")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.success)
                        .cornerRadius(12)
                    }
                } else {
                    // Reopen button for completed tasks
                    Button {
                        Task {
                            await viewModel.toggleTask(id: taskId)
                            NotificationCenter.default.post(name: .taskCompleted, object: nil)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.system(size: 20))
                            Text("Reopen Task")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.warning)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func statusDisplayName(_ status: String?) -> String {
        switch status?.lowercased() {
        case "completed": return "Completed"
        case "in_progress": return "In Progress"
        case "pending": return "Pending"
        default: return (status ?? "pending").replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "completed": return AppColors.success
        case "in_progress": return AppColors.primary
        default: return AppColors.warning
        }
    }

    private func priorityColor(_ priority: String?) -> Color {
        switch priority?.lowercased() {
        case "high", "urgent": return AppColors.error
        case "low": return AppColors.textSecondary
        default: return AppColors.warning
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }

    private func formatDateTime(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GoalsViewModel()
    @State private var currentStep: GoalCreationStep = .choose
    @State private var selectedTemplate: GoalTemplate? = nil

    enum GoalCreationStep {
        case choose
        case templates
        case form
    }

    // Goal Templates
    private let templates: [(audience: String, audienceLabel: String, audienceEmoji: String, items: [GoalTemplate])] = [
        ("family", "Family Goals", "👨‍👩‍👧‍👦", [
            GoalTemplate(id: 1, title: "Family Game Night", description: "Weekly family bonding time", emoji: "🎲", category: "family", goalType: "habit", habitFrequency: "weekly"),
            GoalTemplate(id: 2, title: "Family Savings Goal", description: "Save together for something special", emoji: "💰", category: "finance", goalType: "milestone", milestoneTarget: 1000, milestoneUnit: "dollars"),
            GoalTemplate(id: 3, title: "Eat Dinner Together", description: "Have family meals together", emoji: "🍽️", category: "family", goalType: "habit", habitFrequency: "daily"),
            GoalTemplate(id: 4, title: "Family Vacation Fund", description: "Save for a family trip", emoji: "✈️", category: "finance", goalType: "milestone", milestoneTarget: 2000, milestoneUnit: "dollars"),
        ]),
        ("kids", "Kid Goals", "👧👦", [
            GoalTemplate(id: 5, title: "Read 20 Books", description: "Become a reading champion", emoji: "📚", category: "education", goalType: "milestone", milestoneTarget: 20, milestoneUnit: "books", isKidGoal: true, suggestedReward: true, rewardType: "sticker"),
            GoalTemplate(id: 6, title: "Make My Bed Daily", description: "Start the day with a tidy room", emoji: "🛏️", category: "personal_growth", goalType: "habit", habitFrequency: "daily", isKidGoal: true, suggestedReward: true, rewardType: "sticker"),
            GoalTemplate(id: 7, title: "Brush Teeth Twice Daily", description: "Keep those teeth healthy", emoji: "🦷", category: "health", goalType: "habit", habitFrequency: "daily", isKidGoal: true),
            GoalTemplate(id: 8, title: "Practice Instrument", description: "30 minutes of practice", emoji: "🎹", category: "education", goalType: "habit", habitFrequency: "daily", isKidGoal: true),
            GoalTemplate(id: 9, title: "Homework Before Play", description: "Complete homework first", emoji: "✏️", category: "education", goalType: "habit", habitFrequency: "daily", isKidGoal: true),
            GoalTemplate(id: 10, title: "Save Allowance", description: "Learn to save money", emoji: "🐷", category: "finance", goalType: "milestone", milestoneTarget: 50, milestoneUnit: "dollars", isKidGoal: true, suggestedReward: true, rewardType: "treat"),
        ]),
        ("parents", "Parent Goals", "👫", [
            GoalTemplate(id: 11, title: "Date Night Monthly", description: "Quality time together", emoji: "💑", category: "family", goalType: "habit", habitFrequency: "monthly"),
            GoalTemplate(id: 12, title: "Emergency Fund", description: "Build financial security", emoji: "🏦", category: "finance", goalType: "milestone", milestoneTarget: 5000, milestoneUnit: "dollars"),
            GoalTemplate(id: 13, title: "Exercise Together", description: "Stay healthy as a couple", emoji: "🏃", category: "health", goalType: "habit", habitFrequency: "weekly"),
            GoalTemplate(id: 14, title: "Learn Something New", description: "Take a class together", emoji: "🎓", category: "education", goalType: "one_time"),
        ]),
        ("personal", "Personal Goals", "🧑", [
            GoalTemplate(id: 15, title: "Morning Routine", description: "Start each day right", emoji: "🌅", category: "personal_growth", goalType: "habit", habitFrequency: "daily"),
            GoalTemplate(id: 16, title: "Drink More Water", description: "Stay hydrated daily", emoji: "💧", category: "health", goalType: "habit", habitFrequency: "daily"),
            GoalTemplate(id: 17, title: "Meditation Practice", description: "Find inner peace", emoji: "🧘", category: "health", goalType: "habit", habitFrequency: "daily"),
            GoalTemplate(id: 18, title: "Career Development", description: "Grow professionally", emoji: "📈", category: "career", goalType: "one_time"),
        ])
    ]

    // Categories matching web
    private let categories: [(key: String, emoji: String, label: String)] = [
        ("personal_growth", "🌱", "Personal Growth"),
        ("finance", "💰", "Finance"),
        ("health", "💪", "Health"),
        ("family", "👨‍👩‍👧‍👦", "Family"),
        ("education", "📚", "Education"),
        ("career", "💼", "Career")
    ]

    // Goal types matching web
    private let goalTypes: [(key: String, emoji: String, label: String, description: String)] = [
        ("one_time", "🎯", "One-time", "Complete once"),
        ("habit", "🔄", "Habit", "Repeat regularly"),
        ("milestone", "📊", "Milestone", "Track progress")
    ]

    // Habit frequencies
    private let habitFrequencies: [(key: String, label: String)] = [
        ("daily", "Daily"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly")
    ]

    // Check-in frequencies (matching API: daily, weekly, monthly)
    private let checkInFrequencies: [(key: String, label: String)] = [
        ("daily", "Daily"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly")
    ]

    // Reward types (matching API: sticker, points, treat, outing, custom)
    private let rewardTypes: [(key: String, emoji: String, label: String)] = [
        ("sticker", "⭐", "Sticker/Star"),
        ("points", "🏆", "Points"),
        ("treat", "🍦", "Special Treat"),
        ("outing", "🎢", "Fun Outing"),
        ("custom", "✨", "Custom")
    ]

    var body: some View {
        Group {
            switch currentStep {
            case .choose:
                chooseMethodView
            case .templates:
                templateSelectionView
            case .form:
                goalFormView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if currentStep == .form {
                    Button("Create") {
                        Task {
                            if await viewModel.createGoal() {
                                NotificationCenter.default.post(name: .goalCreated, object: nil)
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.title.isEmpty || viewModel.isLoading)
                }
            }
        }
    }

    private var navigationTitle: String {
        switch currentStep {
        case .choose: return "New Goal"
        case .templates: return "Choose Template"
        case .form: return selectedTemplate != nil ? "Create Goal" : "New Goal"
        }
    }

    // MARK: - Step 1: Choose Method View

    private var chooseMethodView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("How would you like to start?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Choose to create from scratch or use a pre-made template")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Options
                VStack(spacing: 16) {
                    // Create from Scratch
                    Button {
                        selectedTemplate = nil
                        withAnimation { currentStep = .form }
                    } label: {
                        VStack(spacing: 12) {
                            Text("✏️")
                                .font(.system(size: 48))
                            Text("Create from Scratch")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Start with a blank goal and customize everything")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .padding(.horizontal, 20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Use Template
                    Button {
                        withAnimation { currentStep = .templates }
                    } label: {
                        VStack(spacing: 12) {
                            Text("💡")
                                .font(.system(size: 48))
                            Text("Use a Template")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Pick from pre-made goals for families & kids")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)

                            let totalTemplates = templates.flatMap { $0.items }.count
                            Text("\(totalTemplates) templates")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(AppColors.primary)
                                .cornerRadius(12)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .padding(.horizontal, 20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2A: Template Selection View

    private var templateSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(templates, id: \.audience) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Group Header
                        HStack(spacing: 8) {
                            Text(group.audienceEmoji)
                                .font(.system(size: 20))
                            Text(group.audienceLabel)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("\(group.items.count)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)

                        // Templates Grid
                        VStack(spacing: 8) {
                            ForEach(group.items) { template in
                                templateCard(template: template)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func templateCard(template: GoalTemplate) -> some View {
        Button {
            applyTemplate(template)
        } label: {
            HStack(spacing: 12) {
                Text(template.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    if let description = template.description {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func applyTemplate(_ template: GoalTemplate) {
        selectedTemplate = template
        viewModel.title = template.title
        viewModel.description = template.description ?? ""
        viewModel.category = template.category
        viewModel.goalType = template.goalType
        viewModel.habitFrequency = template.habitFrequency ?? ""
        if let target = template.milestoneTarget {
            viewModel.milestoneTarget = String(target)
        }
        viewModel.milestoneUnit = template.milestoneUnit ?? ""
        viewModel.isKidGoal = template.isKidGoal
        viewModel.rewardsEnabled = template.suggestedReward
        viewModel.rewardType = template.rewardType ?? ""

        withAnimation { currentStep = .form }
    }

    // Quick select groups for assignment
    private let assignmentGroups: [(id: String, emoji: String, label: String, description: String)] = [
        ("family", "👨‍👩‍👧‍👦", "Entire Family", "All family members"),
        ("parents", "👫", "Parents Only", "Just the parents"),
        ("kids", "👧👦", "All Kids", "All children"),
        ("individual", "👤", "Individual", "Select specific members")
    ]

    // MARK: - Step 2B: Goal Form View

    private var goalFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Template indicator
                if let template = selectedTemplate {
                    HStack(spacing: 8) {
                        Text(template.emoji)
                            .font(.system(size: 16))
                        Text("Creating from template:")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                        Text(template.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                    }
                    .padding()
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(10)
                }

                // Basic Info Section
                basicInfoSection

                // Assignment Section - Who is this for?
                assignmentSection

                // Goal Type Section
                goalTypeSection

                // Check-ins & Rewards Section
                checkInsRewardsSection

                // Kid Settings Section (shown if isKidGoal)
                if viewModel.isKidGoal {
                    kidSettingsSection
                }

                // Error Message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    // MARK: - Assignment Section

    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Text("👥")
                    .font(.system(size: 18))
                Text("Who is this for?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: 16) {
                // Quick Select Label
                Text("Quick Select")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Quick Select Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(assignmentGroups, id: \.id) { group in
                        assignmentGroupCard(group: group)
                    }
                }

                // Kid Goal Toggle
                Toggle(isOn: $viewModel.isKidGoal) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kid-friendly goal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Show emoji status and star ratings")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.primary)
                .padding(.top, 8)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private func assignmentGroupCard(group: (id: String, emoji: String, label: String, description: String)) -> some View {
        Button {
            viewModel.assignmentType = group.id
        } label: {
            VStack(spacing: 6) {
                Text(group.emoji)
                    .font(.system(size: 28))
                Text(group.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(group.description)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.assignmentType == group.id ? AppColors.primary.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.assignmentType == group.id ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Label("Basic Info", systemImage: "info.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Title")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    TextField("What do you want to achieve?", text: $viewModel.title)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    TextField("Why is this goal important?", text: $viewModel.description, axis: .vertical)
                        .lineLimit(2...4)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(categories, id: \.key) { category in
                            categoryCard(category: category)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private func categoryCard(category: (key: String, emoji: String, label: String)) -> some View {
        Button {
            viewModel.category = category.key
        } label: {
            VStack(spacing: 6) {
                Text(category.emoji)
                    .font(.system(size: 24))
                Text(category.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(viewModel.category == category.key ? AppColors.primary.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(viewModel.category == category.key ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Goal Type Section

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Label("Goal Type", systemImage: "target")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                // Goal Type Cards
                HStack(spacing: 10) {
                    ForEach(goalTypes, id: \.key) { type in
                        goalTypeCard(type: type)
                    }
                }

                // Habit Frequency (shown if habit type)
                if viewModel.goalType == "habit" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How often?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        Picker("Frequency", selection: $viewModel.habitFrequency) {
                            Text("Select frequency...").tag("")
                            ForEach(habitFrequencies, id: \.key) { freq in
                                Text(freq.label).tag(freq.key)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }

                // Milestone Fields (shown if milestone type)
                if viewModel.goalType == "milestone" {
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target number")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)

                            TextField("e.g., 50", text: $viewModel.milestoneTarget)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unit")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)

                            TextField("e.g., dollars, books, days", text: $viewModel.milestoneUnit)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private func goalTypeCard(type: (key: String, emoji: String, label: String, description: String)) -> some View {
        Button {
            viewModel.goalType = type.key
        } label: {
            VStack(spacing: 6) {
                Text(type.emoji)
                    .font(.system(size: 28))
                Text(type.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(type.description)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.goalType == type.key ? AppColors.primary.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.goalType == type.key ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Check-ins & Rewards Section

    private var checkInsRewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Label("Check-ins & Rewards", systemImage: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                // Check-in Frequency
                VStack(alignment: .leading, spacing: 8) {
                    Text("Check-in reminders")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Picker("Check-in", selection: $viewModel.checkInFrequency) {
                        Text("No check-ins").tag("")
                        ForEach(checkInFrequencies, id: \.key) { freq in
                            Text(freq.label).tag(freq.key)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    Text("Get gentle prompts to update progress")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Enable Rewards Toggle
                Toggle(isOn: $viewModel.rewardsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable reward")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Motivate with a special reward when done!")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.primary)
                .onChange(of: viewModel.rewardsEnabled) { _, enabled in
                    if enabled && viewModel.rewardType.isEmpty {
                        viewModel.rewardType = "sticker"
                    }
                }

                // Reward Type Selection (shown if rewards enabled)
                if viewModel.rewardsEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reward type")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(rewardTypes, id: \.key) { reward in
                                rewardTypeCard(reward: reward)
                            }
                        }

                        // Custom Reward Field
                        if viewModel.rewardType == "custom" {
                            TextField("e.g., Ice cream trip!", text: $viewModel.rewardCustom)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private func rewardTypeCard(reward: (key: String, emoji: String, label: String)) -> some View {
        Button {
            viewModel.rewardType = reward.key
        } label: {
            HStack(spacing: 8) {
                Text(reward.emoji)
                    .font(.system(size: 20))
                Text(reward.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(viewModel.rewardType == reward.key ? Color.orange.opacity(0.2) : Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(viewModel.rewardType == reward.key ? Color.orange : Color(.systemGray4), lineWidth: viewModel.rewardType == reward.key ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Kid Settings Section

    private var kidSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Label("Kid Settings", systemImage: "face.smiling")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                Toggle(isOn: $viewModel.visibleToKids) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Visible to kids")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Show this goal in kid-friendly view")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.primary)

                Toggle(isOn: $viewModel.kidsCanUpdate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kids can mark progress")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Allow kids to check in on their own")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.primary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
}

struct CreateTaskView: View {
    let goalId: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GoalsViewModel()

    // Task Categories (from web)
    private let categories: [(key: String, emoji: String, label: String)] = [
        ("home_chores", "🏠", "Home Chores"),
        ("bills", "💵", "Bills & Payments"),
        ("health", "💊", "Health"),
        ("kids", "👶", "Kids"),
        ("car", "🚗", "Car"),
        ("pet_care", "🐾", "Pet Care"),
        ("family_rituals", "👨‍👩‍👧‍👦", "Family Rituals"),
        ("admin", "📋", "Admin")
    ]

    // Priorities (from web)
    private let priorities: [(key: String, label: String, color: String)] = [
        ("low", "Low", "slate"),
        ("medium", "Medium", "blue"),
        ("high", "High", "amber"),
        ("urgent", "Urgent", "red")
    ]

    // Recurrence frequencies
    private let recurrenceFrequencies: [(key: String, label: String)] = [
        ("daily", "Daily"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly"),
        ("yearly", "Yearly")
    ]

    // Reminder timings
    private let reminderTimings: [(key: String, label: String)] = [
        ("at_time", "At due time"),
        ("15_min", "15 minutes before"),
        ("30_min", "30 minutes before"),
        ("1_hour", "1 hour before"),
        ("1_day", "1 day before")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Goal Link Banner (if linked to a goal)
                if let gId = goalId {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.primary)
                        Text("This task will be linked to the selected goal")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                    .padding()
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(10)
                }

                // Basic Info Section
                basicInfoSection

                // Category Section
                categorySection

                // Schedule Section
                scheduleSection

                // Recurring Section
                recurringSection

                // Reminder Section
                reminderSection

                // Error Message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        if await viewModel.createTask() {
                            NotificationCenter.default.post(name: .taskCreated, object: nil)
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.title.isEmpty || viewModel.isLoading)
            }
        }
        .onAppear {
            // Set the goalId if provided
            viewModel.taskGoalId = goalId
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Basic Info", systemImage: "info.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Title")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    TextField("What needs to be done?", text: $viewModel.title)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    TextField("Add details or notes...", text: $viewModel.description, axis: .vertical)
                        .lineLimit(2...4)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                // Priority
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: 8) {
                        ForEach(priorities, id: \.key) { priority in
                            priorityButton(priority: priority)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private func priorityButton(priority: (key: String, label: String, color: String)) -> some View {
        Button {
            viewModel.priority = priority.key
        } label: {
            Text(priority.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(viewModel.priority == priority.key ? .white : priorityColor(priority.color))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(viewModel.priority == priority.key ? priorityColor(priority.color) : priorityColor(priority.color).opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func priorityColor(_ color: String) -> Color {
        switch color {
        case "slate": return Color(.systemGray)
        case "blue": return Color.blue
        case "amber": return Color.orange
        case "red": return Color.red
        default: return Color.blue
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Category", systemImage: "folder.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(categories, id: \.key) { category in
                        categoryCard(category: category)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private func categoryCard(category: (key: String, emoji: String, label: String)) -> some View {
        Button {
            viewModel.taskCategory = category.key
        } label: {
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.system(size: 18))
                Text(category.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(viewModel.taskCategory == category.key ? AppColors.primary.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(viewModel.taskCategory == category.key ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Schedule", systemImage: "calendar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                // Due Date Toggle & Picker
                Toggle(isOn: $viewModel.hasDueDate) {
                    Text("Set due date")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }
                .tint(AppColors.primary)

                if viewModel.hasDueDate {
                    DatePicker("Due Date", selection: $viewModel.dueDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    // Due Time Toggle & Picker
                    Toggle(isOn: $viewModel.hasDueTime) {
                        Text("Set due time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .tint(AppColors.primary)

                    if viewModel.hasDueTime {
                        DatePicker("Due Time", selection: $viewModel.dueTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }

                // Goal Link (if linked to goal, show checkmark)
                if goalId != nil {
                    Toggle(isOn: $viewModel.countTowardGoal) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Count toward goal progress")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Completing this task will update goal progress")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .tint(AppColors.primary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Recurring Section

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recurring", systemImage: "repeat")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                Toggle(isOn: $viewModel.isRecurring) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Repeat this task")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Task will repeat on a schedule")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.primary)

                if viewModel.isRecurring {
                    // Frequency Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How often?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        Picker("Frequency", selection: $viewModel.recurrenceFrequency) {
                            ForEach(recurrenceFrequencies, id: \.key) { freq in
                                Text(freq.label).tag(freq.key)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Interval
                    HStack {
                        Text("Every")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                        Stepper(value: $viewModel.recurrenceInterval, in: 1...30) {
                            Text("\(viewModel.recurrenceInterval)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        Text(frequencyUnit)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private var frequencyUnit: String {
        switch viewModel.recurrenceFrequency {
        case "daily": return viewModel.recurrenceInterval == 1 ? "day" : "days"
        case "weekly": return viewModel.recurrenceInterval == 1 ? "week" : "weeks"
        case "monthly": return viewModel.recurrenceInterval == 1 ? "month" : "months"
        case "yearly": return viewModel.recurrenceInterval == 1 ? "year" : "years"
        default: return "times"
        }
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Reminders", systemImage: "bell.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                Toggle(isOn: $viewModel.sendReminder) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Send reminder")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Get notified before the task is due")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .tint(AppColors.primary)

                if viewModel.sendReminder {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When to remind?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        Picker("Reminder Time", selection: $viewModel.reminderType) {
                            ForEach(reminderTimings, id: \.key) { timing in
                                Text(timing.label).tag(timing.key)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
}

#Preview {
    NavigationStack {
        GoalsListView()
            .environment(AppRouter())
    }
}
