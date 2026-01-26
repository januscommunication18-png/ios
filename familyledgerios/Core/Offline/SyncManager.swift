import SwiftData
import Foundation
import UIKit

@Observable
@MainActor
final class SyncManager {
    static let shared = SyncManager()

    // Dependencies
    private let networkMonitor = NetworkMonitor.shared
    private let outboxManager = OutboxManager.shared
    private let apiClient = APIClient.shared

    // State
    private(set) var isSyncing: Bool = false
    private(set) var lastSyncAt: Date?
    private(set) var lastSyncError: String?
    private(set) var conflictCount: Int = 0

    var pendingCount: Int { outboxManager.pendingCount }
    var isOnline: Bool { networkMonitor.isConnected }
    var hasConflicts: Bool { conflictCount > 0 }

    // Configuration
    private let deviceId: String
    private let deviceName: String

    private var context: ModelContext {
        OfflineDataContainer.shared.context
    }

    private init() {
        // Generate unique device ID
        if let storedId = UserDefaults.standard.string(forKey: "sync_device_id") {
            self.deviceId = storedId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "sync_device_id")
            self.deviceId = newId
        }

        self.deviceName = UIDevice.current.name

        // Load last sync time
        if let timestamp = UserDefaults.standard.object(forKey: "last_sync_at") as? Date {
            self.lastSyncAt = timestamp
        }

        // Setup network change observer
        setupNetworkObserver()
    }

    // MARK: - Setup

    private func setupNetworkObserver() {
        NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let isConnected = notification.userInfo?["isConnected"] as? Bool,
                  isConnected else { return }

            // Auto-sync when network becomes available
            Task { @MainActor in
                await self?.syncIfNeeded()
            }
        }
    }

    // MARK: - Public Sync Methods

    /// Sync if there are pending operations and we're online
    func syncIfNeeded() async {
        guard isOnline, pendingCount > 0, !isSyncing else { return }
        await performSync()
    }

    /// Force sync now
    func syncNow() async {
        guard isOnline, !isSyncing else { return }
        await performSync()
    }

    /// Pull changes from server
    func pullChanges() async throws {
        guard isOnline else {
            throw SyncError.offline
        }

        let entities = ["shopping_lists", "shopping_items", "goals", "goal_tasks", "assets"]
        let lastSync = lastSyncAt?.ISO8601Format() ?? ""

        let response: SyncPullResponse = try await apiClient.request(
            .syncPull(lastSyncAt: lastSync, deviceId: deviceId, entities: entities)
        )

        if response.success {
            try await processPullResponse(response.data)
            saveLastSyncTime()
        }
    }

    // MARK: - Private Sync Methods

    private func performSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        lastSyncError = nil

        do {
            // 1. Push local changes
            try await pushChanges()

            // 2. Pull server changes
            try await pullChanges()

            // 3. Save sync time
            saveLastSyncTime()

            NotificationCenter.default.post(name: .syncCompleted, object: nil)
            print("[SyncManager] Sync completed successfully")

        } catch {
            lastSyncError = error.localizedDescription
            NotificationCenter.default.post(
                name: .syncFailed,
                object: nil,
                userInfo: ["error": error.localizedDescription]
            )
            print("[SyncManager] Sync failed: \(error)")
        }

        isSyncing = false
    }

    private func pushChanges() async throws {
        let operations = outboxManager.getPendingOperations()
        guard !operations.isEmpty else { return }

        let syncOperations = operations.map { $0.toSyncOperation() }

        let request = SyncPushRequest(
            deviceId: deviceId,
            deviceName: deviceName,
            operations: syncOperations
        )

        let response: SyncPushResponse = try await apiClient.request(
            .syncPush,
            body: request
        )

        // Process results
        for result in response.results {
            guard let operation = operations.first(where: { $0.localEntityId == result.localId }) else {
                continue
            }

            switch result.status {
            case "created", "updated", "deleted", "toggled":
                // Success - update local entity and remove operation
                try await handleSuccessResult(result, operation: operation)
                outboxManager.removeOperation(operation)

            case "conflict":
                // Conflict detected
                try await handleConflictResult(result, operation: operation)
                conflictCount += 1

            case "error":
                // Error - mark for retry or remove if max retries exceeded
                if operation.canRetry {
                    outboxManager.markOperationFailed(operation, error: result.error ?? "Unknown error")
                } else {
                    outboxManager.removeOperation(operation)
                }

            default:
                break
            }
        }
    }

    private func handleSuccessResult(_ result: SyncOperationResult, operation: PendingOperation) async throws {
        guard let localUUID = operation.localUUID,
              let entityType = operation.currentEntityType else { return }

        let serverId = result.serverId ?? operation.serverEntityId ?? 0
        let version = result.version ?? 1

        switch entityType {
        case .shoppingList:
            if let cached = try? fetchCachedShoppingList(localId: localUUID) {
                cached.markAsSynced(serverId: serverId, version: version)
            }

        case .shoppingItem:
            if let cached = try? fetchCachedShoppingItem(localId: localUUID) {
                cached.markAsSynced(serverId: serverId, version: version)
            }

        case .goal:
            if let cached = try? fetchCachedGoal(localId: localUUID) {
                cached.markAsSynced(serverId: serverId, version: version)
            }

        case .goalTask:
            if let cached = try? fetchCachedGoalTask(localId: localUUID) {
                cached.markAsSynced(serverId: serverId, version: version)
            }

        case .asset:
            if let cached = try? fetchCachedAsset(localId: localUUID) {
                cached.markAsSynced(serverId: serverId, version: version)
            }
        }

        try context.save()
    }

    private func handleConflictResult(_ result: SyncOperationResult, operation: PendingOperation) async throws {
        // Store conflict for resolution
        // In a full implementation, you'd store this and show UI
        print("[SyncManager] Conflict detected for \(operation.entityType): \(operation.localEntityId)")

        NotificationCenter.default.post(
            name: .conflictDetected,
            object: nil,
            userInfo: [
                "entityType": operation.entityType,
                "localId": operation.localEntityId,
                "serverData": result
            ]
        )
    }

    private func processPullResponse(_ changes: SyncChanges) async throws {
        // Process updated entities
        if let updated = changes.updated {
            for (entityType, records) in updated {
                try await processUpdatedRecords(entityType: entityType, records: records)
            }
        }

        // Process deleted entities
        if let deleted = changes.deleted {
            for (entityType, ids) in deleted {
                try await processDeletedRecords(entityType: entityType, ids: ids)
            }
        }

        try context.save()
    }

    private func processUpdatedRecords(entityType: String, records: [[String: AnyCodable]]) async throws {
        for record in records {
            guard let idValue = record["id"]?.value as? Int else { continue }

            switch entityType {
            case "shopping_lists":
                try await upsertShoppingList(from: record, serverId: idValue)

            case "shopping_items":
                try await upsertShoppingItem(from: record, serverId: idValue)

            case "goals":
                try await upsertGoal(from: record, serverId: idValue)

            case "goal_tasks":
                try await upsertGoalTask(from: record, serverId: idValue)

            case "assets":
                try await upsertAsset(from: record, serverId: idValue)

            default:
                break
            }
        }
    }

    private func processDeletedRecords(entityType: String, ids: [Int]) async throws {
        for id in ids {
            switch entityType {
            case "shopping_lists":
                if let cached = try? fetchCachedShoppingList(serverId: id) {
                    context.delete(cached)
                }

            case "shopping_items":
                if let cached = try? fetchCachedShoppingItem(serverId: id) {
                    context.delete(cached)
                }

            case "goals":
                if let cached = try? fetchCachedGoal(serverId: id) {
                    context.delete(cached)
                }

            case "goal_tasks":
                if let cached = try? fetchCachedGoalTask(serverId: id) {
                    context.delete(cached)
                }

            case "assets":
                if let cached = try? fetchCachedAsset(serverId: id) {
                    context.delete(cached)
                }

            default:
                break
            }
        }
    }

    // MARK: - Upsert Methods

    private func upsertShoppingList(from record: [String: AnyCodable], serverId: Int) async throws {
        let name = record["name"]?.value as? String ?? ""

        if let existing = try? fetchCachedShoppingList(serverId: serverId) {
            // Update existing if not locally modified
            if existing.currentSyncStatus == .synced {
                existing.name = name
                existing.listDescription = record["description"]?.value as? String
                existing.storeName = record["store_name"]?.value as? String
                existing.color = record["color"]?.value as? String
                existing.icon = record["icon"]?.value as? String
                existing.isDefault = record["is_default"]?.value as? Bool ?? false
                existing.version = record["version"]?.value as? Int ?? existing.version
                existing.lastSyncedAt = Date()
            }
        } else {
            // Create new
            let cached = CachedShoppingList(
                serverId: serverId,
                name: name,
                listDescription: record["description"]?.value as? String,
                storeName: record["store_name"]?.value as? String,
                color: record["color"]?.value as? String,
                icon: record["icon"]?.value as? String,
                isDefault: record["is_default"]?.value as? Bool ?? false
            )
            cached.version = record["version"]?.value as? Int ?? 1
            cached.syncStatus = SyncStatus.synced.rawValue
            cached.lastSyncedAt = Date()
            context.insert(cached)
        }
    }

    private func upsertShoppingItem(from record: [String: AnyCodable], serverId: Int) async throws {
        let name = record["name"]?.value as? String ?? ""

        if let existing = try? fetchCachedShoppingItem(serverId: serverId) {
            if existing.currentSyncStatus == .synced {
                existing.name = name
                existing.quantity = record["quantity"]?.value as? Int ?? 1
                existing.unit = record["unit"]?.value as? String
                existing.category = record["category"]?.value as? String
                existing.isChecked = record["is_checked"]?.value as? Bool ?? false
                existing.price = record["price"]?.value as? Double
                existing.notes = record["notes"]?.value as? String
                existing.priority = record["priority"]?.value as? String
                existing.version = record["version"]?.value as? Int ?? existing.version
                existing.lastSyncedAt = Date()
            }
        } else {
            let cached = CachedShoppingItem(
                serverId: serverId,
                name: name,
                quantity: record["quantity"]?.value as? Int ?? 1,
                unit: record["unit"]?.value as? String,
                category: record["category"]?.value as? String,
                isChecked: record["is_checked"]?.value as? Bool ?? false,
                price: record["price"]?.value as? Double,
                notes: record["notes"]?.value as? String,
                priority: record["priority"]?.value as? String,
                shoppingListServerId: record["shopping_list_id"]?.value as? Int
            )
            cached.version = record["version"]?.value as? Int ?? 1
            cached.syncStatus = SyncStatus.synced.rawValue
            cached.lastSyncedAt = Date()
            context.insert(cached)
        }
    }

    private func upsertGoal(from record: [String: AnyCodable], serverId: Int) async throws {
        let title = record["title"]?.value as? String ?? ""

        if let existing = try? fetchCachedGoal(serverId: serverId) {
            if existing.currentSyncStatus == .synced {
                existing.title = title
                existing.goalDescription = record["description"]?.value as? String
                existing.progress = record["progress"]?.value as? Int ?? 0
                existing.status = record["status"]?.value as? String
                existing.priority = record["priority"]?.value as? String
                existing.category = record["category"]?.value as? String
                existing.goalType = record["goal_type"]?.value as? String
                existing.version = record["version"]?.value as? Int ?? existing.version
                existing.lastSyncedAt = Date()
            }
        } else {
            let cached = CachedGoal(
                serverId: serverId,
                title: title,
                goalDescription: record["description"]?.value as? String,
                status: record["status"]?.value as? String,
                priority: record["priority"]?.value as? String
            )
            cached.progress = record["progress"]?.value as? Int ?? 0
            cached.category = record["category"]?.value as? String
            cached.goalType = record["goal_type"]?.value as? String
            cached.version = record["version"]?.value as? Int ?? 1
            cached.syncStatus = SyncStatus.synced.rawValue
            cached.lastSyncedAt = Date()
            context.insert(cached)
        }
    }

    private func upsertGoalTask(from record: [String: AnyCodable], serverId: Int) async throws {
        let title = record["title"]?.value as? String ?? ""

        if let existing = try? fetchCachedGoalTask(serverId: serverId) {
            if existing.currentSyncStatus == .synced {
                existing.title = title
                existing.taskDescription = record["description"]?.value as? String
                existing.status = record["status"]?.value as? String
                existing.priority = record["priority"]?.value as? String
                existing.version = record["version"]?.value as? Int ?? existing.version
                existing.lastSyncedAt = Date()
            }
        } else {
            let cached = CachedGoalTask(
                serverId: serverId,
                title: title,
                taskDescription: record["description"]?.value as? String,
                status: record["status"]?.value as? String,
                priority: record["priority"]?.value as? String,
                goalServerId: record["goal_id"]?.value as? Int
            )
            cached.version = record["version"]?.value as? Int ?? 1
            cached.syncStatus = SyncStatus.synced.rawValue
            cached.lastSyncedAt = Date()
            context.insert(cached)
        }
    }

    private func upsertAsset(from record: [String: AnyCodable], serverId: Int) async throws {
        let name = record["name"]?.value as? String ?? ""

        if let existing = try? fetchCachedAsset(serverId: serverId) {
            if existing.currentSyncStatus == .synced {
                existing.name = name
                existing.assetDescription = record["description"]?.value as? String
                existing.assetCategory = record["asset_category"]?.value as? String
                existing.assetType = record["asset_type"]?.value as? String
                existing.currentValue = record["current_value"]?.value as? Double
                existing.purchaseValue = record["purchase_value"]?.value as? Double
                existing.status = record["status"]?.value as? String
                existing.version = record["version"]?.value as? Int ?? existing.version
                existing.lastSyncedAt = Date()
            }
        } else {
            let cached = CachedAsset(
                serverId: serverId,
                name: name,
                assetCategory: record["asset_category"]?.value as? String,
                assetType: record["asset_type"]?.value as? String,
                assetDescription: record["description"]?.value as? String
            )
            cached.currentValue = record["current_value"]?.value as? Double
            cached.purchaseValue = record["purchase_value"]?.value as? Double
            cached.status = record["status"]?.value as? String
            cached.version = record["version"]?.value as? Int ?? 1
            cached.syncStatus = SyncStatus.synced.rawValue
            cached.lastSyncedAt = Date()
            context.insert(cached)
        }
    }

    // MARK: - Fetch Helpers

    private func fetchCachedShoppingList(localId: UUID) throws -> CachedShoppingList? {
        let localIdString = localId.uuidString
        let descriptor = FetchDescriptor<CachedShoppingList>(
            predicate: #Predicate { $0.localId == localId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedShoppingList(serverId: Int) throws -> CachedShoppingList? {
        let descriptor = FetchDescriptor<CachedShoppingList>(
            predicate: #Predicate { $0.serverId == serverId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedShoppingItem(localId: UUID) throws -> CachedShoppingItem? {
        let descriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate { $0.localId == localId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedShoppingItem(serverId: Int) throws -> CachedShoppingItem? {
        let descriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate { $0.serverId == serverId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedGoal(localId: UUID) throws -> CachedGoal? {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.localId == localId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedGoal(serverId: Int) throws -> CachedGoal? {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.serverId == serverId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedGoalTask(localId: UUID) throws -> CachedGoalTask? {
        let descriptor = FetchDescriptor<CachedGoalTask>(
            predicate: #Predicate { $0.localId == localId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedGoalTask(serverId: Int) throws -> CachedGoalTask? {
        let descriptor = FetchDescriptor<CachedGoalTask>(
            predicate: #Predicate { $0.serverId == serverId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedAsset(localId: UUID) throws -> CachedAsset? {
        let descriptor = FetchDescriptor<CachedAsset>(
            predicate: #Predicate { $0.localId == localId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCachedAsset(serverId: Int) throws -> CachedAsset? {
        let descriptor = FetchDescriptor<CachedAsset>(
            predicate: #Predicate { $0.serverId == serverId }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - Helpers

    private func saveLastSyncTime() {
        lastSyncAt = Date()
        UserDefaults.standard.set(lastSyncAt, forKey: "last_sync_at")
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case offline
    case unauthorized
    case serverError(String)
    case conflict(String)

    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection"
        case .unauthorized:
            return "Authentication required"
        case .serverError(let message):
            return message
        case .conflict(let message):
            return "Sync conflict: \(message)"
        }
    }
}
