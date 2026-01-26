import SwiftData
import Foundation

@Model
final class CachedShoppingList {
    // Identifiers
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Data
    var name: String
    var listDescription: String?
    var storeName: String?
    var color: String?
    var icon: String?
    var isDefault: Bool

    // Sync metadata
    var syncStatus: String  // SyncStatus raw value
    var version: Int
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \CachedShoppingItem.shoppingList)
    var items: [CachedShoppingItem]?

    init(
        serverId: Int? = nil,
        name: String,
        listDescription: String? = nil,
        storeName: String? = nil,
        color: String? = nil,
        icon: String? = nil,
        isDefault: Bool = false
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.name = name
        self.listDescription = listDescription
        self.storeName = storeName
        self.color = color
        self.icon = icon
        self.isDefault = isDefault
        self.syncStatus = serverId != nil ? SyncStatus.synced.rawValue : SyncStatus.pendingCreate.rawValue
        self.version = 1
        self.localUpdatedAt = Date()
    }

    // MARK: - Computed Properties

    var itemsCount: Int { items?.count ?? 0 }
    var purchasedCount: Int { items?.filter { $0.isChecked }.count ?? 0 }
    var uncheckedCount: Int { itemsCount - purchasedCount }

    var progressPercentage: Double {
        guard itemsCount > 0 else { return 0 }
        return Double(purchasedCount) / Double(itemsCount) * 100
    }

    var currentSyncStatus: SyncStatus {
        SyncStatus(rawValue: syncStatus) ?? .synced
    }

    var isPendingSync: Bool {
        currentSyncStatus != .synced
    }

    // MARK: - Convert from API Model

    static func from(_ apiModel: ShoppingList) -> CachedShoppingList {
        let cached = CachedShoppingList(
            serverId: apiModel.id,
            name: apiModel.name,
            listDescription: apiModel.description,
            storeName: apiModel.storeName,
            color: apiModel.color,
            icon: apiModel.icon,
            isDefault: apiModel.isDefault ?? false
        )
        cached.syncStatus = SyncStatus.synced.rawValue
        cached.lastSyncedAt = Date()

        if let updatedAt = apiModel.updatedAt {
            cached.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }

        return cached
    }

    // MARK: - Convert to API Request

    func toCreateRequest() -> [String: Any] {
        var request: [String: Any] = [
            "name": name
        ]
        if let desc = listDescription { request["description"] = desc }
        if let store = storeName { request["store_name"] = store }
        if let color = color { request["color"] = color }
        if let icon = icon { request["icon"] = icon }
        request["is_default"] = isDefault
        return request
    }

    func toUpdateRequest() -> [String: Any] {
        var request = toCreateRequest()
        request["version"] = version
        return request
    }

    // MARK: - Update from Server

    func updateFromServer(_ apiModel: ShoppingList) {
        self.name = apiModel.name
        self.listDescription = apiModel.description
        self.storeName = apiModel.storeName
        self.color = apiModel.color
        self.icon = apiModel.icon
        self.isDefault = apiModel.isDefault ?? false
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
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
}
