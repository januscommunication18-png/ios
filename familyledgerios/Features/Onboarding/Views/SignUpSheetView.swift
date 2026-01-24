import SwiftUI

struct SignUpSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var agreedToTerms = false
    @State private var showEmailForm = false

    var onSignInTapped: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Create Your Account")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 20)

                    if !showEmailForm {
                        // Sign Up Options
                        signUpOptionsView
                    } else {
                        // Email Form
                        emailFormView
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                    }

                    // Already have account
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                        Button {
                            dismiss()
                            onSignInTapped?()
                        } label: {
                            Text("Sign in")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if showEmailForm {
                        Button {
                            withAnimation {
                                showEmailForm = false
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Sign Up Options View

    private var signUpOptionsView: some View {
        VStack(spacing: 12) {
            socialButtonDisabled(
                icon: "g.circle.fill",
                text: "Sign up with Google",
                iconColor: Color(red: 0.26, green: 0.52, blue: 0.96)
            )

            socialButtonDisabled(
                icon: "apple.logo",
                text: "Sign up with Apple",
                iconColor: .black
            )

            socialButtonDisabled(
                icon: "f.circle.fill",
                text: "Sign up with Facebook",
                iconColor: Color(red: 0.23, green: 0.35, blue: 0.60)
            )

            // Sign up with Email button
            Button {
                withAnimation {
                    showEmailForm = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                    Text("Sign up with Email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.primary, lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Email Form View

    private var emailFormView: some View {
        VStack(spacing: 16) {
            // Full Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                TextField("John Doe", text: $viewModel.name)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .onChange(of: viewModel.name) { _, newValue in
                        viewModel.name = newValue.filter { !$0.isNumber }
                    }
            }

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                TextField("you@example.com", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                HStack {
                    if showPassword {
                        TextField("Create a strong password", text: $viewModel.password)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Create a strong password", text: $viewModel.password)
                            .textContentType(.newPassword)
                    }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(Color(.systemGray))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

                Text("Min. 12 characters with uppercase, lowercase, number, and symbol")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray))
            }

            // Terms Agreement
            HStack(alignment: .center, spacing: 12) {
                Button {
                    agreedToTerms.toggle()
                } label: {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(agreedToTerms ? AppColors.primary : Color(.systemGray4))
                }

                Text("I agree to the ")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
                +
                Text("Terms of Service")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.primary)
                +
                Text(" and ")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
                +
                Text("Privacy Policy")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)

            // Create Account Button
            Button {
                Task {
                    await register()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                        Text("Creating...")
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFormValid ? AppColors.primary : AppColors.primary.opacity(0.5))
                .cornerRadius(8)
            }
            .disabled(!isFormValid || viewModel.isLoading)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Computed Properties

    private var isPasswordStrong: Bool {
        let password = viewModel.password
        guard password.count >= 12 else { return false }

        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumber = password.contains(where: { $0.isNumber })
        let hasSymbol = password.contains(where: { !$0.isLetter && !$0.isNumber })

        return hasUppercase && hasLowercase && hasNumber && hasSymbol
    }

    private var isFormValid: Bool {
        !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        viewModel.isEmailValid &&
        isPasswordStrong &&
        agreedToTerms
    }

    // MARK: - Methods

    private func register() async {
        viewModel.errorMessage = nil

        // Validate name (only letters and spaces)
        let nameRegex = try? NSRegularExpression(pattern: "^[a-zA-Z\\s]+$")
        let nameRange = NSRange(viewModel.name.startIndex..., in: viewModel.name)
        if nameRegex?.firstMatch(in: viewModel.name, range: nameRange) == nil {
            viewModel.errorMessage = "Please enter a valid name (e.g., John Snow). Only letters are allowed."
            return
        }

        if !isPasswordStrong {
            viewModel.errorMessage = "Password must be at least 12 characters with uppercase, lowercase, number, and symbol"
            return
        }

        await viewModel.register(appState: appState)
    }

    private func socialButtonDisabled(icon: String, text: String, iconColor: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor.opacity(0.5))
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textPrimary.opacity(0.5))
            Spacer()
            Text("Coming Soon")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(.systemGray))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .opacity(0.6)
    }
}

#Preview {
    SignUpSheetView()
        .environment(AppState())
}
