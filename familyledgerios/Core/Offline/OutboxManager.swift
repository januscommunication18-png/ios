import SwiftData
import Foundation

@Observable
@MainActor
final class OutboxManager {
    static let shared = OutboxManager()

    private var context: ModelContext {
        OfflineDataContainer.shared.context
    }

    private(set) var pendingCount: Int = 0
    private(set) var lastError: String?

    private init() {
        updatePendingCount()
    }

    // MARK: - Queue Operations

    /// Queue a CREATE operation
    func queueCreate(
        entityType: SyncEntityType,
        localEntityId: UUID,
        endpoint: String,
        payload: [String: Any],
        parentServerId: Int? = nil
    ) throws {
        let operation = PendingOperation(
            operationType: .create,
            entityType: entityType,
            localEntityId: localEntityId,
            endpoint: endpoint,
            httpMethod: "POST",
            parentServerId: parentServerId
        )

        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        operation.requestPayload = jsonData

        context.insert(operation)
        try context.save()
        updatePendingCount()

        print("[OutboxManager] Queued CREATE for \(entityType.rawValue): \(localEntityId)")
    }

    /// Queue an UPDATE operation
    func queueUpdate(
        entityType: SyncEntityType,
        localEntityId: UUID,
        serverId: Int,
        endpoint: String,
        payload: [String: Any]
    ) throws {
        // Remove any existing pending operations for this entity
        removeExistingOperations(for: localEntityId)

        let operation = PendingOperation(
            operationType: .update,
            entityType: entityType,
            localEntityId: localEntityId,
            endpoint: endpoint,
            httpMethod: "PUT",
            serverEntityId: serverId
        )

        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        operation.requestPayload = jsonData

        context.insert(operation)
        try context.save()
        updatePendingCount()

        print("[OutboxManager] Queued UPDATE for \(entityType.rawValue): \(serverId)")
    }

    /// Queue a DELETE operation
    func queueDelete(
        entityType: SyncEntityType,
        localEntityId: UUID,
        serverId: Int,
        endpoint: String
    ) throws {
        // Remove any existing pending operations for this entity
        removeExistingOperations(for: localEntityId)

        let operation = PendingOperation(
            operationType: .delete,
            entityType: entityType,
            localEntityId: localEntityId,
            endpoint: endpoint,
            httpMethod: "DELETE",
            serverEntityId: serverId
        )

        context.insert(operation)
        try context.save()
        updatePendingCount()

        print("[OutboxManager] Queued DELETE for \(entityType.rawValue): \(serverId)")
    }

    /// Queue a TOGGLE operation (for quick actions like task completion)
    func queueToggle(
        entityType: SyncEntityType,
        localEntityId: UUID,
        serverId: Int,
        endpoint: String
    ) throws {
        let operation = PendingOperation(
            operationType: .toggle,
            entityType: entityType,
            localEntityId: localEntityId,
            endpoint: endpoint,
            httpMethod: "POST",
            serverEntityId: serverId
        )

        context.insert(operation)
        try context.save()
        updatePendingCount()

        print("[OutboxManager] Queued TOGGLE for \(entityType.rawValue): \(serverId)")
    }

    // MARK: - Fetch Operations

    /// Get all pending operations sorted by priority and creation date
    func getPendingOperations() -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>(
            sortBy: [
                SortDescriptor(\.priority, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get pending operations for a specific entity
    func getOperations(for localId: UUID) -> [PendingOperation] {
        let localIdString = localId.uuidString
        let descriptor = FetchDescriptor<PendingOperation>(
            predicate: #Predicate { $0.localEntityId == localIdString }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get pending operations for a specific entity type
    func getOperations(for entityType: SyncEntityType) -> [PendingOperation] {
        let typeString = entityType.rawValue
        let descriptor = FetchDescriptor<PendingOperation>(
            predicate: #Predicate { $0.entityType == typeString },
            sortBy: [
                SortDescriptor(\.priority, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Check if entity has pending operations
    func hasPendingOperations(for localId: UUID) -> Bool {
        !getOperations(for: localId).isEmpty
    }

    // MARK: - Remove Operations

    /// Remove a specific operation
    func removeOperation(_ operation: PendingOperation) {
        context.delete(operation)
        try? context.save()
        updatePendingCount()
    }

    /// Remove all operations for an entity
    func removeOperations(for localId: UUID) {
        let operations = getOperations(for: localId)
        operations.forEach { context.delete($0) }
        try? context.save()
        updatePendingCount()
    }

    /// Remove all pending operations
    func removeAllOperations() {
        let operations = getPendingOperations()
        operations.forEach { context.delete($0) }
        try? context.save()
        updatePendingCount()
    }

    // MARK: - Helpers

    private func removeExistingOperations(for localId: UUID) {
        let operations = getOperations(for: localId)
        operations.forEach { context.delete($0) }
    }

    private func updatePendingCount() {
        let descriptor = FetchDescriptor<PendingOperation>()
        pendingCount = (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Mark operation as failed and increment retry
    func markOperationFailed(_ operation: PendingOperation, error: String) {
        operation.incrementRetry(error: error)
        lastError = error
        try? context.save()
    }

    /// Get operations that can be retried
    func getRetryableOperations() -> [PendingOperation] {
        getPendingOperations().filter { $0.canRetry }
    }
}
