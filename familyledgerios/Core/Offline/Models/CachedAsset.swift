import SwiftData
import Foundation

@Model
final class CachedAsset {
    // Identifiers
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Basic info
    var name: String
    var imageUrl: String?
    var localImagePath: String?  // For offline-added images
    var assetCategory: String?
    var assetType: String?
    var assetDescription: String?
    var notes: String?

    // Valuation
    var acquisitionDate: Date?
    var purchaseValue: Double?
    var currentValue: Double?
    var currency: String?

    // Location
    var locationAddress: String?
    var locationCity: String?
    var locationState: String?
    var locationZip: String?
    var locationCountry: String?
    var storageLocation: String?
    var roomLocation: String?

    // Status
    var status: String?
    var ownershipType: String?

    // Insurance
    var isInsured: Bool
    var insuranceProvider: String?
    var insurancePolicyNumber: String?
    var insuranceRenewalDate: Date?

    // Vehicle-specific
    var vehicleMake: String?
    var vehicleModel: String?
    var vehicleYear: Int?
    var vinRegistration: String?
    var licensePlate: String?
    var mileage: Int?

    // Owners stored as JSON
    var ownersJSON: Data?

    // Sync metadata
    var syncStatus: String  // SyncStatus raw value
    var version: Int
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    init(
        serverId: Int? = nil,
        name: String,
        assetCategory: String? = nil,
        assetType: String? = nil,
        assetDescription: String? = nil
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.name = name
        self.assetCategory = assetCategory
        self.assetType = assetType
        self.assetDescription = assetDescription
        self.isInsured = false
        self.syncStatus = serverId != nil ? SyncStatus.synced.rawValue : SyncStatus.pendingCreate.rawValue
        self.version = 1
        self.localUpdatedAt = Date()
    }

    // MARK: - Computed Properties

    var currentSyncStatus: SyncStatus {
        SyncStatus(rawValue: syncStatus) ?? .synced
    }

    var isPendingSync: Bool {
        currentSyncStatus != .synced
    }

    var formattedCurrentValue: String? {
        guard let value = currentValue else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: NSNumber(value: value))
    }

    var formattedPurchaseValue: String? {
        guard let value = purchaseValue else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: NSNumber(value: value))
    }

    var fullLocation: String? {
        let components = [locationAddress, locationCity, locationState, locationZip, locationCountry]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    var isVehicle: Bool {
        assetCategory?.lowercased() == "vehicle" || assetType?.lowercased() == "vehicle"
    }

    // MARK: - Owners Handling

    var owners: [AssetOwner]? {
        guard let data = ownersJSON else { return nil }
        return try? JSONDecoder().decode([AssetOwner].self, from: data)
    }

    func setOwners(_ owners: [AssetOwner]) {
        self.ownersJSON = try? JSONEncoder().encode(owners)
    }

    // MARK: - Convert from API Model

    static func from(_ apiModel: Asset) -> CachedAsset {
        let cached = CachedAsset(
            serverId: apiModel.id,
            name: apiModel.name,
            assetCategory: apiModel.assetCategory,
            assetType: apiModel.assetType,
            assetDescription: apiModel.description
        )

        cached.imageUrl = apiModel.imageUrl
        cached.notes = apiModel.notes
        cached.purchaseValue = apiModel.purchaseValue
        cached.currentValue = apiModel.currentValue
        cached.currency = apiModel.currency
        cached.locationAddress = apiModel.locationAddress
        cached.locationCity = apiModel.locationCity
        cached.locationState = apiModel.locationState
        cached.locationZip = apiModel.locationZip
        cached.locationCountry = apiModel.locationCountry
        cached.storageLocation = apiModel.storageLocation
        cached.roomLocation = apiModel.roomLocation
        cached.status = apiModel.status
        cached.ownershipType = apiModel.ownershipType
        cached.isInsured = apiModel.isInsured ?? false
        cached.insuranceProvider = apiModel.insuranceProvider
        cached.insurancePolicyNumber = apiModel.insurancePolicyNumber
        cached.vehicleMake = apiModel.vehicleMake
        cached.vehicleModel = apiModel.vehicleModel
        cached.vehicleYear = apiModel.vehicleYear
        cached.vinRegistration = apiModel.vinRegistration
        cached.licensePlate = apiModel.licensePlate
        cached.mileage = apiModel.mileage
        cached.syncStatus = SyncStatus.synced.rawValue
        cached.lastSyncedAt = Date()

        // Parse acquisition date
        if let dateStr = apiModel.acquisitionDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            cached.acquisitionDate = formatter.date(from: dateStr)
        }

        // Parse insurance renewal date
        if let dateStr = apiModel.insuranceRenewalDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            cached.insuranceRenewalDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            cached.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }

        // Encode owners
        if let owners = apiModel.owners {
            cached.ownersJSON = try? JSONEncoder().encode(owners)
        }

        return cached
    }

    // MARK: - Convert to API Request

    func toCreateRequest() -> [String: Any] {
        var request: [String: Any] = [
            "name": name
        ]

        if let assetCategory = assetCategory { request["asset_category"] = assetCategory }
        if let assetType = assetType { request["asset_type"] = assetType }
        if let desc = assetDescription { request["description"] = desc }
        if let notes = notes { request["notes"] = notes }
        if let purchaseValue = purchaseValue { request["purchase_value"] = purchaseValue }
        if let currentValue = currentValue { request["current_value"] = currentValue }
        if let currency = currency { request["currency"] = currency }

        if let acquisitionDate = acquisitionDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            request["acquisition_date"] = formatter.string(from: acquisitionDate)
        }

        // Location
        if let locationAddress = locationAddress { request["location_address"] = locationAddress }
        if let locationCity = locationCity { request["location_city"] = locationCity }
        if let locationState = locationState { request["location_state"] = locationState }
        if let locationZip = locationZip { request["location_zip"] = locationZip }
        if let locationCountry = locationCountry { request["location_country"] = locationCountry }
        if let storageLocation = storageLocation { request["storage_location"] = storageLocation }
        if let roomLocation = roomLocation { request["room_location"] = roomLocation }

        // Status
        if let status = status { request["status"] = status }
        if let ownershipType = ownershipType { request["ownership_type"] = ownershipType }

        // Insurance
        request["is_insured"] = isInsured
        if let insuranceProvider = insuranceProvider { request["insurance_provider"] = insuranceProvider }
        if let insurancePolicyNumber = insurancePolicyNumber { request["insurance_policy_number"] = insurancePolicyNumber }
        if let insuranceRenewalDate = insuranceRenewalDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            request["insurance_renewal_date"] = formatter.string(from: insuranceRenewalDate)
        }

        // Vehicle
        if let vehicleMake = vehicleMake { request["vehicle_make"] = vehicleMake }
        if let vehicleModel = vehicleModel { request["vehicle_model"] = vehicleModel }
        if let vehicleYear = vehicleYear { request["vehicle_year"] = vehicleYear }
        if let vinRegistration = vinRegistration { request["vin_registration"] = vinRegistration }
        if let licensePlate = licensePlate { request["license_plate"] = licensePlate }
        if let mileage = mileage { request["mileage"] = mileage }

        return request
    }

    func toUpdateRequest() -> [String: Any] {
        var request = toCreateRequest()
        request["version"] = version
        return request
    }

    // MARK: - Update from Server

    func updateFromServer(_ apiModel: Asset) {
        self.name = apiModel.name
        self.imageUrl = apiModel.imageUrl
        self.assetCategory = apiModel.assetCategory
        self.assetType = apiModel.assetType
        self.assetDescription = apiModel.description
        self.notes = apiModel.notes
        self.purchaseValue = apiModel.purchaseValue
        self.currentValue = apiModel.currentValue
        self.currency = apiModel.currency
        self.locationAddress = apiModel.locationAddress
        self.locationCity = apiModel.locationCity
        self.locationState = apiModel.locationState
        self.locationZip = apiModel.locationZip
        self.locationCountry = apiModel.locationCountry
        self.storageLocation = apiModel.storageLocation
        self.roomLocation = apiModel.roomLocation
        self.status = apiModel.status
        self.ownershipType = apiModel.ownershipType
        self.isInsured = apiModel.isInsured ?? false
        self.insuranceProvider = apiModel.insuranceProvider
        self.insurancePolicyNumber = apiModel.insurancePolicyNumber
        self.vehicleMake = apiModel.vehicleMake
        self.vehicleModel = apiModel.vehicleModel
        self.vehicleYear = apiModel.vehicleYear
        self.vinRegistration = apiModel.vinRegistration
        self.licensePlate = apiModel.licensePlate
        self.mileage = apiModel.mileage
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let dateStr = apiModel.acquisitionDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.acquisitionDate = formatter.date(from: dateStr)
        }

        if let dateStr = apiModel.insuranceRenewalDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.insuranceRenewalDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }

        if let owners = apiModel.owners {
            self.ownersJSON = try? JSONEncoder().encode(owners)
        }
    }

    // MARK: - Mark for Sync

    func markAsUpdated() {
        self.syncStatus = SyncStatus.pendingUpdate.rawValue
        self.localUpdatedAt = Date()
    }

    func markAsDeleted() {
        self.syncStatus = SyncStatus.pendingDelete.rawValue
        self.localUpdatedAt = Date()
    }

    func markAsSynced(serverId: Int, version: Int) {
        self.serverId = serverId
        self.version = version
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()
    }

    // MARK: - Convenience Initializer from API Model

    convenience init(from apiModel: Asset) {
        self.init(
            serverId: apiModel.id,
            name: apiModel.name,
            assetCategory: apiModel.assetCategory,
            assetType: apiModel.assetType,
            assetDescription: apiModel.description
        )

        self.imageUrl = apiModel.imageUrl
        self.notes = apiModel.notes
        self.purchaseValue = apiModel.purchaseValue
        self.currentValue = apiModel.currentValue
        self.currency = apiModel.currency
        self.locationAddress = apiModel.locationAddress
        self.locationCity = apiModel.locationCity
        self.locationState = apiModel.locationState
        self.locationZip = apiModel.locationZip
        self.locationCountry = apiModel.locationCountry
        self.storageLocation = apiModel.storageLocation
        self.roomLocation = apiModel.roomLocation
        self.status = apiModel.status
        self.ownershipType = apiModel.ownershipType
        self.isInsured = apiModel.isInsured ?? false
        self.insuranceProvider = apiModel.insuranceProvider
        self.insurancePolicyNumber = apiModel.insurancePolicyNumber
        self.vehicleMake = apiModel.vehicleMake
        self.vehicleModel = apiModel.vehicleModel
        self.vehicleYear = apiModel.vehicleYear
        self.vinRegistration = apiModel.vinRegistration
        self.licensePlate = apiModel.licensePlate
        self.mileage = apiModel.mileage
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let dateStr = apiModel.acquisitionDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.acquisitionDate = formatter.date(from: dateStr)
        }

        if let dateStr = apiModel.insuranceRenewalDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.insuranceRenewalDate = formatter.date(from: dateStr)
        }

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }

        if let owners = apiModel.owners {
            self.ownersJSON = try? JSONEncoder().encode(owners)
        }
    }

    // MARK: - Convert to API Model

    func toAsset() -> Asset {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return Asset(
            id: serverId ?? 0,
            name: name,
            imageUrl: imageUrl,
            assetCategory: assetCategory,
            assetType: assetType,
            description: assetDescription,
            notes: notes,
            acquisitionDate: acquisitionDate.map { dateFormatter.string(from: $0) },
            purchaseValue: purchaseValue,
            currentValue: currentValue,
            currency: currency,
            formattedCurrentValue: formattedCurrentValue,
            locationAddress: locationAddress,
            locationCity: locationCity,
            locationState: locationState,
            locationZip: locationZip,
            locationCountry: locationCountry,
            storageLocation: storageLocation,
            roomLocation: roomLocation,
            status: status,
            statusColor: nil,
            ownershipType: ownershipType,
            isInsured: isInsured,
            insuranceProvider: insuranceProvider,
            insurancePolicyNumber: insurancePolicyNumber,
            insuranceRenewalDate: insuranceRenewalDate.map { dateFormatter.string(from: $0) },
            vehicleMake: vehicleMake,
            vehicleModel: vehicleModel,
            vehicleYear: vehicleYear,
            vinRegistration: vinRegistration,
            licensePlate: licensePlate,
            mileage: mileage,
            createdAt: nil,
            updatedAt: serverUpdatedAt.map { ISO8601DateFormatter().string(from: $0) },
            owners: owners,
            documentsCount: nil
        )
    }

    // MARK: - Update from API Model (alias for updateFromServer)

    func update(from apiModel: Asset) {
        updateFromServer(apiModel)
    }
}
