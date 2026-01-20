import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let tokenKey = "com.familyledger.authToken"
    private let userDataKey = "com.familyledger.userData"
    private let tenantDataKey = "com.familyledger.tenantData"

    private init() {}

    // MARK: - Token Management

    func saveToken(_ token: String) {
        save(key: tokenKey, data: token.data(using: .utf8)!)
    }

    func getToken() -> String? {
        guard let data = load(key: tokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteToken() {
        delete(key: tokenKey)
    }

    // MARK: - User Data Management

    func saveUserData(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            save(key: userDataKey, data: data)
        }
    }

    func getUserData() -> User? {
        guard let data = load(key: userDataKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func deleteUserData() {
        delete(key: userDataKey)
    }

    // MARK: - Tenant Data Management

    func saveTenantData(_ tenant: Tenant) {
        if let data = try? JSONEncoder().encode(tenant) {
            save(key: tenantDataKey, data: data)
        }
    }

    func getTenantData() -> Tenant? {
        guard let data = load(key: tenantDataKey) else { return nil }
        return try? JSONDecoder().decode(Tenant.self, from: data)
    }

    func deleteTenantData() {
        delete(key: tenantDataKey)
    }

    // MARK: - Clear All

    func clearAll() {
        deleteToken()
        deleteUserData()
        deleteTenantData()
    }

    // MARK: - Private Keychain Methods

    private func save(key: String, data: Data) {
        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
