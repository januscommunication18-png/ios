import Foundation

struct LegalDocument: Codable, Identifiable {
    let id: Int
    let name: String?
    let documentType: String?
    let documentTypeName: String?
    let status: String?
    let statusName: String?
    let statusColor: String?
    let originalLocation: String?
    let digitalCopyDate: String?
    let executionDate: String?
    let expirationDate: String?
    let isExpired: Bool?
    let isExpiringSoon: Bool?
    let attorneyName: String?
    let attorneyPhone: String?
    let attorneyEmail: String?
    let attorneyFirm: String?
    let notes: String?
    let files: [LegalDocumentFile]?
    let filesCount: Int?
    let familyCircleId: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, notes, files
        case documentType = "document_type"
        case documentTypeName = "document_type_name"
        case statusName = "status_name"
        case statusColor = "status_color"
        case originalLocation = "original_location"
        case digitalCopyDate = "digital_copy_date"
        case executionDate = "execution_date"
        case expirationDate = "expiration_date"
        case isExpired = "is_expired"
        case isExpiringSoon = "is_expiring_soon"
        case attorneyName = "attorney_name"
        case attorneyPhone = "attorney_phone"
        case attorneyEmail = "attorney_email"
        case attorneyFirm = "attorney_firm"
        case filesCount = "files_count"
        case familyCircleId = "family_circle_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var iconName: String {
        switch documentType {
        case "will": return "doc.text.fill"
        case "trust": return "building.columns.fill"
        case "power_of_attorney": return "person.badge.key.fill"
        case "medical_directive": return "stethoscope"
        default: return "doc.fill"
        }
    }

    var formattedExecutionDate: String? {
        guard let dateString = executionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return nil }
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct LegalDocumentFile: Codable, Identifiable {
    let id: Int
    let name: String
    let filePath: String?
    let mimeType: String?
    let fileSize: Int?
    let formattedSize: String?
    let isImage: Bool?
    let isPdf: Bool?
    let downloadUrl: String?
    let viewUrl: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case filePath = "file_path"
        case mimeType = "mime_type"
        case fileSize = "file_size"
        case formattedSize = "formatted_size"
        case isImage = "is_image"
        case isPdf = "is_pdf"
        case downloadUrl = "download_url"
        case viewUrl = "view_url"
        case createdAt = "created_at"
    }
}

struct LegalDocumentsResponse: Codable {
    let legalDocuments: [LegalDocument]?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case legalDocuments = "legal_documents"
        case total
    }
}

struct LegalDocumentDetailResponse: Codable {
    let legalDocument: LegalDocument?
    let files: [LegalDocumentFile]?
    let familyCircle: LegalDocumentCircle?

    enum CodingKeys: String, CodingKey {
        case legalDocument = "legal_document"
        case files
        case familyCircle = "family_circle"
    }
}

struct LegalDocumentCircle: Codable {
    let id: Int
    let name: String
}
