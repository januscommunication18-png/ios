import SwiftUI

struct GoalsListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = GoalsViewModel()
    @State private var selectedTab = 0

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
                    Button { router.navigate(to: .createGoal) } label: {
                        Label("New Goal", systemImage: "target")
                    }
                    Button { router.navigate(to: .createTask) } label: {
                        Label("New Task", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable { await viewModel.refreshGoals() }
        .task { await viewModel.loadGoals() }
    }

    private var goalsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
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
        VStack(spacing: 12) {
            if viewModel.tasks.isEmpty {
                EmptyStateView.noTasks { router.navigate(to: .createTask) }
            } else {
                ForEach(viewModel.tasks) { task in
                    TaskCard(task: task) { router.navigate(to: .task(id: task.id)) }
                }
            }
        }
        .padding(.horizontal)
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.status == "completed" ? AppColors.success : AppColors.textTertiary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .strikethrough(task.status == "completed")

                    if let date = task.dueDate {
                        Text("Due: \(date)")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                Badge(text: priorityDisplayName(task.priority), color: priorityColor(task.priority))
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
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

struct GoalDetailView: View {
    let goalId: Int
    @State private var viewModel = GoalsViewModel()

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
                // Fallback while waiting for task to run
                LoadingView(message: "Loading goal...")
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadGoal(id: goalId) }
    }

    private func goalContent(goal: Goal) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 16) {
                    // Icon and Title
                    HStack(alignment: .top, spacing: 16) {
                        // Category Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.goals.opacity(0.15))
                                .frame(width: 64, height: 64)

                            Text("🎯")
                                .font(.system(size: 32))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(goal.title)
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                Badge(text: statusDisplayName(goal.status), color: statusColor(goal.status))
                            }

                            if let description = goal.description, !description.isEmpty {
                                Text(description)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                            }

                            // Meta Info
                            HStack(spacing: 12) {
                                if let priority = goal.priority {
                                    Label(priority.capitalized, systemImage: "flag.fill")
                                        .font(AppTypography.captionSmall)
                                        .foregroundColor(priorityColor(priority))
                                }

                                if let targetDate = goal.targetDate {
                                    Label(formatDate(targetDate), systemImage: "calendar")
                                        .font(AppTypography.captionSmall)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Progress Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(goal.progress ?? 0)%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.goals)
                    }

                    ProgressView(value: Double(goal.progress ?? 0) / 100)
                        .tint(AppColors.goals)
                        .scaleEffect(y: 2)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
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
                        if let category = goal.category {
                            DetailRow(label: "Category", value: category.capitalized)
                            Divider()
                        }
                        DetailRow(label: "Status", value: statusDisplayName(goal.status))
                        Divider()
                        if let priority = goal.priority {
                            DetailRow(label: "Priority", value: priority.capitalized)
                            Divider()
                        }
                        if let targetDate = goal.targetDate {
                            DetailRow(label: "Target Date", value: formatDate(targetDate))
                            Divider()
                        }
                        if let createdAt = goal.createdAt {
                            DetailRow(label: "Created", value: createdAt)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

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

    private func priorityColor(_ priority: String?) -> Color {
        switch priority?.lowercased() {
        case "high": return AppColors.error
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
}

struct TaskDetailView: View {
    let taskId: Int
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
                // Fallback while waiting for task to run
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
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        // Status Icon
                        Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 40))
                            .foregroundColor(task.status == "completed" ? AppColors.success : AppColors.textTertiary)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(task.title)
                                    .font(AppTypography.headline)
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
                            HStack(spacing: 12) {
                                if let priority = task.priority {
                                    Label(priority.capitalized, systemImage: "flag.fill")
                                        .font(AppTypography.captionSmall)
                                        .foregroundColor(priorityColor(priority))
                                }

                                if task.isRecurring == true {
                                    Label("Recurring", systemImage: "repeat")
                                        .font(AppTypography.captionSmall)
                                        .foregroundColor(AppColors.info)
                                }
                            }
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

    private let priorities = ["low", "medium", "high"]

    var body: some View {
        Form {
            TextField("Title", text: $viewModel.title)
            TextEditor(text: $viewModel.description).frame(minHeight: 100)
            DatePicker("Target Date", selection: $viewModel.targetDate, displayedComponents: .date)
            Picker("Priority", selection: $viewModel.priority) {
                ForEach(priorities, id: \.self) { priority in
                    Text(priority.capitalized).tag(priority)
                }
            }
        }
        .navigationTitle("New Goal")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { if await viewModel.createGoal() { dismiss() } }
                }
                .disabled(viewModel.title.isEmpty)
            }
        }
    }
}

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GoalsViewModel()

    private let priorities = ["low", "medium", "high"]

    var body: some View {
        Form {
            TextField("Title", text: $viewModel.title)
            TextEditor(text: $viewModel.description).frame(minHeight: 100)
            DatePicker("Due Date", selection: $viewModel.dueDate, displayedComponents: .date)
            Picker("Priority", selection: $viewModel.priority) {
                ForEach(priorities, id: \.self) { priority in
                    Text(priority.capitalized).tag(priority)
                }
            }
        }
        .navigationTitle("New Task")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { if await viewModel.createTask() { dismiss() } }
                }
                .disabled(viewModel.title.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GoalsListView()
            .environment(AppRouter())
    }
}
