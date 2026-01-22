import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()
    @State private var currentStep: LoginStep = .social
    @State private var loginMethod: LoginMethod = .password
    @State private var showPassword = false

    enum LoginStep {
        case social
        case email
        case loginMethod
        case otpVerify
    }

    enum LoginMethod {
        case password
        case otp
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemGray6)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Logo Section
                    VStack(spacing: 8) {
                        Text("Family Ledger")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.primary)

                        Text("Safeguard your family's important information")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemGray))
                    }
                    .padding(.bottom, 32)

                    // Card
                    VStack(spacing: 0) {
                        switch currentStep {
                        case .social:
                            socialStepView
                        case .email:
                            emailStepView
                        case .loginMethod:
                            loginMethodStepView
                        case .otpVerify:
                            otpVerifyStepView
                        }

                        // Error Alert
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.top, 16)
                        }

                        // Success Alert
                        if let success = viewModel.successMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(success)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.top, 16)
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)

                    // Footer
                    Text("\u{00A9} \(Calendar.current.component(.year, from: Date())) Family Ledger. All rights reserved.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.systemGray))
                        .padding(.bottom, 20)
                }
            }
        }
        .loadingOverlay(viewModel.isLoading)
    }

    // MARK: - Step 1: Social Login

    private var socialStepView: some View {
        VStack(spacing: 16) {
            Text("Welcome Back")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, 8)

            // Social Login Buttons
            socialButton(icon: "g.circle.fill", text: "Continue with Google", color: .red) {
                // Google login - not implemented
            }

            socialButton(icon: "apple.logo", text: "Continue with Apple", color: .black) {
                // Apple login - not implemented
            }

            socialButton(icon: "f.circle.fill", text: "Continue with Facebook", color: .blue) {
                // Facebook login - not implemented
            }

            // Divider
            HStack {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
                Text("or")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))
                    .padding(.horizontal, 16)
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            // Continue with Email
            Button {
                withAnimation {
                    currentStep = .email
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope")
                        .font(.system(size: 18))
                    Text("Continue with Email")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Step 2: Email Input

    private var emailStepView: some View {
        VStack(spacing: 16) {
            // Back button and title
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        currentStep = .social
                        viewModel.clearError()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }

                Text("Sign in with email")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))

                Spacer()
            }
            .padding(.bottom, 8)

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))

                TextField("you@example.com", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }

            // Continue Button
            Button {
                withAnimation {
                    currentStep = .loginMethod
                    viewModel.clearError()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.isEmailValid ? AppColors.primary : AppColors.primary.opacity(0.5))
                .cornerRadius(8)
            }
            .disabled(!viewModel.isEmailValid)
        }
    }

    // MARK: - Step 3: Login Method Selection

    private var loginMethodStepView: some View {
        VStack(spacing: 16) {
            // Back button and email display
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        currentStep = .email
                        viewModel.clearError()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }

                Text("Signing in as ")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))
                +
                Text(viewModel.email)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }
            .padding(.bottom, 8)

            // Method Selection
            Text("Choose how you'd like to sign in:")
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Password Option
            loginMethodOption(
                isSelected: loginMethod == .password,
                icon: "lock.fill",
                title: "Use my password",
                description: "Sign in with your account password. Best for quick access."
            ) {
                loginMethod = .password
            }

            // OTP Option
            loginMethodOption(
                isSelected: loginMethod == .otp,
                icon: "envelope.fill",
                title: "Email me a code",
                description: "We'll send a one-time 6-digit code to your email. No password needed."
            ) {
                loginMethod = .otp
            }

            // Password Form
            if loginMethod == .password {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray))

                    HStack {
                        if showPassword {
                            TextField("Enter your password", text: $viewModel.password)
                        } else {
                            SecureField("Enter your password", text: $viewModel.password)
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(Color(.systemGray))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.top, 8)

                // Forgot Password
                HStack {
                    Spacer()
                    Button {
                        // Navigate to forgot password
                    } label: {
                        Text("Forgot password?")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.primary)
                    }
                }

                // Sign In Button
                Button {
                    Task {
                        await viewModel.login(appState: appState)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.to.line")
                            .font(.system(size: 16))
                        Text("Sign In")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.isLoginFormValid ? AppColors.primary : AppColors.primary.opacity(0.5))
                    .cornerRadius(8)
                }
                .disabled(!viewModel.isLoginFormValid)
            }

            // OTP Form
            if loginMethod == .otp {
                Button {
                    Task {
                        await viewModel.requestOTP()
                        if viewModel.showOTPVerification {
                            withAnimation {
                                currentStep = .otpVerify
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                        Text("Send Code")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Step 4: OTP Verify

    private var otpVerifyStepView: some View {
        VStack(spacing: 16) {
            // Back button
            HStack {
                Button {
                    withAnimation {
                        currentStep = .loginMethod
                        viewModel.clearError()
                        viewModel.clearSuccess()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                Spacer()
            }

            // Email sent confirmation
            VStack(spacing: 12) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)

                Text("We sent a 6-digit code to")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))
                Text(viewModel.email)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // OTP Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))

                TextField("000000", text: $viewModel.otpCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24, weight: .medium))
                    .tracking(8)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .onChange(of: viewModel.otpCode) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > 6 {
                            viewModel.otpCode = String(filtered.prefix(6))
                        } else if filtered != newValue {
                            viewModel.otpCode = filtered
                        }
                    }
            }

            // Verify Button
            Button {
                Task {
                    await viewModel.verifyOTP(appState: appState)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("Verify & Sign In")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.isOTPValid ? AppColors.primary : AppColors.primary.opacity(0.5))
                .cornerRadius(8)
            }
            .disabled(!viewModel.isOTPValid)

            // Resend Button
            Button {
                Task {
                    await viewModel.resendOTP()
                }
            } label: {
                Text("Didn't receive it? Resend Code")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))
            }
        }
    }

    // MARK: - Helper Views

    private func socialButton(icon: String, text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }

    private func loginMethodOption(isSelected: Bool, icon: String, title: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Radio button
                Circle()
                    .strokeBorder(isSelected ? AppColors.primary : Color(.systemGray4), lineWidth: 2)
                    .background(Circle().fill(isSelected ? AppColors.primary : Color.clear))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.primary)
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(.systemGray))
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(16)
            .background(isSelected ? AppColors.primary.opacity(0.05) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
