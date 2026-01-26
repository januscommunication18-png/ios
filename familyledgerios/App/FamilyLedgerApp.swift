import SwiftUI
import SwiftData

@main
struct FamilyLedgerApp: App {
    @State private var appState = AppState()

    init() {
        // Start network monitoring for offline mode
        NetworkMonitor.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light) // Force light mode
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    // App onboarding flow state
    @State private var showOnboardingCarousel = false
    @State private var showSignUpSheet = false
    @State private var showLoginFromLanding = false

    var body: some View {
        let _ = print("DEBUG RootView: isLoading=\(appState.isLoading), isAuthenticated=\(appState.isAuthenticated), hasCompletedAppOnboarding=\(appState.hasCompletedAppOnboarding), showOnboarding=\(appState.showOnboarding)")
        Group {
            if appState.isLoading {
                SplashView()
            // Security code page disabled for now
            // } else if !appState.isSecurityCodeVerified {
            //     SecurityCodeView()
            } else if !appState.hasCompletedAppOnboarding && !appState.isAuthenticated {
                // App Landing / Onboarding flow for first-time users
                AppLandingView(
                    showOnboarding: $showOnboardingCarousel,
                    showLogin: $showLoginFromLanding
                )
                .fullScreenCover(isPresented: $showOnboardingCarousel) {
                    OnboardingCarouselView(showSignUp: $showSignUpSheet, onSignInTapped: {
                        // Close carousel and show login
                        showOnboardingCarousel = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showLoginFromLanding = true
                        }
                    })
                        .sheet(isPresented: $showSignUpSheet) {
                            SignUpSheetView(onSignInTapped: {
                                // Close sheet and carousel, then show login
                                showSignUpSheet = false
                                showOnboardingCarousel = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showLoginFromLanding = true
                                }
                            })
                                .environment(appState)
                                .onDisappear {
                                    // If user signed up successfully, mark onboarding complete
                                    if appState.isAuthenticated {
                                        appState.completeAppOnboarding()
                                    }
                                }
                        }
                }
                .fullScreenCover(isPresented: $showLoginFromLanding) {
                    LoginViewWrapper()
                        .environment(appState)
                        .onDisappear {
                            // If user logged in successfully, mark onboarding complete
                            if appState.isAuthenticated {
                                appState.completeAppOnboarding()
                            }
                        }
                }
            } else if appState.isAuthenticated {
                if appState.showOnboarding {
                    OnboardingContainerView()
                } else {
                    MainTabView()
                    #if DEBUG
                        .offlineDebugOverlay()
                    #endif
                }
            } else {
                LoginView()
            }
        }
        .task {
            await appState.initialize()
        }
        // .animation(.easeInOut, value: appState.isSecurityCodeVerified)
        .animation(.easeInOut, value: appState.hasCompletedAppOnboarding)
        .animation(.easeInOut, value: appState.isAuthenticated)
        .animation(.easeInOut, value: appState.showOnboarding)
        .animation(.easeInOut, value: appState.isLoading)
    }
}

// Wrapper to add close button to LoginView when presented from landing
struct LoginViewWrapper: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LoginView()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4)
            }
            .padding(.top, 16)
            .padding(.trailing, 24)
        }
        .onChange(of: appState.isAuthenticated) { _, isAuth in
            if isAuth {
                dismiss()
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            AppColors.primary
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("Meet Olliee")
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
