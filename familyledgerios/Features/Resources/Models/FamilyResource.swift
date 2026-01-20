import Foundation

struct FamilyResource: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let documentType: String?
    let documentTypeName: String?
    let customDocumentType: String?
    let description: String?
    let originalLocation: String?
    let status: String?
    let statusName: String?
    let digitalCopyDate: String?
    let digitalCopyDateRaw: String?
    let expirationDate: String?
    let expirationDateRaw: String?
    let isExpired: Bool?
    let notes: String?
    let files: [ResourceFile]?
    let filesCount: Int?
    let createdBy: ResourceCreator?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, status, files, notes
        case documentType = "document_type"
        case documentTypeName = "document_type_name"
        case customDocumentType = "custom_document_type"
        case originalLocation = "original_location"
        case statusName = "status_name"
        case digitalCopyDate = "digital_copy_date"
        case digitalCopyDateRaw = "digital_copy_date_raw"
        case expirationDate = "expiration_date"
        case expirationDateRaw = "expiration_date_raw"
        case isExpired = "is_expired"
        case filesCount = "files_count"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func == (lhs: FamilyResource, rhs: FamilyResource) -> Bool { lhs.id == rhs.id }

    var iconName: String {
        switch documentType {
        case "emergency": return "exclamationmark.triangle.fill"
        case "evacuation_plan": return "door.left.hand.open"
        case "fire_extinguisher": return "flame.fill"
        case "rental_agreement": return "house.fill"
        case "home_warranty": return "shield.checkered"
        default: return "folder.fill"
        }
    }

    var totalFilesCount: Int {
        filesCount ?? files?.count ?? 0
    }
}

struct ResourceFile: Codable, Identifiable {
    let id: Int
    let name: String?
    let originalName: String?
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
        case originalName = "original_name"
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

    var displayName: String {
        name ?? originalName ?? "File"
    }
}

struct ResourceCreator: Codable {
    let id: Int
    let name: String
}

struct ResourceCounts: Codable {
    let total: Int?
    let emergency: Int?
    let evacuation: Int?
    let fire: Int?
    let rental: Int?
    let warranty: Int?
    let other: Int?
}

struct ResourcesResponse: Codable {
    let resources: [FamilyResource]?
    let counts: ResourceCounts?
    let total: Int?
}

struct FamilyResourcesResponse: Codable {
    let familyResources: [FamilyResource]?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case familyResources = "family_resources"
        case total
    }
}

struct ResourceDetailStats: Codable {
    let totalFiles: Int?
    let images: Int?
    let documents: Int?

    enum CodingKeys: String, CodingKey {
        case totalFiles = "total_files"
        case images, documents
    }
}

struct ResourceDetailResponse: Codable {
    let resource: FamilyResource?
    let files: [ResourceFile]?
    let stats: ResourceDetailStats?
}
