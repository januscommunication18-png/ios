import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    static func noData(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "tray",
            title: "No Data",
            message: "There's nothing here yet. Start by adding some data.",
            actionTitle: action != nil ? "Get Started" : nil,
            action: action
        )
    }

    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "We couldn't find anything matching your search. Try different keywords."
        )
    }

    static func noConnection(retry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Please check your internet connection and try again.",
            actionTitle: "Retry",
            action: retry
        )
    }

    static func noFamilyCircles(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "person.3",
            title: "No Family Circles",
            message: "Create your first family circle to get started.",
            actionTitle: "Create Circle",
            action: action
        )
    }

    static func noExpenses(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "dollarsign.circle",
            title: "No Expenses",
            message: "Start tracking your expenses by adding your first one.",
            actionTitle: "Add Expense",
            action: action
        )
    }

    static func noGoals(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "target",
            title: "No Goals",
            message: "Set your first goal to start tracking progress.",
            actionTitle: "Create Goal",
            action: action
        )
    }

    static func noTasks(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "checklist",
            title: "No Tasks",
            message: "Add tasks to stay organized and productive.",
            actionTitle: "Add Task",
            action: action
        )
    }

    static func noJournalEntries(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "book.closed",
            title: "No Entries",
            message: "Start your journal by writing your first entry.",
            actionTitle: "Write Entry",
            action: action
        )
    }

    static func noShoppingLists(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "cart",
            title: "No Shopping Lists",
            message: "Create a shopping list to keep track of items.",
            actionTitle: "Create List",
            action: action
        )
    }

    static func noPets(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "pawprint",
            title: "No Pets",
            message: "Add your furry friends to track their health and care.",
            actionTitle: "Add Pet",
            action: action
        )
    }

    static func noPeople(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "person.crop.circle",
            title: "No Contacts",
            message: "Add people to your directory for easy access.",
            actionTitle: "Add Contact",
            action: action
        )
    }

    static func noReminders(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "bell",
            title: "No Reminders",
            message: "Set reminders to never miss important events.",
            actionTitle: "Add Reminder",
            action: action
        )
    }
}

#Preview {
    VStack {
        EmptyStateView.noData {
            print("Get started")
        }
    }
}
