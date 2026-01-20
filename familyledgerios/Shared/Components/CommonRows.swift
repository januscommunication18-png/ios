import SwiftUI

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding()
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)

                    Text(value)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let icon: String
    let title: String
    var color: Color = AppColors.primary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))

            Text(title)
                .font(AppTypography.labelMedium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        DetailRow(label: "Name", value: "John Doe")
        ContactRow(icon: "phone.fill", label: "Phone", value: "+1 234 567 8900", action: {})
        StatusBadge(icon: "figure.child", title: "Minor", color: AppColors.warning)
    }
    .padding()
}
