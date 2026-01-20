import SwiftUI

struct OTPVerifyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AuthViewModel

    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection

                // OTP Input
                otpInputSection

                // Verify Button
                verifyButton

                // Resend Section
                resendSection
            }
            .padding(24)
        }
        .background(AppColors.background)
        .navigationTitle("Verify OTP")
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
            Button("OK") { viewModel.clearSuccess() }
        } message: {
            if let success = viewModel.successMessage {
                Text(success)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 50))
                .foregroundColor(AppColors.primary)

            VStack(spacing: 8) {
                Text("Enter Verification Code")
                    .font(AppTypography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)

                Text("We've sent a 6-digit code to")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)

                Text(viewModel.email)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - OTP Input Section

    private var otpInputSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitField(
                        digit: getDigit(at: index),
                        isFocused: focusedField == index
                    )
                    .onTapGesture {
                        focusedField = index
                    }
                }
            }

            // Hidden text field for actual input
            TextField("", text: $viewModel.otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focusedField, equals: 0)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: viewModel.otpCode) { _, newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        viewModel.otpCode = String(newValue.prefix(6))
                    }
                    // Only allow numbers
                    viewModel.otpCode = newValue.filter { $0.isNumber }
                }
        }
        .onAppear {
            focusedField = 0
        }
    }

    private func getDigit(at index: Int) -> String {
        let digits = Array(viewModel.otpCode)
        if index < digits.count {
            return String(digits[index])
        }
        return ""
    }

    // MARK: - Verify Button

    private var verifyButton: some View {
        PrimaryButton(
            title: "Verify",
            icon: "checkmark.shield",
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.isOTPValid
        ) {
            Task {
                await viewModel.verifyOTP(appState: appState)
            }
        }
    }

    // MARK: - Resend Section

    private var resendSection: some View {
        VStack(spacing: 12) {
            Text("Didn't receive the code?")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)

            Button {
                Task {
                    await viewModel.resendOTP()
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

// MARK: - OTP Digit Field

struct OTPDigitField: View {
    let digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.secondaryBackground)
                .frame(width: 50, height: 60)

            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? AppColors.primary : Color.clear, lineWidth: 2)
                .frame(width: 50, height: 60)

            if digit.isEmpty {
                Circle()
                    .fill(AppColors.textTertiary)
                    .frame(width: 8, height: 8)
            } else {
                Text(digit)
                    .font(AppTypography.numberMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OTPVerifyView(viewModel: AuthViewModel())
            .environment(AppState())
    }
}
