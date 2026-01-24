import Foundation
import SwiftUI

@Observable
final class AppState {
    // MARK: - Security Code State
    var isSecurityCodeVerified: Bool = false
    private let validSecurityCodes = ["1000", "2000", "3000", "4000"]
    private let securityCodeKey = "security_code_verified"

    // MARK: - First Launch / App Onboarding State
    var hasCompletedAppOnboarding: Bool = false
    private let appOnboardingKey = "has_completed_app_onboarding"

    // MARK: - Auth State
    var user: User?
    var tenant: Tenant?
    var token: String?
    var isAuthenticated: Bool = false
    var isLoading: Bool = true
    var isInitialized: Bool = false

    // MARK: - Navigation State
    var showOnboarding: Bool = false

    // MARK: - Error State
    var errorMessage: String?

    // MARK: - Computed Properties

    var isOnboardingComplete: Bool {
        tenant?.onboardingCompleted ?? true
    }

    var currentOnboardingStep: Int {
        tenant?.onboardingStep ?? 1
    }

    // MARK: - Initialization

    init() {
        setupAPIClientCallback()
        loadSecurityCodeStatus()
    }

    private func setupAPIClientCallback() {
        APIClient.shared.onUnauthorized = { [weak self] in
            self?.logout()
        }
    }

    private func loadSecurityCodeStatus() {
        isSecurityCodeVerified = UserDefaults.standard.bool(forKey: securityCodeKey)
        hasCompletedAppOnboarding = UserDefaults.standard.bool(forKey: appOnboardingKey)
    }

    @MainActor
    func completeAppOnboarding() {
        hasCompletedAppOnboarding = true
        UserDefaults.standard.set(true, forKey: appOnboardingKey)
    }

    // MARK: - Security Code Methods

    @MainActor
    func verifySecurityCode(_ code: String) -> Bool {
        if validSecurityCodes.contains(code) {
            isSecurityCodeVerified = true
            UserDefaults.standard.set(true, forKey: securityCodeKey)
            return true
        }
        return false
    }

    // MARK: - Auth Methods

    @MainActor
    func initialize() async {
        guard !isInitialized else { return }

        isLoading = true
        print("DEBUG AppState: Initializing...")

        // Load stored credentials
        if let storedToken = KeychainService.shared.getToken() {
            print("DEBUG AppState: Found stored token, validating...")
            token = storedToken

            // Validate token with server
            do {
                let response: UserResponse = try await APIClient.shared.request(.getUser)
                print("DEBUG AppState: Token valid, setting auth")
                setAuth(
                    token: storedToken,
                    user: response.user,
                    tenant: response.tenant
                )
            } catch {
                print("DEBUG AppState: Token invalid, clearing auth: \(error)")
                // Token invalid, clear stored data
                clearAuth()
            }
        } else {
            print("DEBUG AppState: No stored token found")
        }

        isLoading = false
        isInitialized = true
        print("DEBUG AppState: Initialization complete, isAuthenticated: \(isAuthenticated)")
    }

    @MainActor
    func setAuth(token: String, user: User, tenant: Tenant, requiresOnboarding: Bool? = nil) {
        print("DEBUG AppState.setAuth: Setting auth for user \(user.name)")
        self.token = token
        self.user = user
        self.tenant = tenant
        self.isAuthenticated = true
        print("DEBUG AppState.setAuth: isAuthenticated = \(self.isAuthenticated)")

        // Only show onboarding if explicitly required or onboardingCompleted is explicitly false
        if let requires = requiresOnboarding {
            self.showOnboarding = requires
            print("DEBUG AppState.setAuth: showOnboarding (explicit) = \(requires)")
        } else {
            self.showOnboarding = tenant.onboardingCompleted == false
            print("DEBUG AppState.setAuth: showOnboarding (from tenant) = \(self.showOnboarding), onboardingCompleted = \(tenant.onboardingCompleted ?? false)")
        }

        // Persist to keychain
        KeychainService.shared.saveToken(token)
        KeychainService.shared.saveUserData(user)
        KeychainService.shared.saveTenantData(tenant)
        print("DEBUG AppState.setAuth: Credentials persisted to keychain")
    }

    @MainActor
    func updateUser(_ user: User) {
        self.user = user
        KeychainService.shared.saveUserData(user)
    }

    @MainActor
    func updateTenant(_ tenant: Tenant) {
        self.tenant = tenant
        self.showOnboarding = !(tenant.onboardingCompleted ?? false)
        KeychainService.shared.saveTenantData(tenant)
    }

    @MainActor
    func setOnboardingComplete() {
        if var updatedTenant = tenant {
            // Create new tenant with onboarding complete
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            if var tenantData = try? encoder.encode(updatedTenant),
               var tenantDict = try? JSONSerialization.jsonObject(with: tenantData) as? [String: Any] {
                tenantDict["onboarding_completed"] = true
                if let newData = try? JSONSerialization.data(withJSONObject: tenantDict),
                   let newTenant = try? decoder.decode(Tenant.self, from: newData) {
                    updateTenant(newTenant)
                }
            }
        }
        showOnboarding = false
    }

    @MainActor
    func logout() {
        clearAuth()

        // Call logout API (fire and forget)
        Task {
            try? await APIClient.shared.requestEmpty(.logout)
        }
    }

    @MainActor
    private func clearAuth() {
        token = nil
        user = nil
        tenant = nil
        isAuthenticated = false
        showOnboarding = false

        KeychainService.shared.clearAll()
    }

    // MARK: - Error Handling

    @MainActor
    func setError(_ message: String) {
        errorMessage = message
    }

    @MainActor
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Environment Key

struct AppStateKey: EnvironmentKey {
    static let defaultValue = AppState()
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
