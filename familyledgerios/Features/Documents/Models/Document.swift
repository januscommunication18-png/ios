import Foundation

struct InsurancePolicy: Codable, Identifiable, Equatable {
    let id: Int
    let insuranceType: String?
    let providerName: String?
    let policyNumber: String?
    let groupNumber: String?
    let planName: String?
    let premiumAmount: String?
    let paymentFrequency: String?
    let effectiveDate: String?
    let expirationDate: String?
    let status: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?

    // Agent/Contact Information
    let agentName: String?
    let agentPhone: String?
    let agentEmail: String?
    let claimsPhone: String?
    let coverageDetails: String?

    // Insurance Card Images
    let cardFrontImageUrl: String?
    let cardBackImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case insuranceType = "insurance_type"
        case providerName = "provider_name"
        case policyNumber = "policy_number"
        case groupNumber = "group_number"
        case planName = "plan_name"
        case premiumAmount = "premium_amount"
        case paymentFrequency = "payment_frequency"
        case effectiveDate = "effective_date"
        case expirationDate = "expiration_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case agentName = "agent_name"
        case agentPhone = "agent_phone"
        case agentEmail = "agent_email"
        case claimsPhone = "claims_phone"
        case coverageDetails = "coverage_details"
        case cardFrontImageUrl = "card_front_image_url"
        case cardBackImageUrl = "card_back_image_url"
    }

    // Computed properties for display
    var provider: String? { providerName }
    var policyType: String? { insuranceType }

    // Insurance type display name
    var insuranceTypeName: String {
        guard let type = insuranceType else { return "Insurance" }
        let types: [String: String] = [
            "health": "Health Insurance",
            "dental": "Dental Insurance",
            "vision": "Vision Insurance",
            "life": "Life Insurance",
            "auto": "Auto Insurance",
            "home": "Home Insurance",
            "renters": "Renters Insurance",
            "umbrella": "Umbrella Insurance",
            "disability": "Disability Insurance",
            "long_term_care": "Long Term Care Insurance",
            "pet": "Pet Insurance",
            "travel": "Travel Insurance",
            "other": "Other Insurance"
        ]
        return types[type.lowercased()] ?? type.capitalized + " Insurance"
    }

    static func == (lhs: InsurancePolicy, rhs: InsurancePolicy) -> Bool { lhs.id == rhs.id }
}

struct TaxReturn: Codable, Identifiable, Equatable {
    let id: Int
    let taxYear: Int?
    let filingStatus: String?
    let status: String?
    let taxJurisdiction: String?
    let stateJurisdiction: String?
    let filingDate: String?
    let dueDate: String?
    let refundAmount: String?
    let amountOwed: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?

    // CPA Info
    let cpaName: String?
    let cpaPhone: String?
    let cpaEmail: String?
    let cpaFirm: String?

    // Documents (raw paths)
    let federalReturns: [String]?
    let stateReturns: [String]?
    let supportingDocuments: [String]?

    // Document URLs
    let federalReturnsUrls: [TaxDocument]?
    let stateReturnsUrls: [TaxDocument]?
    let supportingDocumentsUrls: [TaxDocument]?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case taxYear = "tax_year"
        case filingStatus = "filing_status"
        case taxJurisdiction = "tax_jurisdiction"
        case stateJurisdiction = "state_jurisdiction"
        case filingDate = "filing_date"
        case dueDate = "due_date"
        case refundAmount = "refund_amount"
        case amountOwed = "amount_owed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case cpaName = "cpa_name"
        case cpaPhone = "cpa_phone"
        case cpaEmail = "cpa_email"
        case cpaFirm = "cpa_firm"
        case federalReturns = "federal_returns"
        case stateReturns = "state_returns"
        case supportingDocuments = "supporting_documents"
        case federalReturnsUrls = "federal_returns_urls"
        case stateReturnsUrls = "state_returns_urls"
        case supportingDocumentsUrls = "supporting_documents_urls"
    }

    static func == (lhs: TaxReturn, rhs: TaxReturn) -> Bool { lhs.id == rhs.id }
}

struct TaxDocument: Codable, Identifiable, Equatable {
    var id: String { path }
    let path: String
    let url: String
    let name: String
}

struct DocumentsResponse: Codable {
    let insurancePolicies: [InsurancePolicy]?
    let taxReturns: [TaxReturn]?

    enum CodingKeys: String, CodingKey {
        case insurancePolicies = "insurance_policies"
        case taxReturns = "tax_returns"
    }
}

struct InsurancePolicyResponse: Codable {
    let insurancePolicy: InsurancePolicy

    enum CodingKeys: String, CodingKey {
        case insurancePolicy = "insurance_policy"
    }
}

struct TaxReturnResponse: Codable {
    let taxReturn: TaxReturn

    enum CodingKeys: String, CodingKey {
        case taxReturn = "tax_return"
    }
}
