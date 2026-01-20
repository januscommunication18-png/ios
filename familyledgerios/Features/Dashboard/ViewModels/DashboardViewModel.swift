import Foundation

@Observable
final class DashboardViewModel {
    var stats: DashboardStats?
    var quickActions: [QuickAction] = []

    // Reminders data
    var overdueReminders: [Reminder] = []
    var todayReminders: [Reminder] = []
    var upcomingReminders: [Reminder] = []

    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?

    // MARK: - Computed Properties

    var hasData: Bool {
        stats != nil
    }

    var hasReminders: Bool {
        !overdueReminders.isEmpty || !todayReminders.isEmpty || !upcomingReminders.isEmpty
    }

    // MARK: - API Methods

    @MainActor
    func loadDashboard() async {
        isLoading = stats == nil
        errorMessage = nil

        do {
            let response: DashboardOverview = try await APIClient.shared.request(.dashboard)
            stats = response.stats
            quickActions = response.quickActions ?? []
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("Dashboard API Error: \(error)")
        } catch {
            errorMessage = "Failed to load dashboard"
            print("Dashboard Error: \(error)")
        }

        // Load reminders in parallel
        await loadReminders()

        isLoading = false
    }

    @MainActor
    func loadReminders() async {
        do {
            let response: RemindersResponse = try await APIClient.shared.request(.reminders)
            overdueReminders = response.overdue ?? []
            todayReminders = response.today ?? []
            upcomingReminders = (response.tomorrow ?? []) + (response.thisWeek ?? [])
        } catch {
            // Silently fail on reminders
            print("Reminders load error: \(error)")
        }
    }

    @MainActor
    func completeReminder(id: Int) async {
        do {
            let _: Reminder = try await APIClient.shared.request(.completeReminder(id: id))
            await loadReminders()
        } catch {
            print("Complete reminder error: \(error)")
        }
    }

    @MainActor
    func refresh() async {
        isRefreshing = true

        do {
            let response: DashboardOverview = try await APIClient.shared.request(.dashboard)
            stats = response.stats
            quickActions = response.quickActions ?? []
        } catch {
            // Silently fail on refresh
            print("Dashboard refresh error: \(error)")
        }

        await loadReminders()

        isRefreshing = false
    }
}
