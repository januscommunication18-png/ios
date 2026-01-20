import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String?
    var icon: String?
    var color: Color = AppColors.primary
    var trend: TrendDirection?
    var trendValue: String?

    enum TrendDirection {
        case up, down, neutral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                        .background(color.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                if let trend = trend, let trendValue = trendValue {
                    TrendBadge(direction: trend, value: trendValue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(AppTypography.numberMedium)
                    .foregroundColor(AppColors.textPrimary)

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct TrendBadge: View {
    let direction: StatCard.TrendDirection
    let value: String

    var icon: String {
        switch direction {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    var color: Color {
        switch direction {
        case .up: return AppColors.success
        case .down: return AppColors.error
        case .neutral: return AppColors.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(value)
                .font(AppTypography.captionSmall)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    var icon: String?
    var color: Color = AppColors.primary

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTypography.numberSmall)
                    .foregroundColor(AppColors.textPrimary)

                Text(title)
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(12)
        .background(AppColors.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    var color: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            StatCard(
                title: "Family Members",
                value: "12",
                icon: "person.3.fill",
                color: AppColors.family,
                trend: .up,
                trendValue: "+2"
            )

            HStack(spacing: 12) {
                MiniStatCard(
                    title: "Assets",
                    value: "$125K",
                    icon: "house.fill",
                    color: AppColors.assets
                )

                MiniStatCard(
                    title: "Expenses",
                    value: "$3.2K",
                    icon: "dollarsign.circle.fill",
                    color: AppColors.expenses
                )
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(title: "Add Member", icon: "person.badge.plus", color: AppColors.family) { }
                QuickActionCard(title: "Add Expense", icon: "plus.circle", color: AppColors.expenses) { }
                QuickActionCard(title: "Documents", icon: "doc.fill", color: AppColors.primary) { }
                QuickActionCard(title: "Settings", icon: "gearshape.fill") { }
            }

            FeatureCard(
                title: "Expenses",
                subtitle: "Track and manage spending",
                icon: "dollarsign.circle.fill",
                color: AppColors.expenses
            ) { }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
