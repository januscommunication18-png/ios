import Foundation
import SwiftUI
import UIKit

@Observable
final class AuthViewModel {
    // MARK: - Properties

    var name = ""
    var email = ""
    var password = ""
    var otpCode = ""
    var resetCode = ""
    var newPassword = ""
    var confirmPassword = ""

    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    // MARK: - Navigation State

    var showOTPVerification = false
    var showResetPassword = false

    // MARK: - Computed Properties

    var isEmailValid: Bool {
        email.isValidEmail
    }

    var isPasswordValid: Bool {
        password.count >= 8
    }

    var isLoginFormValid: Bool {
        isEmailValid && isPasswordValid
    }

    var isOTPValid: Bool {
        otpCode.count == 6
    }

    var isResetFormValid: Bool {
        isEmailValid && resetCode.count == 6 && newPassword.count >= 8 && newPassword == confirmPassword
    }

    private var deviceName: String {
        UIDevice.current.name
    }

    // MARK: - Auth Methods

    @MainActor
    func login(appState: AppState) async {
        guard isLoginFormValid else {
            errorMessage = "Please enter a valid email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = LoginRequest(
                email: email,
                password: password,
                deviceName: deviceName
            )

            print("DEBUG: Attempting login for \(email)")
            let response: AuthResponse = try await APIClient.shared.request(.login, body: request)
            print("DEBUG: Login successful, token received: \(response.token.prefix(20))...")
            print("DEBUG: User: \(response.user.name), Tenant: \(response.tenant.name)")
            print("DEBUG: Onboarding completed: \(response.tenant.onboardingCompleted ?? false)")

            appState.setAuth(
                token: response.token,
                user: response.user,
                tenant: response.tenant,
                requiresOnboarding: response.requiresOnboarding
            )
            print("DEBUG: Auth set, isAuthenticated: \(appState.isAuthenticated)")

            clearForm()
        } catch let error as APIError {
            print("DEBUG: Login failed with APIError: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("DEBUG: Login failed with unexpected error: \(error)")
            errorMessage = "An unexpected error occurred"
        }

        isLoading = false
    }

    @MainActor
    func requestOTP() async {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = OTPRequestBody(
                email: email,
                deviceName: deviceName
            )

            let _: OTPRequestResponse = try await APIClient.shared.request(.otpRequest, body: request)

            showOTPVerification = true
            successMessage = "OTP sent to your email"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to send OTP"
        }

        isLoading = false
    }

    @MainActor
    func verifyOTP(appState: AppState) async {
        guard isOTPValid else {
            errorMessage = "Please enter a valid 6-digit code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = OTPVerifyRequest(
                email: email,
                code: otpCode,
                deviceName: deviceName
            )

            let response: AuthResponse = try await APIClient.shared.request(.otpVerify, body: request)

            appState.setAuth(
                token: response.token,
                user: response.user,
                tenant: response.tenant,
                requiresOnboarding: response.requiresOnboarding
            )

            clearForm()
            showOTPVerification = false
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to verify OTP"
        }

        isLoading = false
    }

    @MainActor
    func resendOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            let request = OTPRequestBody(
                email: email,
                deviceName: deviceName
            )

            let _: OTPRequestResponse = try await APIClient.shared.request(.otpResend, body: request)
            successMessage = "OTP resent successfully"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to resend OTP"
        }

        isLoading = false
    }

    @MainActor
    func forgotPassword() async {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = ForgotPasswordRequest(email: email)
            let _: MessageResponse = try await APIClient.shared.request(.forgotPassword, body: request)

            showResetPassword = true
            successMessage = "Reset code sent to your email"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to send reset code"
        }

        isLoading = false
    }

    @MainActor
    func resetPassword() async {
        guard isResetFormValid else {
            if newPassword != confirmPassword {
                errorMessage = "Passwords do not match"
            } else {
                errorMessage = "Please fill in all fields correctly"
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = ResetPasswordRequest(
                email: email,
                code: resetCode,
                password: newPassword,
                passwordConfirmation: confirmPassword
            )

            let _: MessageResponse = try await APIClient.shared.request(.resetPassword, body: request)

            successMessage = "Password reset successfully. Please login."
            clearForm()
            showResetPassword = false
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to reset password"
        }

        isLoading = false
    }

    @MainActor
    func resendResetCode() async {
        isLoading = true
        errorMessage = nil

        do {
            let request = ForgotPasswordRequest(email: email)
            let _: MessageResponse = try await APIClient.shared.request(.resendResetCode, body: request)
            successMessage = "Reset code resent successfully"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to resend reset code"
        }

        isLoading = false
    }

    @MainActor
    func register(appState: AppState) async {
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            return
        }

        guard isEmailValid else {
            errorMessage = "Please enter a valid email"
            return
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let request = RegisterRequest(
                name: name,
                email: email,
                password: password,
                deviceName: deviceName
            )

            let response: AuthResponse = try await APIClient.shared.request(.register, body: request)

            appState.setAuth(
                token: response.token,
                user: response.user,
                tenant: response.tenant,
                requiresOnboarding: response.requiresOnboarding
            )

            clearForm()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    func clearForm() {
        email = ""
        password = ""
        otpCode = ""
        resetCode = ""
        newPassword = ""
        confirmPassword = ""
    }

    func clearError() {
        errorMessage = nil
    }

    func clearSuccess() {
        successMessage = nil
    }
}
