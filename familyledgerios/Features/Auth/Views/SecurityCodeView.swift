import SwiftUI

struct SecurityCodeView: View {
    @Environment(AppState.self) private var appState
    @State private var securityCode = ""
    @State private var errorMessage: String?
    @State private var isShaking = false
    @FocusState private var isCodeFocused: Bool

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
                        // Lock Icon
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 64, height: 64)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.bottom, 16)

                        // Header
                        Text("Private Access")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, 8)

                        Text("Enter your security code to continue")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemGray))
                            .padding(.bottom, 24)

                        // Code Input
                        VStack(spacing: 8) {
                            TextField("Enter access code", text: $securityCode)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 24, weight: .medium))
                                .tracking(8)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(errorMessage != nil ? Color.red : Color(.systemGray4), lineWidth: 1)
                                )
                                .focused($isCodeFocused)
                                .onChange(of: securityCode) { _, newValue in
                                    // Limit to 4 digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 4 {
                                        securityCode = String(filtered.prefix(4))
                                    } else if filtered != newValue {
                                        securityCode = filtered
                                    }
                                    // Clear error when typing
                                    errorMessage = nil
                                }
                                .modifier(ShakeEffect(shakes: isShaking ? 2 : 0))
                                .animation(.default, value: isShaking)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.bottom, 16)

                        // Continue Button
                        Button {
                            verifyCode()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right.to.line")
                                    .font(.system(size: 16))
                                Text("Continue")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.primary)
                            .cornerRadius(8)
                        }
                        .disabled(securityCode.count != 4)
                        .opacity(securityCode.count != 4 ? 0.6 : 1)

                        // Beta Notice
                        Text("This site is currently in private beta.")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.systemGray))
                            .padding(.top, 24)
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
        .onAppear {
            isCodeFocused = true
        }
    }

    private func verifyCode() {
        if appState.verifySecurityCode(securityCode) {
            // Success - AppState will update and view will change
        } else {
            errorMessage = "Invalid security code. Please try again."
            isShaking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShaking = false
            }
            securityCode = ""
        }
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 2), y: 0))
    }
}

#Preview {
    SecurityCodeView()
        .environment(AppState())
}
