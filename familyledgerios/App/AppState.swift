import Foundation
import SwiftUI

@Observable
final class AppState {
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
    }

    private func setupAPIClientCallback() {
        APIClient.shared.onUnauthorized = { [weak self] in
            self?.logout()
        }
    }

    // MARK: - Auth Methods

    @MainActor
    func initialize() async {
        guard !isInitialized else { return }

        isLoading = true

        // Load stored credentials
        if let storedToken = KeychainService.shared.getToken() {
            token = storedToken

            // Validate token with server
            do {
                let response: UserResponse = try await APIClient.shared.request(.getUser)
                setAuth(
                    token: storedToken,
                    user: response.user,
                    tenant: response.tenant
                )
            } catch {
                // Token invalid, clear stored data
                clearAuth()
            }
        }

        isLoading = false
        isInitialized = true
    }

    @MainActor
    func setAuth(token: String, user: User, tenant: Tenant, requiresOnboarding: Bool? = nil) {
        self.token = token
        self.user = user
        self.tenant = tenant
        self.isAuthenticated = true

        // Only show onboarding if explicitly required or onboardingCompleted is explicitly false
        if let requires = requiresOnboarding {
            self.showOnboarding = requires
        } else {
            self.showOnboarding = tenant.onboardingCompleted == false
        }

        // Persist to keychain
        KeychainService.shared.saveToken(token)
        KeychainService.shared.saveUserData(user)
        KeychainService.shared.saveTenantData(tenant)
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
