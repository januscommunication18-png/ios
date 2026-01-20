import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isDisabled ? Color.gray : color)
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(color)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(AppTypography.headline)
            .foregroundColor(isDisabled ? .gray : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
    }
}

struct OutlineButton: View {
    let title: String
    var icon: String?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(color)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(AppTypography.headline)
            .foregroundColor(isDisabled ? .gray : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDisabled ? Color.gray : color, lineWidth: 2)
            )
        }
        .disabled(isDisabled || isLoading)
    }
}

struct IconButton: View {
    let icon: String
    var size: CGFloat = 44
    var color: Color = AppColors.primary
    var backgroundColor: Color = AppColors.primary.opacity(0.1)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }
}

struct TextButton: View {
    let title: String
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.labelLarge)
                .foregroundColor(color)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", icon: "arrow.right") { }

        PrimaryButton(title: "Loading...", isLoading: true) { }

        SecondaryButton(title: "Cancel") { }

        OutlineButton(title: "Learn More") { }

        HStack(spacing: 16) {
            IconButton(icon: "plus") { }
            IconButton(icon: "heart.fill", color: .red, backgroundColor: .red.opacity(0.1)) { }
            IconButton(icon: "trash", color: AppColors.error, backgroundColor: AppColors.error.opacity(0.1)) { }
        }

        TextButton(title: "Forgot Password?") { }
    }
    .padding()
}
