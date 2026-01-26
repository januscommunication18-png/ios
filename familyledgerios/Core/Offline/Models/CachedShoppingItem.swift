import SwiftData
import Foundation

@Model
final class CachedShoppingItem {
    // Identifiers
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Data
    var name: String
    var quantity: Int
    var unit: String?
    var category: String?
    var isChecked: Bool
    var price: Double?
    var notes: String?
    var priority: String?

    // Parent reference
    var shoppingListServerId: Int?

    // Sync metadata
    var syncStatus: String  // SyncStatus raw value
    var version: Int
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Relationship
    var shoppingList: CachedShoppingList?

    init(
        serverId: Int? = nil,
        name: String,
        quantity: Int = 1,
        unit: String? = nil,
        category: String? = nil,
        isChecked: Bool = false,
        price: Double? = nil,
        notes: String? = nil,
        priority: String? = nil,
        shoppingListServerId: Int? = nil
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.price = price
        self.notes = notes
        self.priority = priority
        self.shoppingListServerId = shoppingListServerId
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

    var isPurchased: Bool { isChecked }

    // MARK: - Convert from API Model

    static func from(_ apiModel: ShoppingItem, listServerId: Int?) -> CachedShoppingItem {
        let cached = CachedShoppingItem(
            serverId: apiModel.id,
            name: apiModel.name,
            quantity: apiModel.quantity ?? 1,
            unit: apiModel.unit,
            category: apiModel.category,
            isChecked: apiModel.isChecked ?? apiModel.isPurchased ?? false,
            price: apiModel.price,
            notes: apiModel.notes,
            priority: apiModel.priority,
            shoppingListServerId: listServerId
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
            "name": name,
            "quantity": quantity,
            "is_checked": isChecked
        ]
        if let unit = unit { request["unit"] = unit }
        if let category = category { request["category"] = category }
        if let price = price { request["price"] = price }
        if let notes = notes { request["notes"] = notes }
        if let priority = priority { request["priority"] = priority }
        return request
    }

    func toUpdateRequest() -> [String: Any] {
        var request = toCreateRequest()
        request["version"] = version
        return request
    }

    // MARK: - Update from Server

    func updateFromServer(_ apiModel: ShoppingItem) {
        self.name = apiModel.name
        self.quantity = apiModel.quantity ?? 1
        self.unit = apiModel.unit
        self.category = apiModel.category
        self.isChecked = apiModel.isChecked ?? apiModel.isPurchased ?? false
        self.price = apiModel.price
        self.notes = apiModel.notes
        self.priority = apiModel.priority
        self.syncStatus = SyncStatus.synced.rawValue
        self.lastSyncedAt = Date()

        if let updatedAt = apiModel.updatedAt {
            self.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }
    }

    // MARK: - Toggle

    func toggle() {
        self.isChecked.toggle()
        self.syncStatus = SyncStatus.pendingUpdate.rawValue
        self.localUpdatedAt = Date()
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
