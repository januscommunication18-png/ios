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

    @MainActor
    func createInsurancePolicy(request: InsurancePolicyRequest) async -> Bool {
        do {
            print("DEBUG: Creating insurance policy...")
            print("DEBUG: Request dictionary: \(request.toDictionary())")
            let _: GenericResponse = try await APIClient.shared.request(.createInsurancePolicy, bodyDict: request.toDictionary())
            print("DEBUG: Insurance policy created successfully")
            return true
        } catch {
            print("DEBUG: Failed to create insurance policy: \(error)")
            errorMessage = "Failed to create insurance policy: \(error.localizedDescription)"
            return false
        }
    }

    @MainActor
    func createTaxReturn(request: TaxReturnRequest) async -> Bool {
        do {
            let _: GenericResponse = try await APIClient.shared.request(.createTaxReturn, body: request)
            return true
        } catch {
            errorMessage = "Failed to create tax return"
            return false
        }
    }
}

// MARK: - Request Models

struct InsurancePolicyRequest {
    let insuranceType: String
    let providerName: String
    let policyNumber: String?
    let groupNumber: String?
    let planName: String?
    let premiumAmount: Double?
    let paymentFrequency: String?
    let effectiveDate: String?
    let expirationDate: String?
    let status: String?
    let agentName: String?
    let agentPhone: String?
    let agentEmail: String?
    let claimsPhone: String?
    let coverageDetails: String?
    let notes: String?
    let policyholders: [Int]?
    let coveredMembers: [Int]?
    let cardFrontImage: UIImage?
    let cardBackImage: UIImage?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "insurance_type": insuranceType,
            "provider_name": providerName,
            "status": status ?? "active"
        ]

        if let policyNumber = policyNumber { dict["policy_number"] = policyNumber }
        if let groupNumber = groupNumber { dict["group_number"] = groupNumber }
        if let planName = planName { dict["plan_name"] = planName }
        if let premiumAmount = premiumAmount { dict["premium_amount"] = premiumAmount }
        if let paymentFrequency = paymentFrequency { dict["payment_frequency"] = paymentFrequency }
        if let effectiveDate = effectiveDate { dict["effective_date"] = effectiveDate }
        if let expirationDate = expirationDate { dict["expiration_date"] = expirationDate }
        if let agentName = agentName { dict["agent_name"] = agentName }
        if let agentPhone = agentPhone { dict["agent_phone"] = agentPhone }
        if let agentEmail = agentEmail { dict["agent_email"] = agentEmail }
        if let claimsPhone = claimsPhone { dict["claims_phone"] = claimsPhone }
        if let coverageDetails = coverageDetails { dict["coverage_details"] = coverageDetails }
        if let notes = notes { dict["notes"] = notes }
        if let policyholders = policyholders, !policyholders.isEmpty { dict["policyholders"] = policyholders }
        if let coveredMembers = coveredMembers, !coveredMembers.isEmpty { dict["covered_members"] = coveredMembers }

        if let frontImage = cardFrontImage, let base64 = frontImage.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
            dict["card_front_image"] = "data:image/jpeg;base64,\(base64)"
        }
        if let backImage = cardBackImage, let base64 = backImage.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
            dict["card_back_image"] = "data:image/jpeg;base64,\(base64)"
        }

        return dict
    }
}

struct TaxReturnRequest: Encodable {
    let taxYear: Int
    let filingStatus: String?
    let status: String?
    let taxJurisdiction: String?
    let stateJurisdiction: String?
    let cpaName: String?
    let cpaPhone: String?
    let cpaEmail: String?
    let cpaFirm: String?
    let filingDate: String?
    let dueDate: String?
    let refundAmount: Double?
    let amountOwed: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case status, notes
        case taxYear = "tax_year"
        case filingStatus = "filing_status"
        case taxJurisdiction = "tax_jurisdiction"
        case stateJurisdiction = "state_jurisdiction"
        case cpaName = "cpa_name"
        case cpaPhone = "cpa_phone"
        case cpaEmail = "cpa_email"
        case cpaFirm = "cpa_firm"
        case filingDate = "filing_date"
        case dueDate = "due_date"
        case refundAmount = "refund_amount"
        case amountOwed = "amount_owed"
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectedTab == 0 {
                        router.navigate(to: .createInsurancePolicy)
                    } else {
                        router.navigate(to: .createTaxReturn)
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await viewModel.loadDocuments() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DocumentCreated"))) { _ in
            Task { await viewModel.loadDocuments() }
        }
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
                    Text(policy.insuranceTypeName.uppercased())
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
                    if let planName = policy.planName, !planName.isEmpty {
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

                // Policy Information Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(icon: "shield.fill", title: "Policy Information", subtitle: "Basic insurance policy details", color: .blue)

                    VStack(spacing: 0) {
                        DetailRow(label: "Insurance Type", value: policy.insuranceTypeName)
                        Divider()
                        DetailRow(label: "Provider Name", value: policy.providerName ?? "N/A")
                        if let policyNumber = policy.policyNumber, !policyNumber.isEmpty {
                            Divider()
                            DetailRow(label: "Policy Number", value: policyNumber)
                        }
                        if let groupNumber = policy.groupNumber, !groupNumber.isEmpty {
                            Divider()
                            DetailRow(label: "Group Number", value: groupNumber)
                        }
                        if let planName = policy.planName, !planName.isEmpty {
                            Divider()
                            DetailRow(label: "Plan Name", value: planName)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppColors.background)
                .cornerRadius(16)

                // Dates & Payments Section
                if policy.effectiveDate != nil || policy.expirationDate != nil || policy.premiumAmount != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "calendar", title: "Dates & Payments", subtitle: "Coverage period and premium information", color: .green)

                        VStack(spacing: 0) {
                            if policy.effectiveDate != nil {
                                DetailRow(label: "Effective Date", value: formatDate(policy.effectiveDate))
                                Divider()
                            }
                            if policy.expirationDate != nil {
                                DetailRow(label: "Expiration Date", value: formatDate(policy.expirationDate))
                                Divider()
                            }
                            if policy.premiumAmount != nil {
                                DetailRow(label: "Premium Amount", value: formatCurrency(policy.premiumAmount))
                                if policy.paymentFrequency != nil {
                                    Divider()
                                }
                            }
                            if let freq = policy.paymentFrequency, !freq.isEmpty {
                                DetailRow(label: "Payment Frequency", value: formatPaymentFrequency(freq))
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Contact Information Section
                if policy.agentName != nil || policy.agentPhone != nil || policy.agentEmail != nil || policy.claimsPhone != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "person.circle.fill", title: "Contact Information", subtitle: "Agent and claims contact details", color: .purple)

                        VStack(spacing: 0) {
                            if let agentName = policy.agentName, !agentName.isEmpty {
                                DetailRow(label: "Agent Name", value: agentName)
                                Divider()
                            }
                            if let agentPhone = policy.agentPhone, !agentPhone.isEmpty {
                                Button {
                                    if let url = URL(string: "tel:\(agentPhone)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text("Agent Phone")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(AppColors.textSecondary)
                                        Spacer()
                                        Text(agentPhone)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .padding()
                                }
                                Divider()
                            }
                            if let agentEmail = policy.agentEmail, !agentEmail.isEmpty {
                                Button {
                                    if let url = URL(string: "mailto:\(agentEmail)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text("Agent Email")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(AppColors.textSecondary)
                                        Spacer()
                                        Text(agentEmail)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .padding()
                                }
                                Divider()
                            }
                            if let claimsPhone = policy.claimsPhone, !claimsPhone.isEmpty {
                                Button {
                                    if let url = URL(string: "tel:\(claimsPhone)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text("Claims Phone")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(AppColors.textSecondary)
                                        Spacer()
                                        Text(claimsPhone)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppColors.primary)
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

                // Additional Information Section
                if (policy.coverageDetails != nil && !policy.coverageDetails!.isEmpty) || (policy.notes != nil && !policy.notes!.isEmpty) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "doc.text.fill", title: "Additional Information", subtitle: "Coverage details and notes", color: .gray)

                        VStack(spacing: 12) {
                            if let coverageDetails = policy.coverageDetails, !coverageDetails.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Coverage Details")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    Text(coverageDetails)
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                            }

                            if let notes = policy.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    Text(notes)
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(16)
                }

                // Insurance Card Images Section
                if policy.cardFrontImageUrl != nil || policy.cardBackImageUrl != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "creditcard.fill", title: "Insurance Card", subtitle: "Your insurance card images", color: .orange)

                        VStack(spacing: 12) {
                            if let frontUrl = policy.cardFrontImageUrl, let url = URL(string: frontUrl) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Front of Card")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 200)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(12)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .font(.system(size: 48))
                                                .foregroundColor(AppColors.textTertiary)
                                                .frame(height: 200)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }

                            if let backUrl = policy.cardBackImageUrl, let url = URL(string: backUrl) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Back of Card")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 200)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(12)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .font(.system(size: 48))
                                                .foregroundColor(AppColors.textTertiary)
                                                .frame(height: 200)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
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

    private func formatPaymentFrequency(_ frequency: String) -> String {
        let frequencies: [String: String] = [
            "monthly": "Monthly",
            "quarterly": "Quarterly",
            "semi_annual": "Semi-Annual",
            "annual": "Annual",
            "one_time": "One Time"
        ]
        return frequencies[frequency.lowercased()] ?? frequency.replacingOccurrences(of: "_", with: " ").capitalized
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
                if (taxReturn.federalReturnsUrls?.isEmpty == false) ||
                   (taxReturn.stateReturnsUrls?.isEmpty == false) ||
                   (taxReturn.supportingDocumentsUrls?.isEmpty == false) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "doc.fill", title: "Documents", subtitle: "Tax return files", color: .blue)

                        VStack(spacing: 12) {
                            // Federal Returns
                            if let federalDocs = taxReturn.federalReturnsUrls, !federalDocs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Federal Returns")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    ForEach(federalDocs) { doc in
                                        TaxDocumentRow(document: doc, color: AppColors.info)
                                    }
                                }
                            }

                            // State Returns
                            if let stateDocs = taxReturn.stateReturnsUrls, !stateDocs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("State Returns")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    ForEach(stateDocs) { doc in
                                        TaxDocumentRow(document: doc, color: AppColors.success)
                                    }
                                }
                            }

                            // Supporting Documents
                            if let supportingDocs = taxReturn.supportingDocumentsUrls, !supportingDocs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Supporting Documents")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                    ForEach(supportingDocs) { doc in
                                        TaxDocumentRow(document: doc, color: AppColors.warning)
                                    }
                                }
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



// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
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

// MARK: - Tax Document Row

struct TaxDocumentRow: View {
    let document: TaxDocument
    let color: Color

    var body: some View {
        Button {
            if let url = URL(string: document.url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: fileIcon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    Text("Tap to view")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.primary)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var fileIcon: String {
        let ext = (document.name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "gif": return "photo.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        default: return "doc.fill"
        }
    }
}

// MARK: - Create Insurance Policy View

struct CreateInsurancePolicyView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = DocumentsViewModel()

    // Form fields
    @State private var insuranceType = ""
    @State private var providerName = ""
    @State private var policyNumber = ""
    @State private var groupNumber = ""
    @State private var planName = ""
    @State private var premiumAmount = ""
    @State private var paymentFrequency = ""
    @State private var effectiveDate: Date?
    @State private var expirationDate: Date?
    @State private var status = "active"
    @State private var agentName = ""
    @State private var agentPhone = ""
    @State private var agentEmail = ""
    @State private var claimsPhone = ""
    @State private var coverageDetails = ""
    @State private var notes = ""

    // Family members
    @State private var familyMembers: [SimpleFamilyMember] = []
    @State private var selectedPolicyholders: Set<Int> = []
    @State private var selectedCoveredMembers: Set<Int> = []
    @State private var isLoadingMembers = false

    // Insurance Card Images
    @State private var cardFrontImage: UIImage?
    @State private var cardBackImage: UIImage?
    @State private var showingFrontImagePicker = false
    @State private var showingBackImagePicker = false

    @State private var isSaving = false
    @State private var showError = false

    static let insuranceTypes = [
        ("health", "Health"),
        ("dental", "Dental"),
        ("vision", "Vision"),
        ("life", "Life"),
        ("auto", "Auto"),
        ("home", "Home"),
        ("renters", "Renters"),
        ("umbrella", "Umbrella"),
        ("disability", "Disability"),
        ("long_term_care", "Long Term Care"),
        ("pet", "Pet"),
        ("travel", "Travel"),
        ("other", "Other")
    ]

    static let statusOptions = [
        ("active", "Active"),
        ("pending", "Pending"),
        ("expired", "Expired"),
        ("cancelled", "Cancelled")
    ]

    static let paymentFrequencies = [
        ("monthly", "Monthly"),
        ("quarterly", "Quarterly"),
        ("semi_annual", "Semi-Annual"),
        ("annual", "Annual"),
        ("one_time", "One Time")
    ]

    var body: some View {
        Form {
            // Policy Information
            Section {
                Picker("Insurance Type *", selection: $insuranceType) {
                    Text("Select").tag("")
                    ForEach(Self.insuranceTypes, id: \.0) { type in
                        Text(type.1).tag(type.0)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(Self.statusOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }

                TextField("Provider Name *", text: $providerName)

                // Policyholder Selection
                NavigationLink {
                    MultiSelectMemberView(
                        title: "Select Policyholders",
                        members: familyMembers,
                        selectedIds: $selectedPolicyholders
                    )
                } label: {
                    HStack {
                        Text("Policyholder")
                        Spacer()
                        if selectedPolicyholders.isEmpty {
                            Text("None")
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedPolicyholders.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Covered Members Selection
                NavigationLink {
                    MultiSelectMemberView(
                        title: "Select Covered Members",
                        members: familyMembers,
                        selectedIds: $selectedCoveredMembers
                    )
                } label: {
                    HStack {
                        Text("Covered Members")
                        Spacer()
                        if selectedCoveredMembers.isEmpty {
                            Text("None")
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedCoveredMembers.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                TextField("Policy Number", text: $policyNumber)

                TextField("Group Number", text: $groupNumber)

                TextField("Plan Name", text: $planName)
            } header: {
                Label("Policy Information", systemImage: "shield.fill")
            }

            // Insurance Card Images
            Section {
                // Front of Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Front of Card")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let image = cardFrontImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(8)
                            .onTapGesture { showingFrontImagePicker = true }
                    } else {
                        Button {
                            showingFrontImagePicker = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    if cardFrontImage != nil {
                        Button("Remove", role: .destructive) {
                            cardFrontImage = nil
                        }
                        .font(.caption)
                    }
                }

                // Back of Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Back of Card")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let image = cardBackImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(8)
                            .onTapGesture { showingBackImagePicker = true }
                    } else {
                        Button {
                            showingBackImagePicker = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    if cardBackImage != nil {
                        Button("Remove", role: .destructive) {
                            cardBackImage = nil
                        }
                        .font(.caption)
                    }
                }
            } header: {
                Label("Insurance Card", systemImage: "creditcard.fill")
            }

            // Dates & Payments
            Section {
                DatePicker("Effective Date", selection: Binding(
                    get: { effectiveDate ?? Date() },
                    set: { effectiveDate = $0 }
                ), displayedComponents: .date)

                if effectiveDate != nil {
                    Button("Clear Effective Date") { effectiveDate = nil }
                        .foregroundColor(.red)
                        .font(.caption)
                }

                DatePicker("Expiration Date", selection: Binding(
                    get: { expirationDate ?? Date() },
                    set: { expirationDate = $0 }
                ), displayedComponents: .date)

                if expirationDate != nil {
                    Button("Clear Expiration Date") { expirationDate = nil }
                        .foregroundColor(.red)
                        .font(.caption)
                }

                HStack {
                    Text("$")
                    TextField("Premium Amount", text: $premiumAmount)
                        .keyboardType(.decimalPad)
                }

                Picker("Payment Frequency", selection: $paymentFrequency) {
                    Text("Select").tag("")
                    ForEach(Self.paymentFrequencies, id: \.0) { freq in
                        Text(freq.1).tag(freq.0)
                    }
                }
            } header: {
                Label("Dates & Payments", systemImage: "calendar")
            }

            // Contact Information
            Section {
                TextField("Agent Name", text: $agentName)
                    .onChange(of: agentName) { _, newValue in
                        agentName = newValue.filter { !$0.isNumber }
                    }

                TextField("Agent Phone", text: $agentPhone)
                    .keyboardType(.phonePad)
                    .onChange(of: agentPhone) { _, newValue in
                        agentPhone = newValue.filter { "0123456789 ()-+".contains($0) }
                    }

                TextField("Agent Email", text: $agentEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                TextField("Claims Phone", text: $claimsPhone)
                    .keyboardType(.phonePad)
                    .onChange(of: claimsPhone) { _, newValue in
                        claimsPhone = newValue.filter { "0123456789 ()-+".contains($0) }
                    }
            } header: {
                Label("Contact Information", systemImage: "person.circle")
            }

            // Additional Information
            Section {
                TextField("Coverage Details", text: $coverageDetails, axis: .vertical)
                    .lineLimit(3...6)

                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Label("Additional Information", systemImage: "note.text")
            }
        }
        .navigationTitle("Add Insurance Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(insuranceType.isEmpty || providerName.isEmpty || isSaving)
            }
        }
        .sheet(isPresented: $showingFrontImagePicker) {
            DocumentImagePicker(image: $cardFrontImage)
        }
        .sheet(isPresented: $showingBackImagePicker) {
            DocumentImagePicker(image: $cardBackImage)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Failed to save insurance policy")
        }
        .task {
            await loadFamilyMembers()
        }
    }

    private func loadFamilyMembers() async {
        isLoadingMembers = true
        do {
            let response: FamilyMembersListResponse = try await APIClient.shared.request(.familyMembers)
            familyMembers = response.members ?? []
        } catch {
            print("Failed to load family members: \(error)")
        }
        isLoadingMembers = false
    }

    private func save() async {
        isSaving = true
        showError = false

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = InsurancePolicyRequest(
            insuranceType: insuranceType,
            providerName: providerName,
            policyNumber: policyNumber.isEmpty ? nil : policyNumber,
            groupNumber: groupNumber.isEmpty ? nil : groupNumber,
            planName: planName.isEmpty ? nil : planName,
            premiumAmount: Double(premiumAmount),
            paymentFrequency: paymentFrequency.isEmpty ? nil : paymentFrequency,
            effectiveDate: effectiveDate != nil ? formatter.string(from: effectiveDate!) : nil,
            expirationDate: expirationDate != nil ? formatter.string(from: expirationDate!) : nil,
            status: status,
            agentName: agentName.isEmpty ? nil : agentName,
            agentPhone: agentPhone.isEmpty ? nil : agentPhone,
            agentEmail: agentEmail.isEmpty ? nil : agentEmail,
            claimsPhone: claimsPhone.isEmpty ? nil : claimsPhone,
            coverageDetails: coverageDetails.isEmpty ? nil : coverageDetails,
            notes: notes.isEmpty ? nil : notes,
            policyholders: selectedPolicyholders.isEmpty ? nil : Array(selectedPolicyholders),
            coveredMembers: selectedCoveredMembers.isEmpty ? nil : Array(selectedCoveredMembers),
            cardFrontImage: cardFrontImage,
            cardBackImage: cardBackImage
        )

        let success = await viewModel.createInsurancePolicy(request: request)
        isSaving = false

        if success {
            NotificationCenter.default.post(name: NSNotification.Name("DocumentCreated"), object: nil)
            router.goBack()
        } else {
            showError = true
        }
    }
}

// MARK: - Simple Family Member for Selection

struct SimpleFamilyMember: Codable, Identifiable {
    let id: Int
    let firstName: String?
    let lastName: String?

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct FamilyMembersListResponse: Codable {
    let members: [SimpleFamilyMember]?
}

// MARK: - Multi-Select Member View

struct MultiSelectMemberView: View {
    let title: String
    let members: [SimpleFamilyMember]
    @Binding var selectedIds: Set<Int>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(members) { member in
                Button {
                    if selectedIds.contains(member.id) {
                        selectedIds.remove(member.id)
                    } else {
                        selectedIds.insert(member.id)
                    }
                } label: {
                    HStack {
                        Text(member.fullName)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if selectedIds.contains(member.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Document Image Picker

struct DocumentImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: DocumentImagePicker

        init(_ parent: DocumentImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Create Tax Return View

struct CreateTaxReturnView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = DocumentsViewModel()

    // Form fields
    @State private var taxYear = Calendar.current.component(.year, from: Date())
    @State private var filingStatus = ""
    @State private var status = "not_started"
    @State private var taxJurisdiction = "federal"
    @State private var stateJurisdiction = ""
    @State private var cpaName = ""
    @State private var cpaPhone = ""
    @State private var cpaEmail = ""
    @State private var cpaFirm = ""
    @State private var filingDate: Date?
    @State private var dueDate: Date?
    @State private var refundAmount = ""
    @State private var amountOwed = ""
    @State private var notes = ""

    @State private var isSaving = false

    static let filingStatuses = [
        ("single", "Single"),
        ("married_filing_jointly", "Married Filing Jointly"),
        ("married_filing_separately", "Married Filing Separately"),
        ("head_of_household", "Head of Household"),
        ("qualifying_widow", "Qualifying Widow(er)")
    ]

    static let statusOptions = [
        ("not_started", "Not Started"),
        ("gathering_docs", "Gathering Documents"),
        ("in_progress", "In Progress"),
        ("review", "Under Review"),
        ("filed", "Filed"),
        ("amended", "Amended")
    ]

    static let jurisdictions = [
        ("federal", "Federal"),
        ("state", "State"),
        ("both", "Federal & State")
    ]

    static let usStates = [
        ("AL", "Alabama"), ("AK", "Alaska"), ("AZ", "Arizona"), ("AR", "Arkansas"),
        ("CA", "California"), ("CO", "Colorado"), ("CT", "Connecticut"), ("DE", "Delaware"),
        ("FL", "Florida"), ("GA", "Georgia"), ("HI", "Hawaii"), ("ID", "Idaho"),
        ("IL", "Illinois"), ("IN", "Indiana"), ("IA", "Iowa"), ("KS", "Kansas"),
        ("KY", "Kentucky"), ("LA", "Louisiana"), ("ME", "Maine"), ("MD", "Maryland"),
        ("MA", "Massachusetts"), ("MI", "Michigan"), ("MN", "Minnesota"), ("MS", "Mississippi"),
        ("MO", "Missouri"), ("MT", "Montana"), ("NE", "Nebraska"), ("NV", "Nevada"),
        ("NH", "New Hampshire"), ("NJ", "New Jersey"), ("NM", "New Mexico"), ("NY", "New York"),
        ("NC", "North Carolina"), ("ND", "North Dakota"), ("OH", "Ohio"), ("OK", "Oklahoma"),
        ("OR", "Oregon"), ("PA", "Pennsylvania"), ("RI", "Rhode Island"), ("SC", "South Carolina"),
        ("SD", "South Dakota"), ("TN", "Tennessee"), ("TX", "Texas"), ("UT", "Utah"),
        ("VT", "Vermont"), ("VA", "Virginia"), ("WA", "Washington"), ("WV", "West Virginia"),
        ("WI", "Wisconsin"), ("WY", "Wyoming"), ("DC", "District of Columbia")
    ]

    var body: some View {
        Form {
            // Tax Return Information
            Section {
                Picker("Tax Year *", selection: $taxYear) {
                    ForEach((2010...(Calendar.current.component(.year, from: Date()) + 1)).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }

                Picker("Filing Status", selection: $filingStatus) {
                    Text("Select").tag("")
                    ForEach(Self.filingStatuses, id: \.0) { status in
                        Text(status.1).tag(status.0)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(Self.statusOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }

                Picker("Tax Jurisdiction", selection: $taxJurisdiction) {
                    ForEach(Self.jurisdictions, id: \.0) { juris in
                        Text(juris.1).tag(juris.0)
                    }
                }

                Picker("State", selection: $stateJurisdiction) {
                    Text("Select").tag("")
                    ForEach(Self.usStates, id: \.0) { state in
                        Text(state.1).tag(state.0)
                    }
                }
            } header: {
                Label("Tax Return Information", systemImage: "doc.text.fill")
            }

            // Dates
            Section {
                DatePicker("Filing Date", selection: Binding(
                    get: { filingDate ?? Date() },
                    set: { filingDate = $0 }
                ), displayedComponents: .date)

                if filingDate != nil {
                    Button("Clear Filing Date") { filingDate = nil }
                        .foregroundColor(.red)
                        .font(.caption)
                }

                DatePicker("Due Date", selection: Binding(
                    get: { dueDate ?? Date() },
                    set: { dueDate = $0 }
                ), displayedComponents: .date)

                if dueDate != nil {
                    Button("Clear Due Date") { dueDate = nil }
                        .foregroundColor(.red)
                        .font(.caption)
                }
            } header: {
                Label("Dates", systemImage: "calendar")
            }

            // Amounts
            Section {
                HStack {
                    Text("$")
                    TextField("Refund Amount", text: $refundAmount)
                        .keyboardType(.decimalPad)
                }

                HStack {
                    Text("$")
                    TextField("Amount Owed", text: $amountOwed)
                        .keyboardType(.decimalPad)
                }
            } header: {
                Label("Financial", systemImage: "dollarsign.circle")
            }

            // CPA Information
            Section {
                TextField("CPA Name", text: $cpaName)
                    .onChange(of: cpaName) { _, newValue in
                        cpaName = newValue.filter { !$0.isNumber }
                    }

                TextField("Firm Name", text: $cpaFirm)

                TextField("Phone", text: $cpaPhone)
                    .keyboardType(.phonePad)
                    .onChange(of: cpaPhone) { _, newValue in
                        cpaPhone = newValue.filter { "0123456789 ()-+".contains($0) }
                    }

                TextField("Email", text: $cpaEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            } header: {
                Label("CPA / Tax Preparer", systemImage: "person.circle")
            }

            // Notes
            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Label("Notes", systemImage: "note.text")
            }
        }
        .navigationTitle("Add Tax Return")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = TaxReturnRequest(
            taxYear: taxYear,
            filingStatus: filingStatus.isEmpty ? nil : filingStatus,
            status: status,
            taxJurisdiction: taxJurisdiction,
            stateJurisdiction: stateJurisdiction.isEmpty ? nil : stateJurisdiction,
            cpaName: cpaName.isEmpty ? nil : cpaName,
            cpaPhone: cpaPhone.isEmpty ? nil : cpaPhone,
            cpaEmail: cpaEmail.isEmpty ? nil : cpaEmail,
            cpaFirm: cpaFirm.isEmpty ? nil : cpaFirm,
            filingDate: filingDate != nil ? formatter.string(from: filingDate!) : nil,
            dueDate: dueDate != nil ? formatter.string(from: dueDate!) : nil,
            refundAmount: Double(refundAmount),
            amountOwed: Double(amountOwed),
            notes: notes.isEmpty ? nil : notes
        )

        let success = await viewModel.createTaxReturn(request: request)
        isSaving = false

        if success {
            NotificationCenter.default.post(name: NSNotification.Name("DocumentCreated"), object: nil)
            router.goBack()
        }
    }
}
