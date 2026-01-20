import SwiftUI

struct AppTypography {
    // MARK: - Display
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 24, weight: .bold, design: .default)

    // MARK: - Headlines
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    // MARK: - Body
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Labels
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Caption
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Numbers
    static let numberLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let numberMedium = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let numberSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
}

// MARK: - Text Modifiers

extension View {
    func displayLargeStyle() -> some View {
        self.font(AppTypography.displayLarge)
            .foregroundColor(AppColors.textPrimary)
    }

    func displayMediumStyle() -> some View {
        self.font(AppTypography.displayMedium)
            .foregroundColor(AppColors.textPrimary)
    }

    func headlineStyle() -> some View {
        self.font(AppTypography.headline)
            .foregroundColor(AppColors.textPrimary)
    }

    func subheadlineStyle() -> some View {
        self.font(AppTypography.subheadline)
            .foregroundColor(AppColors.textSecondary)
    }

    func bodyStyle() -> some View {
        self.font(AppTypography.bodyMedium)
            .foregroundColor(AppColors.textPrimary)
    }

    func captionStyle() -> some View {
        self.font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary)
    }
}
