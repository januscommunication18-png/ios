import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case email, password
        case deviceName = "device_name"
    }
}

struct OTPRequestBody: Encodable {
    let email: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case email
        case deviceName = "device_name"
    }
}

struct OTPVerifyRequest: Encodable {
    let email: String
    let code: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case email, code
        case deviceName = "device_name"
    }
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let email: String
    let code: String
    let password: String
    let passwordConfirmation: String

    enum CodingKeys: String, CodingKey {
        case email, code, password
        case passwordConfirmation = "password_confirmation"
    }
}

struct AuthResponse: Decodable {
    let token: String
    let tokenType: String?
    let isNewUser: Bool?
    let requiresOnboarding: Bool?
    let user: User
    let tenant: Tenant

    enum CodingKeys: String, CodingKey {
        case token, user, tenant
        case tokenType = "token_type"
        case isNewUser = "is_new_user"
        case requiresOnboarding = "requires_onboarding"
    }
}

struct UserResponse: Decodable {
    let user: User
    let tenant: Tenant
}

struct OTPRequestResponse: Decodable {
    let message: String
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case expiresIn = "expires_in"
    }
}

struct MessageResponse: Decodable {
    let message: String
}
