import Foundation

struct Asset: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let imageUrl: String?
    let assetCategory: String?
    let assetType: String?
    let description: String?
    let notes: String?

    // Valuation
    let acquisitionDate: String?
    let purchaseValueRaw: StringOrDouble?
    let currentValueRaw: StringOrDouble?
    let currency: String?
    let formattedCurrentValue: String?

    // Computed properties for numeric values
    var purchaseValue: Double? { purchaseValueRaw?.doubleValue }
    var currentValue: Double? { currentValueRaw?.doubleValue }

    // Location
    let locationAddress: String?
    let locationCity: String?
    let locationState: String?
    let locationZip: String?
    let locationCountry: String?
    let storageLocation: String?
    let roomLocation: String?

    // Status
    let status: String?
    let statusColor: String?
    let ownershipType: String?

    // Insurance
    let isInsured: Bool?
    let insuranceProvider: String?
    let insurancePolicyNumber: String?
    let insuranceRenewalDate: String?

    // Vehicle-specific
    let vehicleMake: String?
    let vehicleModel: String?
    let vehicleYear: Int?
    let vinRegistration: String?
    let licensePlate: String?
    let mileage: Int?

    // Timestamps
    let createdAt: String?
    let updatedAt: String?

    // Relations
    let owners: [AssetOwner]?
    let documentsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description, notes, currency, status, mileage, owners
        case imageUrl = "image_url"
        case assetCategory = "asset_category"
        case assetType = "asset_type"
        case acquisitionDate = "acquisition_date"
        case purchaseValueRaw = "purchase_value"
        case currentValueRaw = "current_value"
        case formattedCurrentValue = "formatted_current_value"
        case locationAddress = "location_address"
        case locationCity = "location_city"
        case locationState = "location_state"
        case locationZip = "location_zip"
        case locationCountry = "location_country"
        case storageLocation = "storage_location"
        case roomLocation = "room_location"
        case statusColor = "status_color"
        case ownershipType = "ownership_type"
        case isInsured = "is_insured"
        case insuranceProvider = "insurance_provider"
        case insurancePolicyNumber = "insurance_policy_number"
        case insuranceRenewalDate = "insurance_renewal_date"
        case vehicleMake = "vehicle_make"
        case vehicleModel = "vehicle_model"
        case vehicleYear = "vehicle_year"
        case vinRegistration = "vin_registration"
        case licensePlate = "license_plate"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case documentsCount = "documents_count"
    }

    static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }
}

struct AssetOwner: Codable, Identifiable {
    let id: Int
    let familyMemberId: Int?
    let ownerName: String?
    let ownerEmail: String?
    let ownerPhone: String?
    let ownershipPercentageRaw: StringOrDouble?
    let formattedOwnershipPercentage: String?
    let isPrimaryOwner: Bool?
    let isFamilyMember: Bool?
    let isExternalOwner: Bool?

    var ownershipPercentage: Double? { ownershipPercentageRaw?.doubleValue }

    enum CodingKeys: String, CodingKey {
        case id
        case familyMemberId = "family_member_id"
        case ownerName = "owner_name"
        case ownerEmail = "owner_email"
        case ownerPhone = "owner_phone"
        case ownershipPercentageRaw = "ownership_percentage"
        case formattedOwnershipPercentage = "formatted_ownership_percentage"
        case isPrimaryOwner = "is_primary_owner"
        case isFamilyMember = "is_family_member"
        case isExternalOwner = "is_external_owner"
    }
}

struct AssetsResponse: Codable {
    let assets: [Asset]?
    let total: Int?
    let totalValueRaw: StringOrDouble?
    let formattedTotalValue: String?

    var totalValue: Double? { totalValueRaw?.doubleValue }

    enum CodingKeys: String, CodingKey {
        case assets, total
        case totalValueRaw = "total_value"
        case formattedTotalValue = "formatted_total_value"
    }
}

struct AssetFile: Codable, Identifiable {
    let id: Int
    let name: String
    let documentType: String?
    let documentTypeName: String?
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
        case documentType = "document_type"
        case documentTypeName = "document_type_name"
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

struct AssetDetailResponse: Codable {
    let asset: Asset
    let files: [AssetFile]?
}
