import SwiftData
import Foundation

@Model
final class PendingOperation {
    @Attribute(.unique) var id: UUID

    // Operation details
    var operationType: String   // OperationType raw value
    var entityType: String      // SyncEntityType raw value
    var localEntityId: String   // UUID string of cached entity
    var serverEntityId: Int?    // Server ID if known
    var parentServerId: Int?    // For nested entities (e.g., item's listId, task's goalId)

    // Request data
    var endpoint: String        // API endpoint path
    var httpMethod: String      // GET, POST, PUT, DELETE
    var requestPayload: Data?   // JSON encoded request body

    // Metadata
    var createdAt: Date
    var retryCount: Int
    var maxRetries: Int
    var lastAttemptAt: Date?
    var lastError: String?

    // Priority (lower = higher priority)
    var priority: Int

    init(
        operationType: OperationType,
        entityType: SyncEntityType,
        localEntityId: UUID,
        endpoint: String,
        httpMethod: String,
        serverEntityId: Int? = nil,
        parentServerId: Int? = nil
    ) {
        self.id = UUID()
        self.operationType = operationType.rawValue
        self.entityType = entityType.rawValue
        self.localEntityId = localEntityId.uuidString
        self.serverEntityId = serverEntityId
        self.parentServerId = parentServerId
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.createdAt = Date()
        self.retryCount = 0
        self.maxRetries = 3
        // Deletes processed last, toggles processed first
        self.priority = operationType == .delete ? 100 : (operationType == .toggle ? -10 : 0)
    }

    // MARK: - Computed Properties

    var canRetry: Bool {
        retryCount < maxRetries
    }

    var currentOperationType: OperationType? {
        OperationType(rawValue: operationType)
    }

    var currentEntityType: SyncEntityType? {
        SyncEntityType(rawValue: entityType)
    }

    var localUUID: UUID? {
        UUID(uuidString: localEntityId)
    }

    // MARK: - Methods

    func incrementRetry(error: String) {
        retryCount += 1
        lastAttemptAt = Date()
        lastError = error
    }

    func setPayload<T: Encodable>(_ payload: T) throws {
        self.requestPayload = try JSONEncoder().encode(payload)
    }

    func getPayload<T: Decodable>(as type: T.Type) -> T? {
        guard let data = requestPayload else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // Convert to sync operation for API
    func toSyncOperation() -> SyncOperation {
        var dataDict: [String: AnyCodable]? = nil

        if let payload = requestPayload,
           let dict = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] {
            dataDict = dict.mapValues { AnyCodable($0) }
        }

        return SyncOperation(
            localId: localEntityId,
            operationType: operationType,
            entityType: entityType,
            serverId: serverEntityId,
            version: nil,  // Version is included in the data dict
            data: dataDict,
            createdAt: ISO8601DateFormatter().string(from: createdAt)
        )
    }
}
