import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .dashboard

    // Separate routers for each tab to manage navigation state
    @State private var dashboardRouter = AppRouter()
    @State private var familyRouter = AppRouter()
    @State private var assetsRouter = AppRouter()

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case family = "Family"
        case assets = "Assets"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .family: return "person.3.fill"
            case .assets: return "dollarsign.circle.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var selectedIcon: String {
            icon
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environment(dashboardRouter)
                .tabItem {
                    Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            FamilyListView()
                .environment(familyRouter)
                .tabItem {
                    Label(Tab.family.rawValue, systemImage: Tab.family.icon)
                }
                .tag(Tab.family)

            AssetsListView()
                .environment(assetsRouter)
                .tabItem {
                    Label(Tab.assets.rawValue, systemImage: Tab.assets.icon)
                }
                .tag(Tab.assets)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(AppColors.primary)
        .onChange(of: selectedTab) { oldTab, newTab in
            // Reset navigation stack when switching to a tab
            switch newTab {
            case .dashboard:
                dashboardRouter.goToRoot()
            case .family:
                familyRouter.goToRoot()
            case .assets:
                assetsRouter.goToRoot()
            case .settings:
                break // Settings doesn't have navigation stack
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
