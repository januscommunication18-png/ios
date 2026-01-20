import SwiftUI

// MARK: - Driver's License Detail View

struct DriversLicenseDetailView: View {
    let circleId: Int
    let memberId: Int
    let document: MemberDocument?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.info.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Text("🪪")
                            .font(.system(size: 40))
                    }

                    Text("Driver's License")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.textPrimary)

                    // Status Badge
                    if let doc = document {
                        statusBadge(isExpired: doc.isExpired ?? false)
                    } else {
                        Text("Not on File")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.background)
                .cornerRadius(16)

                if let doc = document {
                    // Document Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("LICENSE DETAILS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            DetailRow(label: "License Number", value: doc.documentNumber ?? "N/A")
                            Divider()
                            DetailRow(label: "Issuing State", value: doc.issuingState ?? "N/A")
                            Divider()
                            DetailRow(label: "Issuing Authority", value: doc.issuingAuthority ?? "N/A")
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Dates Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DATES")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            DetailRow(label: "Issue Date", value: formatDate(doc.issueDate))
                            Divider()
                            if doc.isExpired ?? false {
                                HStack {
                                    Text("Expiry Date")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Text(formatDate(doc.expiryDate))
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.error)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            } else {
                                DetailRow(label: "Expiry Date", value: formatDate(doc.expiryDate))
                            }
                            if let daysUntilExpiry = doc.daysUntilExpiry, daysUntilExpiry > 0 {
                                Divider()
                                DetailRow(label: "Days Until Expiry", value: "\(daysUntilExpiry) days")
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                } else {
                    // Empty State
                    emptyDocumentState(documentType: "driver's license")
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Driver's License")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Passport Detail View

struct PassportDetailView: View {
    let circleId: Int
    let memberId: Int
    let document: MemberDocument?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.family.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Text("📘")
                            .font(.system(size: 40))
                    }

                    Text("Passport")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.textPrimary)

                    // Status Badge
                    if let doc = document {
                        statusBadge(isExpired: doc.isExpired ?? false)
                    } else {
                        Text("Not on File")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.background)
                .cornerRadius(16)

                if let doc = document {
                    // Document Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PASSPORT DETAILS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            DetailRow(label: "Passport Number", value: doc.documentNumber ?? "N/A")
                            Divider()
                            DetailRow(label: "Issuing Country", value: doc.issuingCountry ?? "N/A")
                            Divider()
                            DetailRow(label: "Issuing Authority", value: doc.issuingAuthority ?? "N/A")
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Dates Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DATES")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            DetailRow(label: "Issue Date", value: formatDate(doc.issueDate))
                            Divider()
                            if doc.isExpired ?? false {
                                HStack {
                                    Text("Expiry Date")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Text(formatDate(doc.expiryDate))
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.error)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            } else {
                                DetailRow(label: "Expiry Date", value: formatDate(doc.expiryDate))
                            }
                            if let daysUntilExpiry = doc.daysUntilExpiry, daysUntilExpiry > 0 {
                                Divider()
                                DetailRow(label: "Days Until Expiry", value: "\(daysUntilExpiry) days")
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                } else {
                    // Empty State
                    emptyDocumentState(documentType: "passport")
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Passport")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Social Security Detail View

struct SocialSecurityDetailView: View {
    let circleId: Int
    let memberId: Int
    let document: MemberDocument?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.success.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Text("🔒")
                            .font(.system(size: 40))
                    }

                    Text("Social Security")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.textPrimary)

                    // Status Badge
                    if document != nil {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 8, height: 8)
                            Text("On File")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.success)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        Text("Not on File")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.background)
                .cornerRadius(16)

                if let doc = document {
                    // Document Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SSN DETAILS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            DetailRow(label: "SSN (Masked)", value: maskedSsn(doc.documentNumber))
                            Divider()
                            DetailRow(label: "Status", value: "Secure & On File")
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Security Notice
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(AppColors.success)
                            Text("Security Notice")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Text("Your Social Security Number is encrypted and stored securely. Only the last 4 digits are displayed for your protection.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                    .background(AppColors.success.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    // Empty State
                    emptyDocumentState(documentType: "Social Security card")
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Social Security")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func maskedSsn(_ ssn: String?) -> String {
        guard let ssn = ssn, ssn.count >= 4 else { return "XXX-XX-****" }
        return "XXX-XX-\(ssn.suffix(4))"
    }
}

// MARK: - Birth Certificate Detail View

struct BirthCertificateDetailView: View {
    let circleId: Int
    let memberId: Int
    let document: MemberDocument?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.warning.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Text("📄")
                            .font(.system(size: 40))
                    }

                    Text("Birth Certificate")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.textPrimary)

                    // Status Badge
                    if document != nil {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 8, height: 8)
                            Text("On File")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.success)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        Text("Not on File")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.background)
                .cornerRadius(16)

                if let doc = document {
                    // Document Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CERTIFICATE DETAILS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            DetailRow(label: "Certificate Number", value: doc.documentNumber ?? "N/A")
                            Divider()
                            DetailRow(label: "Issuing State/Country", value: doc.issuingState ?? doc.issuingCountry ?? "N/A")
                            Divider()
                            DetailRow(label: "Issuing Authority", value: doc.issuingAuthority ?? "N/A")
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)

                    // Issue Date Section
                    if doc.issueDate != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DATES")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .tracking(0.5)

                            VStack(spacing: 0) {
                                DetailRow(label: "Issue Date", value: formatDate(doc.issueDate))
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(16)
                    }
                } else {
                    // Empty State
                    emptyDocumentState(documentType: "birth certificate")
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Birth Certificate")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared Helper Views

@ViewBuilder
private func statusBadge(isExpired: Bool) -> some View {
    HStack(spacing: 6) {
        Circle()
            .fill(isExpired ? AppColors.error : AppColors.success)
            .frame(width: 8, height: 8)
        Text(isExpired ? "Expired" : "Valid")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isExpired ? AppColors.error : AppColors.success)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background((isExpired ? AppColors.error : AppColors.success).opacity(0.1))
    .cornerRadius(12)
}

@ViewBuilder
private func emptyDocumentState(documentType: String) -> some View {
    VStack(spacing: 16) {
        Image(systemName: "doc.text.fill")
            .font(.system(size: 48))
            .foregroundColor(AppColors.textTertiary)

        Text("No \(documentType.capitalized) on File")
            .font(AppTypography.headline)
            .foregroundColor(AppColors.textSecondary)

        Text("This document hasn't been added yet.")
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textTertiary)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(40)
    .background(AppColors.background)
    .cornerRadius(16)
}

private func formatDate(_ dateString: String?) -> String {
    guard let dateString = dateString else { return "N/A" }

    // Try ISO8601 format first
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoFormatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM dd, yyyy"
        return displayFormatter.string(from: date)
    }

    // Try simple date format
    let simpleFormatter = DateFormatter()
    simpleFormatter.dateFormat = "yyyy-MM-dd"
    if let date = simpleFormatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM dd, yyyy"
        return displayFormatter.string(from: date)
    }

    return dateString
}
