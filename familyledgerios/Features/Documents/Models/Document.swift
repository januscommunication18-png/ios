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
    }

    // Computed properties for display
    var provider: String? { providerName }
    var policyType: String? { insuranceType }

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

    // Documents
    let federalReturns: [String]?
    let stateReturns: [String]?
    let supportingDocuments: [String]?

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
    }

    static func == (lhs: TaxReturn, rhs: TaxReturn) -> Bool { lhs.id == rhs.id }
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
