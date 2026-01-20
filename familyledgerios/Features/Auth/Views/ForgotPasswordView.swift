import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AuthViewModel

    @State private var step: Step = .requestCode

    enum Step {
        case requestCode
        case resetPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection

                // Form based on step
                if step == .requestCode {
                    requestCodeSection
                } else {
                    resetPasswordSection
                }
            }
            .padding(24)
        }
        .background(AppColors.background)
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isLoading)
        .loadingOverlay(viewModel.isLoading)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.clearSuccess()
                if step == .resetPassword && viewModel.successMessage?.contains("successfully") == true {
                    dismiss()
                }
            }
        } message: {
            if let success = viewModel.successMessage {
                Text(success)
            }
        }
        .onChange(of: viewModel.showResetPassword) { _, newValue in
            if newValue {
                step = .resetPassword
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: step == .requestCode ? "key" : "lock.rotation")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary)

            VStack(spacing: 8) {
                Text(step == .requestCode ? "Forgot Password?" : "Reset Password")
                    .font(AppTypography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)

                Text(step == .requestCode
                    ? "Enter your email to receive a reset code"
                    : "Enter the code and your new password")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Request Code Section

    private var requestCodeSection: some View {
        VStack(spacing: 24) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)

                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(AppColors.textSecondary)

                    TextField("Enter your email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)
            }

            // Send Code Button
            PrimaryButton(
                title: "Send Reset Code",
                icon: "paperplane",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isEmailValid
            ) {
                Task {
                    await viewModel.forgotPassword()
                    if viewModel.errorMessage == nil {
                        step = .resetPassword
                    }
                }
            }
        }
    }

    // MARK: - Reset Password Section

    private var resetPasswordSection: some View {
        VStack(spacing: 24) {
            // Reset Code Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Reset Code")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)

                HStack {
                    Image(systemName: "number")
                        .foregroundColor(AppColors.textSecondary)

                    TextField("Enter 6-digit code", text: $viewModel.resetCode)
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.resetCode) { _, newValue in
                            if newValue.count > 6 {
                                viewModel.resetCode = String(newValue.prefix(6))
                            }
                            viewModel.resetCode = newValue.filter { $0.isNumber }
                        }
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)
            }

            // New Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)

                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(AppColors.textSecondary)

                    SecureField("Enter new password", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)

                if !viewModel.newPassword.isEmpty && viewModel.newPassword.count < 8 {
                    Text("Password must be at least 8 characters")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.error)
                }
            }

            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(AppColors.textSecondary)

                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)

                if !viewModel.confirmPassword.isEmpty && viewModel.newPassword != viewModel.confirmPassword {
                    Text("Passwords do not match")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.error)
                }
            }

            // Reset Password Button
            PrimaryButton(
                title: "Reset Password",
                icon: "checkmark",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isResetFormValid
            ) {
                Task {
                    await viewModel.resetPassword()
                }
            }

            // Resend Code Button
            Button {
                Task {
                    await viewModel.resendResetCode()
                }
            } label: {
                Text("Resend Code")
                    .font(AppTypography.labelLarge)
                    .foregroundColor(AppColors.primary)
            }
            .disabled(viewModel.isLoading)
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(viewModel: AuthViewModel())
    }
}
