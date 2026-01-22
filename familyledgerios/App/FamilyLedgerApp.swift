import SwiftUI

@main
struct FamilyLedgerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else if !appState.isSecurityCodeVerified {
                // Security Code Gate - First screen
                SecurityCodeView()
            } else if appState.isAuthenticated {
                if appState.showOnboarding {
                    OnboardingContainerView()
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .task {
            await appState.initialize()
        }
        .animation(.easeInOut, value: appState.isSecurityCodeVerified)
        .animation(.easeInOut, value: appState.isAuthenticated)
        .animation(.easeInOut, value: appState.showOnboarding)
        .animation(.easeInOut, value: appState.isLoading)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("Family Ledger")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
