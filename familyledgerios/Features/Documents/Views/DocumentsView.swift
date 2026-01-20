import SwiftUI

@Observable
final class DocumentsViewModel {
    var policies: [InsurancePolicy] = []
    var taxReturns: [TaxReturn] = []
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadDocuments() async {
        isLoading = policies.isEmpty && taxReturns.isEmpty
        do {
            let response: DocumentsResponse = try await APIClient.shared.request(.documents)
            policies = response.insurancePolicies ?? []
            taxReturns = response.taxReturns ?? []
        } catch {
            errorMessage = "Failed to load documents"
        }
        isLoading = false
    }
}

struct DocumentsView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = DocumentsViewModel()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading documents...")
            } else {
                VStack(spacing: 0) {
                    Picker("Type", selection: $selectedTab) {
                        Text("Insurance").tag(0)
                        Text("Tax Returns").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if selectedTab == 0 {
                        insuranceList
                    } else {
                        taxReturnsList
                    }
                }
            }
        }
        .navigationTitle("Documents")
        .task { await viewModel.loadDocuments() }
    }

    private var insuranceList: some View {
        Group {
            if viewModel.policies.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No Insurance Policies")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Add insurance policies to track them here")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(viewModel.policies) { policy in
                    Button { router.navigate(to: .insurancePolicy(id: policy.id)) } label: {
                        VStack(alignment: .leading) {
                            Text(policy.provider ?? "Unknown Provider").font(AppTypography.headline)
                            Text((policy.policyType ?? "Other").capitalized).font(AppTypography.caption).foregroundColor(AppColors.textSecondary)
                            Text("Policy #\(policy.policyNumber ?? "N/A")").font(AppTypography.captionSmall).foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
        }
    }

    private var taxReturnsList: some View {
        Group {
            if viewModel.taxReturns.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No Tax Returns")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Add tax returns to track them here")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(viewModel.taxReturns) { taxReturn in
                    Button { router.navigate(to: .taxReturn(id: taxReturn.id)) } label: {
                        VStack(alignment: .leading) {
                            Text("Tax Year \(taxReturn.taxYear ?? 0)").font(AppTypography.headline)
                            Text((taxReturn.filingStatus ?? "unknown").replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(AppTypography.caption).foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Insurance Policy Detail View

@Observable
final class InsurancePolicyDetailViewModel {
    var policy: InsurancePolicy?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadPolicy(id: Int) async {
        isLoading = policy == nil
        do {
            let response: InsurancePolicyResponse = try await APIClient.shared.request(.insurancePolicy(id: id))
            policy = response.insurancePolicy
        } catch {
            errorMessage = "Failed to load policy details"
        }
        isLoading = false
    }
}

struct InsurancePolicyDetailView: View {
    let policyId: Int
    @State private var viewModel = InsurancePolicyDetailViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading policy...")
            } else if let policy = viewModel.policy {
                policyContent(policy: policy)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadPolicy(id: policyId) }
                }
            } else {
                LoadingView(message: "Loading policy...")
            }
        }
        .navigationTitle("Insurance Policy")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadPolicy(id: policyId) }
    }

    private func policyContent(policy: InsurancePolicy) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 12) {
                    // Type Badge
                    Text((policy.insuranceType ?? "Insurance").uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(policyTypeColor(policy.insuranceType))
                        .cornerRadius(8)

                    // Provider Name
                    Text(policy.providerName ?? "Unknown Provider")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    // Plan Name
                    if let planName = policy.planName {
                        Text(planName)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Status Badge
                    if let status = policy.status {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(status == "active" ? AppColors.success : AppColors.warning)
                                .frame(width: 8, height: 8)
                            Text(status.capitalized)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(status == "active" ? AppColors.success : AppColors.warning)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background((status == "active" ? AppColors.success : AppColors.warning).opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.background)
                .cornerRadius(16)

                // Policy Details Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("POLICY DETAILS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(0.5)

                    VStack(spacing: 0) {
                        DetailRow(label: "Policy Number", value: policy.policyNumber ?? "N/A")
                        Divider()
                        DetailRow(label: "Group Number", value: policy.groupNumber ?? "N/A")
                        Divider()
                        DetailRow(label: "Insurance Type", value: (policy.insuranceType ?? "Other").capitalized)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Payment Details Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("PAYMENT")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(0.5)

                    VStack(spacing: 0) {
                        DetailRow(label: "Premium Amount", value: formatCurrency(policy.premiumAmount))
                        Divider()
                        DetailRow(label: "Payment Frequency", value: (policy.paymentFrequency ?? "N/A").replacingOccurrences(of: "_", with: " ").capitalized)
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
                        DetailRow(label: "Effective Date", value: formatDate(policy.effectiveDate))
                        Divider()
                        DetailRow(label: "Expiration Date", value: formatDate(policy.expirationDate))
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Notes Section
                if let notes = policy.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NOTES")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        Text(notes)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func policyTypeColor(_ type: String?) -> Color {
        switch type?.lowercased() {
        case "health": return AppColors.success
        case "dental": return AppColors.info
        case "vision": return Color.purple
        case "life": return AppColors.family
        case "auto": return AppColors.warning
        case "home", "homeowners": return Color.orange
        default: return AppColors.textSecondary
        }
    }

    private func formatCurrency(_ amount: String?) -> String {
        guard let amount = amount, let value = Double(amount) else { return "N/A" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "N/A"
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "N/A" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Tax Return Detail View

@Observable
final class TaxReturnDetailViewModel {
    var taxReturn: TaxReturn?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadTaxReturn(id: Int) async {
        isLoading = taxReturn == nil
        do {
            let response: TaxReturnResponse = try await APIClient.shared.request(.taxReturn(id: id))
            taxReturn = response.taxReturn
        } catch {
            errorMessage = "Failed to load tax return details"
        }
        isLoading = false
    }
}

struct TaxReturnDetailView: View {
    let returnId: Int
    @State private var viewModel = TaxReturnDetailViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading tax return...")
            } else if let taxReturn = viewModel.taxReturn {
                taxReturnContent(taxReturn: taxReturn)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadTaxReturn(id: returnId) }
                }
            } else {
                LoadingView(message: "Loading tax return...")
            }
        }
        .navigationTitle("Tax Return")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadTaxReturn(id: returnId) }
    }

    private func taxReturnContent(taxReturn: TaxReturn) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                VStack(spacing: 12) {
                    Text("TAX YEAR")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textTertiary)

                    Text("\(taxReturn.taxYear ?? 0)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppColors.family)

                    // Filing Status
                    if let status = taxReturn.filingStatus {
                        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Status Badge
                    if let status = taxReturn.status {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor(status))
                                .frame(width: 8, height: 8)
                            Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(statusColor(status))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor(status).opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppColors.background)
                .cornerRadius(16)

                // Financial Summary
                HStack(spacing: 12) {
                    // Refund
                    VStack(spacing: 8) {
                        Text("Refund")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                        Text(formatCurrency(taxReturn.refundAmount))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.success)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.success.opacity(0.1))
                    .cornerRadius(12)

                    // Amount Owed
                    VStack(spacing: 8) {
                        Text("Owed")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                        Text(formatCurrency(taxReturn.amountOwed))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.error)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.error.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Details Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("DETAILS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(0.5)

                    VStack(spacing: 0) {
                        DetailRow(label: "Tax Jurisdiction", value: (taxReturn.taxJurisdiction ?? "N/A").capitalized)
                        Divider()
                        DetailRow(label: "State", value: taxReturn.stateJurisdiction ?? "N/A")
                        Divider()
                        DetailRow(label: "Filing Date", value: formatDate(taxReturn.filingDate))
                        Divider()
                        DetailRow(label: "Due Date", value: formatDate(taxReturn.dueDate))
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // CPA/Tax Professional Section
                if taxReturn.cpaName != nil || taxReturn.cpaFirm != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TAX PROFESSIONAL")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            if let name = taxReturn.cpaName {
                                DetailRow(label: "Name", value: name)
                                Divider()
                            }
                            if let firm = taxReturn.cpaFirm {
                                DetailRow(label: "Firm", value: firm)
                                Divider()
                            }
                            if let phone = taxReturn.cpaPhone {
                                Button {
                                    if let url = URL(string: "tel:\(phone)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text("Phone")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(AppColors.textSecondary)
                                        Spacer()
                                        Text(phone)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppColors.family)
                                    }
                                    .padding()
                                }
                                Divider()
                            }
                            if let email = taxReturn.cpaEmail {
                                Button {
                                    if let url = URL(string: "mailto:\(email)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text("Email")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(AppColors.textSecondary)
                                        Spacer()
                                        Text(email)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppColors.family)
                                    }
                                    .padding()
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Documents Section
                if (taxReturn.federalReturns?.isEmpty == false) ||
                   (taxReturn.stateReturns?.isEmpty == false) ||
                   (taxReturn.supportingDocuments?.isEmpty == false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DOCUMENTS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 12) {
                            // Federal Returns
                            if let federal = taxReturn.federalReturns, !federal.isEmpty {
                                DocumentCountRow(
                                    icon: "doc.fill",
                                    title: "Federal Returns",
                                    count: federal.count,
                                    color: AppColors.info
                                )
                            }

                            // State Returns
                            if let state = taxReturn.stateReturns, !state.isEmpty {
                                DocumentCountRow(
                                    icon: "doc.fill",
                                    title: "State Returns",
                                    count: state.count,
                                    color: AppColors.success
                                )
                            }

                            // Supporting Documents
                            if let supporting = taxReturn.supportingDocuments, !supporting.isEmpty {
                                DocumentCountRow(
                                    icon: "paperclip",
                                    title: "Supporting Documents",
                                    count: supporting.count,
                                    color: AppColors.warning
                                )
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Notes Section
                if let notes = taxReturn.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NOTES")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(0.5)

                        Text(notes)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "filed", "completed": return AppColors.success
        case "gathering_docs", "in_progress": return AppColors.warning
        case "pending", "review": return AppColors.info
        default: return AppColors.textSecondary
        }
    }

    private func formatCurrency(_ amount: String?) -> String {
        guard let amount = amount, let value = Double(amount) else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "N/A" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}



// MARK: - Document Count Row

struct DocumentCountRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(count) file\(count == 1 ? "" : "s")")
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
