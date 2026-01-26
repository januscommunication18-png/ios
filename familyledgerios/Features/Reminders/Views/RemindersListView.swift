import SwiftUI

@Observable
final class RemindersViewModel {
    var reminders: [Reminder] = []
    var overdue: [Reminder] = []
    var today: [Reminder] = []
    var tomorrow: [Reminder] = []
    var thisWeek: [Reminder] = []
    var upcoming: [Reminder] = []
    var completed: [Reminder] = []
    var birthdayReminders: [BirthdayReminder] = []
    var importantDateReminders: [ImportantDateReminder] = []
    var stats: ReminderStats?
    var selectedReminder: Reminder?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadReminders() async {
        isLoading = reminders.isEmpty
        do {
            let response: RemindersResponse = try await APIClient.shared.request(.reminders)
            reminders = response.reminders ?? []
            overdue = response.overdue ?? []
            today = response.today ?? []
            tomorrow = response.tomorrow ?? []
            thisWeek = response.thisWeek ?? []
            upcoming = response.upcoming ?? []
            completed = response.completed ?? []
            birthdayReminders = response.birthdayReminders ?? []
            importantDateReminders = response.importantDateReminders ?? []
            stats = response.stats
        }
        catch { errorMessage = "Failed to load reminders" }
        isLoading = false
    }

    @MainActor
    func loadReminder(id: Int) async {
        isLoading = selectedReminder == nil
        errorMessage = nil
        do {
            let response: ReminderDetailResponse = try await APIClient.shared.request(.reminder(id: id))
            selectedReminder = response.reminder
            if selectedReminder == nil {
                errorMessage = "Reminder not found"
            }
        } catch {
            errorMessage = "Failed to load reminder"
            print("DEBUG: Load reminder error: \(error)")
        }
        isLoading = false
    }

    @MainActor
    func completeReminder(id: Int) async {
        do {
            let _: Reminder = try await APIClient.shared.request(.completeReminder(id: id))
            await loadReminders()
        } catch { }
    }
}

struct RemindersListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = RemindersViewModel()
    @State private var showCompleted = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading reminders...")
            } else if isEmpty {
                EmptyStateView.noReminders { router.navigate(to: .createReminder) }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Stats Cards
                        statsCards

                        // Birthday Reminders
                        if !viewModel.birthdayReminders.isEmpty {
                            birthdayRemindersSection
                        }

                        // Important Date Reminders
                        if !viewModel.importantDateReminders.isEmpty {
                            importantDatesSection
                        }

                        // Overdue
                        if !viewModel.overdue.isEmpty {
                            overdueSection
                        }

                        // Today
                        if !viewModel.today.isEmpty {
                            todaySection
                        }

                        // Tomorrow
                        if !viewModel.tomorrow.isEmpty {
                            tomorrowSection
                        }

                        // This Week
                        if !viewModel.thisWeek.isEmpty {
                            thisWeekSection
                        }

                        // Upcoming
                        if !viewModel.upcoming.isEmpty {
                            upcomingSection
                        }

                        // Completed (collapsible)
                        if !viewModel.completed.isEmpty {
                            completedSection
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.navigate(to: .createReminder) } label: { Image(systemName: "plus") }
            }
        }
        .task { await viewModel.loadReminders() }
        .refreshable { await viewModel.loadReminders() }
    }

    private var isEmpty: Bool {
        viewModel.overdue.isEmpty &&
        viewModel.today.isEmpty &&
        viewModel.tomorrow.isEmpty &&
        viewModel.thisWeek.isEmpty &&
        viewModel.upcoming.isEmpty &&
        viewModel.completed.isEmpty &&
        viewModel.birthdayReminders.isEmpty &&
        viewModel.importantDateReminders.isEmpty
    }

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 12) {
            ReminderStatCard(value: viewModel.stats?.total ?? 0, label: "Active", color: .primary)
            ReminderStatCard(value: viewModel.stats?.overdue ?? 0, label: "Overdue", color: .red)
            ReminderStatCard(value: viewModel.stats?.today ?? 0, label: "Today", color: .orange)
            ReminderStatCard(value: viewModel.stats?.completed ?? 0, label: "Done", color: .green)
        }
    }

    // MARK: - Birthday Reminders

    private var birthdayRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "birthday.cake.fill")
                    .foregroundColor(.pink)
                Text("Upcoming Birthdays")
                    .font(AppTypography.headline)
                    .foregroundColor(.pink)
                Spacer()
                Text("\(viewModel.birthdayReminders.count)")
                    .font(AppTypography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.2))
                    .foregroundColor(.pink)
                    .cornerRadius(10)
            }

            ForEach(viewModel.birthdayReminders) { birthday in
                BirthdayReminderRow(birthday: birthday, onTap: {
                    router.navigate(to: .person(id: birthday.personId))
                })
            }
        }
        .padding()
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .fill(Color.pink)
                .frame(width: 4),
            alignment: .leading
        )
        .cornerRadius(16)
    }

    // MARK: - Important Dates

    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundColor(.red.opacity(0.8))
                Text("Important Dates")
                    .font(AppTypography.headline)
                    .foregroundColor(.red.opacity(0.8))
                Spacer()
                Text("\(viewModel.importantDateReminders.count)")
                    .font(AppTypography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red.opacity(0.8))
                    .cornerRadius(10)
            }

            ForEach(viewModel.importantDateReminders) { dateReminder in
                ImportantDateReminderRow(dateReminder: dateReminder, onTap: {
                    router.navigate(to: .person(id: dateReminder.personId))
                })
            }
        }
        .padding()
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 4),
            alignment: .leading
        )
        .cornerRadius(16)
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        ReminderSection(
            title: "Overdue",
            icon: "exclamationmark.circle.fill",
            count: viewModel.overdue.count,
            color: .red,
            reminders: viewModel.overdue,
            onComplete: { id in Task { await viewModel.completeReminder(id: id) } },
            onTap: { id in router.navigate(to: .reminder(id: id)) }
        )
    }

    // MARK: - Today Section

    private var todaySection: some View {
        ReminderSection(
            title: "Today",
            icon: "calendar.badge.exclamationmark",
            count: viewModel.today.count,
            color: .orange,
            reminders: viewModel.today,
            onComplete: { id in Task { await viewModel.completeReminder(id: id) } },
            onTap: { id in router.navigate(to: .reminder(id: id)) }
        )
    }

    // MARK: - Tomorrow Section

    private var tomorrowSection: some View {
        ReminderSection(
            title: "Tomorrow",
            icon: "calendar.badge.plus",
            count: viewModel.tomorrow.count,
            color: .blue,
            reminders: viewModel.tomorrow,
            onComplete: { id in Task { await viewModel.completeReminder(id: id) } },
            onTap: { id in router.navigate(to: .reminder(id: id)) }
        )
    }

    // MARK: - This Week Section

    private var thisWeekSection: some View {
        ReminderSection(
            title: "This Week",
            icon: "calendar",
            count: viewModel.thisWeek.count,
            color: .purple,
            reminders: viewModel.thisWeek,
            onComplete: { id in Task { await viewModel.completeReminder(id: id) } },
            onTap: { id in router.navigate(to: .reminder(id: id)) }
        )
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        ReminderSection(
            title: "Upcoming",
            icon: "calendar.badge.clock",
            count: viewModel.upcoming.count,
            color: .gray,
            reminders: viewModel.upcoming,
            onComplete: { id in Task { await viewModel.completeReminder(id: id) } },
            onTap: { id in router.navigate(to: .reminder(id: id)) }
        )
    }

    // MARK: - Completed Section

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showCompleted.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(AppTypography.headline)
                    Spacer()
                    Text("\(viewModel.completed.count)")
                        .font(AppTypography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if showCompleted {
                ForEach(viewModel.completed) { reminder in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.title)
                                .font(AppTypography.bodySmall)
                                .strikethrough()
                                .foregroundColor(AppColors.textSecondary)
                            if let completedAt = reminder.completedAt {
                                Text("Completed \(completedAt)")
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(10)
                    .opacity(0.6)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }
}

// MARK: - Reminder Stat Card

struct ReminderStatCard: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(AppTypography.captionSmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Birthday Reminder Row

struct BirthdayReminderRow: View {
    let birthday: BirthdayReminder
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                if let url = birthday.personImageUrl, !url.isEmpty {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(birthday.personName)
                        .font(AppTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: 4) {
                        Text(birthday.daysUntilText ?? "")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(birthday.daysUntil == 0 ? .pink : AppColors.textSecondary)
                            .fontWeight(birthday.daysUntil <= 1 ? .semibold : .regular)

                        Text("•")
                            .foregroundColor(AppColors.textTertiary)

                        Text(birthday.birthdayDate ?? "")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)

                        Text("•")
                            .foregroundColor(AppColors.textTertiary)

                        Text("Turning \(birthday.turningAge ?? 0)")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                Spacer()

                // Relationship badge
                if let relationship = birthday.relationship {
                    Text(relationship)
                        .font(.system(size: 10))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink.opacity(0.15))
                        .foregroundColor(.pink)
                        .cornerRadius(8)
                }
            }
            .padding(12)
            .background(birthday.daysUntil == 0 ? Color.pink.opacity(0.15) : birthday.daysUntil == 1 ? Color.pink.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle().fill(Color.pink.opacity(0.2))
            Text(birthday.personInitials ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pink)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Important Date Reminder Row

struct ImportantDateReminderRow: View {
    let dateReminder: ImportantDateReminder
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                if let url = dateReminder.personImageUrl, !url.isEmpty {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateReminder.label ?? "Important Date")
                        .font(AppTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: 4) {
                        Text(dateReminder.personName)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)

                        Text("•")
                            .foregroundColor(AppColors.textTertiary)

                        Text(dateReminder.daysUntilText ?? "")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(dateReminder.daysUntil == 0 ? .red.opacity(0.8) : AppColors.textSecondary)
                            .fontWeight(dateReminder.daysUntil <= 1 ? .semibold : .regular)

                        Text("•")
                            .foregroundColor(AppColors.textTertiary)

                        Text(dateReminder.nextDate ?? "")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                Spacer()

                // Recurring badge
                if dateReminder.isRecurring == true {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.system(size: 10))
                        Text("Yearly")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
            .padding(12)
            .background(dateReminder.daysUntil == 0 ? Color.red.opacity(0.1) : dateReminder.daysUntil == 1 ? Color.red.opacity(0.05) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle().fill(Color.red.opacity(0.15))
            Text(dateReminder.personInitials ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.red.opacity(0.8))
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Reminder Section

struct ReminderSection: View {
    let title: String
    let icon: String
    let count: Int
    let color: Color
    let reminders: [Reminder]
    let onComplete: (Int) -> Void
    let onTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(AppTypography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .cornerRadius(10)
            }

            ForEach(reminders) { reminder in
                ReminderRow(
                    reminder: reminder,
                    accentColor: color,
                    onComplete: { onComplete(reminder.id) },
                    onTap: { onTap(reminder.id) }
                )
            }
        }
        .padding()
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .fill(color)
                .frame(width: 4),
            alignment: .leading
        )
        .cornerRadius(16)
    }
}

// MARK: - Reminder Row

struct ReminderRow: View {
    let reminder: Reminder
    let accentColor: Color
    let onComplete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: reminder.categoryIcon ?? "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(AppTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(reminder.dueText ?? "")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(accentColor)
                            .fontWeight(.medium)

                        if let time = reminder.dueTimeFormatted {
                            Text("at \(time)")
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Priority Badge
                Badge(text: (reminder.priority ?? "medium").capitalized, color: priorityColor(reminder.priority))

                // Complete Button
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(accentColor.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func priorityColor(_ priority: String?) -> Color {
        switch priority?.lowercased() {
        case "high": return .red
        case "low": return .gray
        default: return .orange
        }
    }
}

// MARK: - Detail View

struct ReminderDetailView: View {
    let reminderId: Int
    @State private var viewModel = RemindersViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading reminder...")
            } else if let reminder = viewModel.selectedReminder {
                reminderContent(reminder: reminder)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadReminder(id: reminderId)
                    }
                }
            } else {
                // Default state - still loading or initial state
                VStack {
                    ProgressView()
                    Text("Loading reminder...")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadReminder(id: reminderId) }
    }

    private func reminderContent(reminder: Reminder) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(categoryColor(reminder.category).opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: reminder.categoryIcon ?? "bell.fill")
                            .font(.system(size: 32))
                            .foregroundColor(categoryColor(reminder.category))
                    }

                    Text(reminder.title)
                        .font(AppTypography.displaySmall)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Badge(text: statusDisplayName(reminder.status), color: statusColor(reminder.status))
                        Badge(text: (reminder.priority ?? "medium").capitalized, color: priorityColor(reminder.priority))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.background)
                .cornerRadius(16)

                // Due Date Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 40, height: 40)
                            Image(systemName: "calendar")
                                .foregroundColor(.white)
                        }
                        Text("Due Date")
                            .font(AppTypography.headline)
                    }

                    HStack {
                        Text(reminder.dueText ?? "Not set")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                        Spacer()
                        if let formatted = reminder.dueDateFormatted {
                            Text(formatted)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    if let time = reminder.dueTimeFormatted {
                        HStack {
                            Text("Time")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text(time)
                                .font(AppTypography.bodySmall)
                                .fontWeight(.medium)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Description Card
                if let desc = reminder.description, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.white)
                            }
                            Text("Description")
                                .font(AppTypography.headline)
                        }

                        Text(desc)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Category Card
                if let category = reminder.category, !category.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [categoryColor(category), categoryColor(category).opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                Image(systemName: reminder.categoryIcon ?? "tag.fill")
                                    .foregroundColor(.white)
                            }
                            Text("Category")
                                .font(AppTypography.headline)
                        }

                        Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Recurring Info Card
                if reminder.isRecurring == true, let pattern = reminder.recurrencePattern {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "repeat")
                                    .foregroundColor(.white)
                            }
                            Text("Recurring")
                                .font(AppTypography.headline)
                        }

                        Text(pattern.capitalized)
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.medium)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func statusDisplayName(_ status: String?) -> String {
        (status ?? "pending").replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "completed": return .green
        case "overdue": return .red
        default: return .orange
        }
    }

    private func priorityColor(_ priority: String?) -> Color {
        switch priority?.lowercased() {
        case "high": return .red
        case "low": return .gray
        default: return .orange
        }
    }

    private func categoryColor(_ category: String?) -> Color {
        switch category?.lowercased() {
        case "bills": return .green
        case "health": return .red
        case "kids", "school": return .blue
        case "car": return .orange
        case "pet_care": return .brown
        case "groceries": return .purple
        default: return .indigo
        }
    }
}

struct CreateReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var priority: String = "medium"

    private let priorities = ["low", "medium", "high"]

    var body: some View {
        Form {
            TextField("Title", text: $title)
            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
            Picker("Priority", selection: $priority) {
                ForEach(priorities, id: \.self) { priority in
                    Text(priority.capitalized).tag(priority)
                }
            }
        }
        .navigationTitle("New Reminder")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Add") { dismiss() }.disabled(title.isEmpty) }
        }
    }
}
