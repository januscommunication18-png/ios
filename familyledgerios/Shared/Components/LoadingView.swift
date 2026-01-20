import SwiftUI

struct LoadingView: View {
    var message: String?
    var color: Color = AppColors.primary

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(color)

            if let message = message {
                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

struct FullScreenLoadingView: View {
    var message: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                if let message = message {
                    Text(message)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(.white)
                }
            }
            .padding(32)
            .background(Color(.systemGray5).opacity(0.9))
            .cornerRadius(16)
        }
    }
}

struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    var message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)

            if isLoading {
                FullScreenLoadingView(message: message)
            }
        }
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingView(message: "Loading...")

        FullScreenLoadingView(message: "Please wait...")
    }
}
