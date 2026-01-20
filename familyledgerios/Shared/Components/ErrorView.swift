import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.title = "Error"
        self.message = error.localizedDescription
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.error)

            VStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(10)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Inline Error Banner

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(AppTypography.bodySmall)
                .foregroundColor(.white)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(AppColors.error)
        .cornerRadius(10)
    }
}

// MARK: - Success Banner

struct SuccessBanner: View {
    let message: String
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(AppTypography.bodySmall)
                .foregroundColor(.white)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(AppColors.success)
        .cornerRadius(10)
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorView(
            message: "Failed to load data. Please check your connection.",
            retryAction: { }
        )

        ErrorBanner(message: "Something went wrong") { }
            .padding()

        SuccessBanner(message: "Successfully saved!") { }
            .padding()
    }
}
