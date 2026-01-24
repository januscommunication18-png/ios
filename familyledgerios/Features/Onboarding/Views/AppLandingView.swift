import SwiftUI

struct AppLandingView: View {
    @Binding var showOnboarding: Bool
    @Binding var showLogin: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primary, AppColors.primary.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo and App Name
                VStack(spacing: 20) {
                    // App Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: "house.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }

                    // App Name
                    Text("Meet Olliee")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    // Tagline
                    Text("Safeguard your family's\nimportant information")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    // Get Started Button
                    Button {
                        showOnboarding = true
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    // Already have an account Button
                    Button {
                        showLogin = true
                    } label: {
                        Text("I already have an account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    AppLandingView(showOnboarding: .constant(false), showLogin: .constant(false))
}
