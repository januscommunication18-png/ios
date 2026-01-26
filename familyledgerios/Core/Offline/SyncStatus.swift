import Foundation

// MARK: - Sync Status Enum
enum SyncStatus: String, Codable {
    case synced          // Data matches server
    case pendingCreate   // Created offline, needs upload
    case pendingUpdate   // Modified offline, needs sync
    case pendingDelete   // Deleted offline, needs server deletion
    case conflicted      // Server and local differ, needs resolution
}

// MARK: - Operation Types
enum OperationType: String, Codable {
    case create
    case update
    case delete
    case toggle    // For quick actions like task completion
}

// MARK: - Entity Types
enum SyncEntityType: String, Codable {
    case shoppingList
    case shoppingItem
    case goal
    case goalTask
    case asset
}

// MARK: - Sync Result
struct SyncOperationResult: Codable {
    let localId: String
    let serverId: Int?
    let status: String
    let version: Int?
    let serverUpdatedAt: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case localId = "local_id"
        case serverId = "server_id"
        case status
        case version
        case serverUpdatedAt = "server_updated_at"
        case error
    }
}

// MARK: - Pull Response
struct SyncPullResponse: Codable {
    let success: Bool
    let data: SyncChanges
    let serverTime: String

    enum CodingKeys: String, CodingKey {
        case success
        case data
        case serverTime = "server_time"
    }
}

struct SyncChanges: Codable {
    let updated: [String: [[String: AnyCodable]]]?
    let deleted: [String: [Int]]?
}

// MARK: - Push Request
struct SyncPushRequest: Encodable {
    let deviceId: String
    let deviceName: String?
    let operations: [SyncOperation]

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case deviceName = "device_name"
        case operations
    }
}

struct SyncOperation: Codable {
    let localId: String
    let operationType: String
    let entityType: String
    let serverId: Int?
    let version: Int?
    let data: [String: AnyCodable]?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case localId = "local_id"
        case operationType = "operation_type"
        case entityType = "entity_type"
        case serverId = "server_id"
        case version
        case data
        case createdAt = "created_at"
    }
}

// MARK: - Push Response
struct SyncPushResponse: Codable {
    let success: Bool
    let results: [SyncOperationResult]
    let serverTime: String

    enum CodingKeys: String, CodingKey {
        case success
        case results
        case serverTime = "server_time"
    }
}

// MARK: - Conflict
struct SyncConflict: Identifiable, Codable {
    let id: Int
    let entityType: String
    let entityId: Int
    let serverData: [String: AnyCodable]
    let clientData: [String: AnyCodable]
    let resolution: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case entityType = "entity_type"
        case entityId = "entity_id"
        case serverData = "server_data"
        case clientData = "client_data"
        case resolution
        case createdAt = "created_at"
    }
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}
