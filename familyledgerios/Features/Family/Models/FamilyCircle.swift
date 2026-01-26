import Foundation

struct FamilyCircle: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String?
    let coverImageUrl: String?
    let membersCount: Int?
    let createdAt: String?
    let updatedAt: String?
    let members: [FamilyMemberBasic]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, members
        case coverImageUrl = "cover_image_url"
        case membersCount = "members_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: FamilyCircle, rhs: FamilyCircle) -> Bool {
        lhs.id == rhs.id
    }
}

// Basic member info for list views (without complex nested types)
struct FamilyMemberBasic: Codable, Identifiable, Equatable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let email: String?
    let phone: String?
    let dateOfBirth: String?
    let age: Int?
    let relationship: String?
    let relationshipName: String?
    let isMinor: Bool?
    let profileImageUrl: String?
    let immigrationStatus: String?
    let immigrationStatusName: String?
    let coParentingEnabled: Bool?
    let createdAt: String?
    let updatedAt: String?
    let documentsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, age, relationship
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case relationshipName = "relationship_name"
        case isMinor = "is_minor"
        case profileImageUrl = "profile_image_url"
        case immigrationStatus = "immigration_status"
        case immigrationStatusName = "immigration_status_name"
        case coParentingEnabled = "co_parenting_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case documentsCount = "documents_count"
    }

    var displayName: String {
        fullName ?? "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let first = firstName?.prefix(1) ?? ""
        let last = lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    var relationshipIcon: String {
        switch relationship?.lowercased() {
        case "self": return "person.fill"
        case "spouse", "partner": return "heart.fill"
        case "child", "stepchild": return "figure.child"
        case "parent": return "figure.stand"
        case "sibling": return "person.2.fill"
        case "grandparent": return "figure.walk"
        case "guardian", "caregiver": return "hand.raised.fill"
        case "relative": return "person.3.fill"
        default: return "person.fill.questionmark"
        }
    }

    var formattedAge: String? {
        guard let age = age else { return nil }
        return "\(age) years old"
    }

    static func == (lhs: FamilyMemberBasic, rhs: FamilyMemberBasic) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Response Wrappers

struct FamilyCirclesResponse: Codable {
    let familyCircles: [FamilyCircle]?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case familyCircles = "family_circles"
        case total
    }
}

struct CreateFamilyCircleRequest: Encodable {
    let name: String
    let description: String?
    let includeMe: Bool
    let photo: String?

    enum CodingKeys: String, CodingKey {
        case name, description, photo
        case includeMe = "include_me"
    }
}

struct FamilyCircleDetailResponse: Codable {
    let familyCircle: FamilyCircle

    enum CodingKeys: String, CodingKey {
        case familyCircle = "family_circle"
    }
}

struct FamilyMembersResponse: Codable {
    let members: [FamilyMemberBasic]?
    let total: Int?
}

struct CreateFamilyMemberRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let phoneCountryCode: String?
    let dateOfBirth: String
    let relationship: String
    let fatherName: String?
    let motherName: String?
    let isMinor: Bool
    let coParentingEnabled: Bool
    let immigrationStatus: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case email, phone, relationship
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneCountryCode = "phone_country_code"
        case dateOfBirth = "date_of_birth"
        case fatherName = "father_name"
        case motherName = "mother_name"
        case isMinor = "is_minor"
        case coParentingEnabled = "co_parenting_enabled"
        case immigrationStatus = "immigration_status"
        case profileImage = "profile_image"
    }
}

struct CreateFamilyMemberResponse: Codable {
    let member: FamilyMemberBasic?
    let message: String?
}

struct RelationshipsResponse: Codable {
    let relationships: [String: String]
}

struct ImmigrationStatusesResponse: Codable {
    let immigrationStatuses: [String: String]

    enum CodingKeys: String, CodingKey {
        case immigrationStatuses = "immigration_statuses"
    }
}

struct FamilyMember: Codable, Identifiable, Equatable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let email: String?
    let phone: String?
    let dateOfBirth: String?
    let age: Int?
    let relationship: String?
    let relationshipName: String?
    let isMinor: Bool?
    let profileImageUrl: String?
    let immigrationStatus: String?
    let immigrationStatusName: String?
    let coParentingEnabled: Bool?
    let createdAt: String?
    let updatedAt: String?
    let documentsCount: Int?

    // Medical Info
    var medicalInfo: MedicalInfo?

    // Contacts
    var contacts: [MemberContact]?

    // Documents
    var driversLicense: MemberDocument?
    var passport: MemberDocument?
    var socialSecurity: MemberDocument?
    var birthCertificate: MemberDocument?

    // Health
    var allergies: [Allergy]?
    var medicalConditions: [MedicalCondition]?
    var healthcareProviders: [HealthcareProvider]?
    var medications: [FamilyMemberMedication]?
    var vaccinations: [MemberVaccination]?

    // Education / School
    var schoolInfo: MemberSchoolInfo?
    var schoolRecords: [MemberSchoolInfo]?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, age, relationship, contacts, allergies, medications, vaccinations
        case schoolInfo = "school_info"
        case schoolRecords = "school_records"
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case relationshipName = "relationship_name"
        case isMinor = "is_minor"
        case profileImageUrl = "profile_image_url"
        case immigrationStatus = "immigration_status"
        case immigrationStatusName = "immigration_status_name"
        case coParentingEnabled = "co_parenting_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case documentsCount = "documents_count"
        case medicalInfo = "medical_info"
        case driversLicense = "drivers_license"
        case passport
        case socialSecurity = "social_security"
        case birthCertificate = "birth_certificate"
        case medicalConditions = "medical_conditions"
        case healthcareProviders = "healthcare_providers"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required field
        id = try container.decode(Int.self, forKey: .id)

        // Basic fields (all optional, safe to decode)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        dateOfBirth = try container.decodeIfPresent(String.self, forKey: .dateOfBirth)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        relationship = try container.decodeIfPresent(String.self, forKey: .relationship)
        relationshipName = try container.decodeIfPresent(String.self, forKey: .relationshipName)
        isMinor = try container.decodeIfPresent(Bool.self, forKey: .isMinor)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        immigrationStatus = try container.decodeIfPresent(String.self, forKey: .immigrationStatus)
        immigrationStatusName = try container.decodeIfPresent(String.self, forKey: .immigrationStatusName)
        coParentingEnabled = try container.decodeIfPresent(Bool.self, forKey: .coParentingEnabled)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        documentsCount = try container.decodeIfPresent(Int.self, forKey: .documentsCount)

        // Nested types - use try? to gracefully handle decoding failures
        medicalInfo = try? container.decodeIfPresent(MedicalInfo.self, forKey: .medicalInfo)
        contacts = try? container.decodeIfPresent([MemberContact].self, forKey: .contacts)
        driversLicense = try? container.decodeIfPresent(MemberDocument.self, forKey: .driversLicense)
        passport = try? container.decodeIfPresent(MemberDocument.self, forKey: .passport)
        socialSecurity = try? container.decodeIfPresent(MemberDocument.self, forKey: .socialSecurity)
        birthCertificate = try? container.decodeIfPresent(MemberDocument.self, forKey: .birthCertificate)
        allergies = try? container.decodeIfPresent([Allergy].self, forKey: .allergies)
        medicalConditions = try? container.decodeIfPresent([MedicalCondition].self, forKey: .medicalConditions)
        healthcareProviders = try? container.decodeIfPresent([HealthcareProvider].self, forKey: .healthcareProviders)
        medications = try? container.decodeIfPresent([FamilyMemberMedication].self, forKey: .medications)
        vaccinations = try? container.decodeIfPresent([MemberVaccination].self, forKey: .vaccinations)
        schoolInfo = try? container.decodeIfPresent(MemberSchoolInfo.self, forKey: .schoolInfo)
        schoolRecords = try? container.decodeIfPresent([MemberSchoolInfo].self, forKey: .schoolRecords)
    }

    var displayName: String {
        fullName ?? "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let first = firstName?.prefix(1) ?? ""
        let last = lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    var relationshipIcon: String {
        switch relationship?.lowercased() {
        case "self": return "person.fill"
        case "spouse", "partner": return "heart.fill"
        case "child", "stepchild": return "figure.child"
        case "parent": return "figure.stand"
        case "sibling": return "person.2.fill"
        case "grandparent": return "figure.walk"
        case "guardian", "caregiver": return "hand.raised.fill"
        case "relative": return "person.3.fill"
        default: return "person.fill.questionmark"
        }
    }

    var formattedAge: String? {
        guard let age = age else { return nil }
        return "\(age) years old"
    }

    /// Returns date of birth formatted as "MMM dd, yyyy" (e.g., "Jan 15, 2000")
    var formattedDateOfBirth: String? {
        guard let dateOfBirth = dateOfBirth else { return nil }

        // Try ISO8601 format first (with time)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateOfBirth) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd, yyyy"
            return displayFormatter.string(from: date)
        }

        // Try simple date format (YYYY-MM-DD)
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        if let date = simpleFormatter.date(from: dateOfBirth) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM dd, yyyy"
            return displayFormatter.string(from: date)
        }

        // Return original if parsing fails
        return dateOfBirth
    }

    var emergencyContacts: [MemberContact] {
        contacts?.filter { $0.isEmergencyContact == true } ?? []
    }

    static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        lhs.id == rhs.id
    }
}

struct FamilyMemberDetailResponse: Codable {
    let member: FamilyMember
}

// MARK: - Medical Info

struct MedicalInfo: Codable, Hashable {
    let bloodType: String?
    let insuranceProvider: String?
    let insurancePolicyNumber: String?
    let insuranceGroupNumber: String?
    let primaryPhysician: String?
    let physicianPhone: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case bloodType = "blood_type"
        case insuranceProvider = "insurance_provider"
        case insurancePolicyNumber = "insurance_policy_number"
        case insuranceGroupNumber = "insurance_group_number"
        case primaryPhysician = "primary_physician"
        case physicianPhone = "physician_phone"
    }

    /// Blood type display names matching the web format
    static let bloodTypeDisplayNames: [String: String] = [
        "A+": "A Positive (A+)",
        "A-": "A Negative (A-)",
        "B+": "B Positive (B+)",
        "B-": "B Negative (B-)",
        "AB+": "AB Positive (AB+)",
        "AB-": "AB Negative (AB-)",
        "O+": "O Positive (O+)",
        "O-": "O Negative (O-)"
    ]

    /// Returns the formatted blood type display name
    var bloodTypeDisplayName: String? {
        guard let bloodType = bloodType else { return nil }
        // Try to match exact case first, then try uppercase
        return MedicalInfo.bloodTypeDisplayNames[bloodType] ??
               MedicalInfo.bloodTypeDisplayNames[bloodType.uppercased()]
    }
}

// MARK: - Member Contact

struct MemberContact: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let email: String?
    let phone: String?
    let relationship: String?
    let relationshipName: String?
    let address: String?
    let notes: String?
    let isEmergencyContact: Bool?
    let priority: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, relationship, address, notes, priority
        case relationshipName = "relationship_name"
        case isEmergencyContact = "is_emergency_contact"
    }
}

// MARK: - Member Document

struct MemberDocument: Codable, Identifiable, Hashable {
    let id: Int
    let documentType: String?
    let documentNumber: String?
    let issuingAuthority: String?
    let issuingCountry: String?
    let issuingState: String?
    let issueDate: String?
    let expiryDate: String?
    let isExpired: Bool?
    let daysUntilExpiry: Int?
    let status: String?
    let frontImageUrl: String?
    let backImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case documentType = "document_type"
        case documentNumber = "document_number"
        case issuingAuthority = "issuing_authority"
        case issuingCountry = "issuing_country"
        case issuingState = "issuing_state"
        case issueDate = "issue_date"
        case expiryDate = "expiry_date"
        case isExpired = "is_expired"
        case daysUntilExpiry = "days_until_expiry"
        case frontImageUrl = "front_image_url"
        case backImageUrl = "back_image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id might be Int or might be missing - handle both
        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        documentType = try container.decodeIfPresent(String.self, forKey: .documentType)
        documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
        issuingAuthority = try container.decodeIfPresent(String.self, forKey: .issuingAuthority)
        issuingCountry = try container.decodeIfPresent(String.self, forKey: .issuingCountry)
        issuingState = try container.decodeIfPresent(String.self, forKey: .issuingState)
        issueDate = try container.decodeIfPresent(String.self, forKey: .issueDate)
        expiryDate = try container.decodeIfPresent(String.self, forKey: .expiryDate)
        isExpired = try container.decodeIfPresent(Bool.self, forKey: .isExpired)
        // days_until_expiry comes as Double from API, convert to Int
        if let daysDouble = try? container.decodeIfPresent(Double.self, forKey: .daysUntilExpiry) {
            daysUntilExpiry = Int(daysDouble)
        } else {
            daysUntilExpiry = try? container.decodeIfPresent(Int.self, forKey: .daysUntilExpiry)
        }
        status = try container.decodeIfPresent(String.self, forKey: .status)
        frontImageUrl = try container.decodeIfPresent(String.self, forKey: .frontImageUrl)
        backImageUrl = try container.decodeIfPresent(String.self, forKey: .backImageUrl)
    }
}

// MARK: - Allergy

struct Allergy: Codable, Identifiable {
    let id: Int
    let allergenName: String?
    let severity: String?
    let severityColor: String?
    let reaction: String?

    enum CodingKeys: String, CodingKey {
        case id, severity, reaction
        case allergenName = "allergen_name"
        case severityColor = "severity_color"
    }
}

// MARK: - Medical Condition

struct MedicalCondition: Codable, Identifiable {
    let id: Int
    let name: String?
    let status: String?
    let statusColor: String?
    let diagnosedDate: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, notes
        case statusColor = "status_color"
        case diagnosedDate = "diagnosed_date"
    }
}

// MARK: - Healthcare Provider

struct HealthcareProvider: Codable, Identifiable {
    let id: Int
    let name: String?
    let providerType: String?
    let specialty: String?
    let phone: String?
    let email: String?
    let isPrimary: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, specialty, phone, email
        case providerType = "provider_type"
        case isPrimary = "is_primary"
    }
}

// MARK: - Family Member Medication

struct FamilyMemberMedication: Codable, Identifiable {
    let id: Int
    let name: String?
    let dosage: String?
    let frequency: String?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, dosage, frequency
        case isActive = "is_active"
    }
}

// MARK: - Member Education Document

struct MemberEducationDocument: Codable, Identifiable {
    let id: Int
    let documentType: String?
    let documentTypeName: String?
    let title: String?
    let description: String?
    let schoolYear: String?
    let gradeLevel: String?
    let filePath: String?
    let fileName: String?
    let fileSize: Int?
    let mimeType: String?
    let fileUrl: String?
    let formattedFileSize: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case documentType = "document_type"
        case documentTypeName = "document_type_name"
        case schoolYear = "school_year"
        case gradeLevel = "grade_level"
        case filePath = "file_path"
        case fileName = "file_name"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case fileUrl = "file_url"
        case formattedFileSize = "formatted_file_size"
        case createdAt = "created_at"
    }

    var displayTitle: String {
        title ?? documentTypeName ?? "Document"
    }

    var fileIcon: String {
        let mime = mimeType ?? ""
        if mime.contains("pdf") {
            return "doc.fill"
        } else if mime.contains("image") {
            return "photo.fill"
        } else if mime.contains("word") || mime.contains("document") {
            return "doc.text.fill"
        }
        return "doc.fill"
    }
}

// MARK: - Member School Info

struct MemberSchoolInfo: Codable, Identifiable {
    let id: Int
    let schoolName: String?
    let gradeLevel: String?
    let gradeLevelName: String?
    let schoolYear: String?
    let isCurrent: Bool?
    let startDate: String?
    let endDate: String?
    let studentId: String?
    let schoolAddress: String?
    let schoolPhone: String?
    let schoolEmail: String?
    let teacherName: String?
    let teacherEmail: String?
    let counselorName: String?
    let counselorEmail: String?
    let busNumber: String?
    let busPickupTime: String?
    let busDropoffTime: String?
    let notes: String?
    let documents: [MemberEducationDocument]?

    enum CodingKeys: String, CodingKey {
        case id, notes, documents
        case schoolName = "school_name"
        case gradeLevel = "grade_level"
        case gradeLevelName = "grade_level_name"
        case schoolYear = "school_year"
        case isCurrent = "is_current"
        case startDate = "start_date"
        case endDate = "end_date"
        case studentId = "student_id"
        case schoolAddress = "school_address"
        case schoolPhone = "school_phone"
        case schoolEmail = "school_email"
        case teacherName = "teacher_name"
        case teacherEmail = "teacher_email"
        case counselorName = "counselor_name"
        case counselorEmail = "counselor_email"
        case busNumber = "bus_number"
        case busPickupTime = "bus_pickup_time"
        case busDropoffTime = "bus_dropoff_time"
    }

    var displayGradeLevel: String {
        gradeLevelName ?? gradeLevel ?? ""
    }

    var formattedDateRange: String? {
        let start = startDate ?? ""
        let end = isCurrent == true ? "Present" : (endDate ?? "")
        if start.isEmpty && end.isEmpty {
            return schoolYear
        }
        if start.isEmpty {
            return end
        }
        if end.isEmpty {
            return start
        }
        return "\(start) - \(end)"
    }

    var hasBusInfo: Bool {
        busNumber != nil && !(busNumber?.isEmpty ?? true)
    }

    var hasTeacherInfo: Bool {
        teacherName != nil && !(teacherName?.isEmpty ?? true)
    }

    var hasCounselorInfo: Bool {
        counselorName != nil && !(counselorName?.isEmpty ?? true)
    }
}

// MARK: - Member Vaccination

struct MemberVaccination: Codable, Identifiable {
    let id: Int
    let vaccineType: String?
    let vaccineName: String?
    let customVaccineName: String?
    let vaccinationDate: String?
    let nextVaccinationDate: String?
    let administeredBy: String?
    let lotNumber: String?
    let notes: String?
    let isDue: Bool?
    let isComingSoon: Bool?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case vaccineType = "vaccine_type"
        case vaccineName = "vaccine_name"
        case customVaccineName = "custom_vaccine_name"
        case vaccinationDate = "vaccination_date"
        case nextVaccinationDate = "next_vaccination_date"
        case administeredBy = "administered_by"
        case lotNumber = "lot_number"
        case isDue = "is_due"
        case isComingSoon = "is_coming_soon"
    }

    var displayName: String {
        vaccineName ?? customVaccineName ?? vaccineType ?? "Unknown"
    }
}
