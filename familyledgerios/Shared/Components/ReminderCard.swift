import SwiftUI

// MARK: - Reminder Card (Matches web design exactly)

struct ReminderCard: View {
    let title: String
    let icon: String
    let count: Int
    let accentColor: Color
    let reminders: [Reminder]
    var onComplete: ((Int) -> Void)? = nil
    var onTap: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)

                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(accentColor)

                Spacer()

                // Count Badge
                Text("\(count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.15))
                    .cornerRadius(10)
            }

            // Reminder Rows
            ForEach(reminders) { reminder in
                ReminderCardRow(
                    reminder: reminder,
                    accentColor: accentColor,
                    onComplete: { onComplete?(reminder.id) },
                    onTap: { onTap?(reminder.id) }
                )
            }
        }
        .padding(16)
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .fill(accentColor)
                .frame(width: 4),
            alignment: .leading
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Reminder Card Row

struct ReminderCardRow: View {
    let reminder: Reminder
    let accentColor: Color
    var onComplete: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Category Icon Circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)
                }

                // Content
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
                ReminderPriorityBadge(priority: reminder.priority ?? "medium")

                // Complete Button
                if let complete = onComplete {
                    Button(action: complete) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(accentColor.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var categoryIcon: String {
        if let icon = reminder.categoryIcon {
            return icon
        }
        switch reminder.category?.lowercased() {
        case "home_chores": return "house.fill"
        case "bills": return "banknote.fill"
        case "health": return "heart.fill"
        case "kids": return "figure.2.and.child.holdinghands"
        case "car": return "car.fill"
        case "pet_care": return "pawprint.fill"
        case "family_rituals": return "person.3.fill"
        case "appointments": return "calendar"
        case "groceries": return "cart.fill"
        case "school": return "graduationcap.fill"
        default: return "bell.fill"
        }
    }
}

// MARK: - Priority Badge

struct ReminderPriorityBadge: View {
    let priority: String

    var body: some View {
        Text(priority.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(priorityColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.15))
            .cornerRadius(6)
    }

    private var priorityColor: Color {
        switch priority.lowercased() {
        case "high": return .red
        case "low": return AppColors.info
        default: return .orange
        }
    }
}

// MARK: - Dashboard Reminders Widget

struct DashboardRemindersWidget: View {
    let overdue: [Reminder]
    let today: [Reminder]
    let upcoming: [Reminder]
    var onViewAll: (() -> Void)? = nil
    var onComplete: ((Int) -> Void)? = nil
    var onTap: ((Int) -> Void)? = nil

    private var hasReminders: Bool {
        !overdue.isEmpty || !today.isEmpty || !upcoming.isEmpty
    }

    private var displayReminders: [(Reminder, Color, String)] {
        var items: [(Reminder, Color, String)] = []

        // Add overdue (max 2)
        for reminder in overdue.prefix(2) {
            items.append((reminder, .red, "Overdue"))
        }

        // Add today (max 2)
        for reminder in today.prefix(2) {
            items.append((reminder, .orange, "Today"))
        }

        // Add upcoming (max 1)
        if let reminder = upcoming.first {
            items.append((reminder, .blue, "Upcoming"))
        }

        return Array(items.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.reminders)

                    Text("Reminders")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                if hasReminders, let viewAll = onViewAll {
                    Button(action: viewAll) {
                        Text("View All")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }

            if hasReminders {
                // Stats Row
                HStack(spacing: 12) {
                    if !overdue.isEmpty {
                        ReminderMiniStat(count: overdue.count, label: "Overdue", color: .red)
                    }
                    if !today.isEmpty {
                        ReminderMiniStat(count: today.count, label: "Today", color: .orange)
                    }
                    if !upcoming.isEmpty {
                        ReminderMiniStat(count: upcoming.count, label: "Upcoming", color: .blue)
                    }
                }

                // Reminder Items
                VStack(spacing: 8) {
                    ForEach(displayReminders, id: \.0.id) { reminder, color, status in
                        DashboardReminderRow(
                            reminder: reminder,
                            statusColor: color,
                            statusText: status,
                            onComplete: { onComplete?(reminder.id) },
                            onTap: { onTap?(reminder.id) }
                        )
                    }
                }
            } else {
                // Empty State
                VStack(spacing: 8) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.textTertiary)

                    Text("No upcoming reminders")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Mini Stat

struct ReminderMiniStat: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Dashboard Reminder Row

struct DashboardReminderRow: View {
    let reminder: Reminder
    let statusColor: Color
    let statusText: String
    var onComplete: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 10) {
                // Status Indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(AppTypography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(statusText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(statusColor)

                        if let time = reminder.dueTimeFormatted {
                            Text("at \(time)")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Priority
                ReminderPriorityBadge(priority: reminder.priority ?? "medium")

                // Complete Button
                if let complete = onComplete {
                    Button(action: complete) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(statusColor.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Birthday Reminder Card

struct BirthdayReminderCard: View {
    let birthdays: [BirthdayReminder]
    var onTap: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.pink)

                Text("Upcoming Birthdays")
                    .font(AppTypography.headline)
                    .foregroundColor(.pink)

                Spacer()

                Text("\(birthdays.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.pink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.15))
                    .cornerRadius(10)
            }

            // Birthday Rows
            ForEach(birthdays) { birthday in
                BirthdayCardRow(birthday: birthday, onTap: { onTap?(birthday.personId) })
            }
        }
        .padding(16)
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .fill(Color.pink)
                .frame(width: 4),
            alignment: .leading
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Birthday Card Row

struct BirthdayCardRow: View {
    let birthday: BirthdayReminder
    var onTap: (() -> Void)? = nil

    private var backgroundColor: Color {
        if birthday.daysUntil == 0 {
            return Color.pink.opacity(0.15)
        } else if birthday.daysUntil == 1 {
            return Color.pink.opacity(0.08)
        }
        return Color(.systemGray6)
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Avatar
                if let url = birthday.personImageUrl, !url.isEmpty, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { phase in
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

                        if let age = birthday.turningAge {
                            Text("•")
                                .foregroundColor(AppColors.textTertiary)

                            Text("Turning \(age)")
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Relationship Badge
                if let relationship = birthday.relationship {
                    Text(relationship)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.pink.opacity(0.2))

            Text(birthday.personInitials ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pink)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Important Date Reminder Card

struct ImportantDateReminderCard: View {
    let dateReminders: [ImportantDateReminder]
    var onTap: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.8))

                Text("Important Dates")
                    .font(AppTypography.headline)
                    .foregroundColor(.red.opacity(0.8))

                Spacer()

                Text("\(dateReminders.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(10)
            }

            // Date Rows
            ForEach(dateReminders) { dateReminder in
                ImportantDateCardRow(dateReminder: dateReminder, onTap: { onTap?(dateReminder.personId) })
            }
        }
        .padding(16)
        .background(AppColors.background)
        .overlay(
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 4),
            alignment: .leading
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Important Date Card Row

struct ImportantDateCardRow: View {
    let dateReminder: ImportantDateReminder
    var onTap: (() -> Void)? = nil

    private var backgroundColor: Color {
        if dateReminder.daysUntil == 0 {
            return Color.red.opacity(0.1)
        } else if dateReminder.daysUntil == 1 {
            return Color.red.opacity(0.05)
        }
        return Color(.systemGray6)
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Avatar
                if let url = dateReminder.personImageUrl, !url.isEmpty, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { phase in
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

                // Recurring Badge
                if dateReminder.isRecurring == true {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.system(size: 10))
                        Text("Yearly")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.15))

            Text(dateReminder.personInitials ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.red.opacity(0.8))
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Completed Reminder Card

struct CompletedReminderCard: View {
    let reminders: [Reminder]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (Tappable)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)

                    Text("Completed")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Text("\(reminders.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(10)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Content (Collapsible)
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(reminders.prefix(10)) { reminder in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
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
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            DashboardRemindersWidget(
                overdue: [
                    Reminder(id: 1, title: "Pay electricity bill", description: nil, dueDate: nil, dueDateFormatted: nil, dueDateDay: nil, dueText: "Overdue by 2 days", dueTime: nil, dueTimeFormatted: "10:00 AM", priority: "high", status: nil, isRecurring: nil, recurrencePattern: nil, category: "bills", categoryIcon: nil, assignedTo: nil, completedAt: nil, createdAt: nil, updatedAt: nil)
                ],
                today: [
                    Reminder(id: 2, title: "Doctor appointment", description: nil, dueDate: nil, dueDateFormatted: nil, dueDateDay: nil, dueText: "Due today", dueTime: nil, dueTimeFormatted: "2:30 PM", priority: "medium", status: nil, isRecurring: nil, recurrencePattern: nil, category: "health", categoryIcon: nil, assignedTo: nil, completedAt: nil, createdAt: nil, updatedAt: nil)
                ],
                upcoming: []
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
