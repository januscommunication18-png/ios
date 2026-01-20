import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()
    @State private var loginMethod: LoginMethod = .password

    enum LoginMethod: String, CaseIterable {
        case password = "Password"
        case otp = "OTP"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo & Header
                    headerSection

                    // Login Method Selector
                    loginMethodPicker

                    // Form Fields
                    formSection

                    // Login Button
                    loginButton

                    // Forgot Password
                    if loginMethod == .password {
                        forgotPasswordButton
                    }

                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationDestination(isPresented: $viewModel.showOTPVerification) {
                OTPVerifyView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $viewModel.showResetPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
            .loadingOverlay(viewModel.isLoading)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)

            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(AppTypography.displayMedium)
                    .foregroundColor(AppColors.textPrimary)

                Text("Sign in to continue to Family Ledger")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Login Method Picker

    private var loginMethodPicker: some View {
        Picker("Login Method", selection: $loginMethod) {
            ForEach(LoginMethod.allCases, id: \.self) { method in
                Text(method.rawValue).tag(method)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 16) {
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

            // Password Field (only for password method)
            if loginMethod == .password {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textSecondary)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(AppColors.textSecondary)

                        SecureField("Enter your password", text: $viewModel.password)
                            .textContentType(.password)
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        PrimaryButton(
            title: loginMethod == .password ? "Sign In" : "Send OTP",
            icon: loginMethod == .password ? "arrow.right" : "paperplane",
            isLoading: viewModel.isLoading,
            isDisabled: loginMethod == .password ? !viewModel.isLoginFormValid : !viewModel.isEmailValid
        ) {
            Task {
                if loginMethod == .password {
                    await viewModel.login(appState: appState)
                } else {
                    await viewModel.requestOTP()
                }
            }
        }
    }

    // MARK: - Forgot Password Button

    private var forgotPasswordButton: some View {
        Button {
            viewModel.showResetPassword = true
        } label: {
            Text("Forgot Password?")
                .font(AppTypography.labelLarge)
                .foregroundColor(AppColors.primary)
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
