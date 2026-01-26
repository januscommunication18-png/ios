# Offline Mode Implementation Plan for FamilyLedger iOS

## Overview
This document provides a complete implementation plan for adding offline support to the FamilyLedger iOS app with Laravel backend synchronization.

---

## Part 1: SwiftData Local Database Schema

### 1.1 Core Infrastructure

```swift
// File: Core/Offline/OfflineModels.swift

import SwiftData
import Foundation

// MARK: - Sync Status Enum
enum SyncStatus: String, Codable {
    case synced          // Data matches server
    case pendingCreate   // Created offline, needs upload
    case pendingUpdate   // Modified offline, needs sync
    case pendingDelete   // Deleted offline, needs server deletion
    case conflicted      // Server and local differ, needs resolution
}

// MARK: - Base Protocol for Cacheable Models
protocol CacheableModel {
    var serverId: Int? { get }
    var localId: UUID { get }
    var syncStatus: SyncStatus { get set }
    var lastSyncedAt: Date? { get set }
    var serverUpdatedAt: Date? { get set }
    var localUpdatedAt: Date { get set }
}
```

### 1.2 Family Circle Cache Model

```swift
// File: Core/Offline/Models/CachedFamilyCircle.swift

import SwiftData
import Foundation

@Model
final class CachedFamilyCircle: CacheableModel {
    // Identifiers
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Data
    var name: String
    var circleDescription: String?
    var coverImageUrl: String?
    var membersCount: Int

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \CachedFamilyMember.familyCircle)
    var members: [CachedFamilyMember]?

    init(
        serverId: Int? = nil,
        name: String,
        circleDescription: String? = nil,
        coverImageUrl: String? = nil,
        membersCount: Int = 0
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.name = name
        self.circleDescription = circleDescription
        self.coverImageUrl = coverImageUrl
        self.membersCount = membersCount
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    // Convert from API model
    static func from(_ apiModel: FamilyCircle) -> CachedFamilyCircle {
        let cached = CachedFamilyCircle(
            serverId: apiModel.id,
            name: apiModel.name,
            circleDescription: apiModel.description,
            coverImageUrl: apiModel.coverImageUrl,
            membersCount: apiModel.membersCount ?? 0
        )
        cached.syncStatus = .synced
        cached.lastSyncedAt = Date()
        if let updatedAt = apiModel.updatedAt {
            cached.serverUpdatedAt = ISO8601DateFormatter().date(from: updatedAt)
        }
        return cached
    }
}
```

### 1.3 Family Member Cache Model

```swift
// File: Core/Offline/Models/CachedFamilyMember.swift

import SwiftData
import Foundation

@Model
final class CachedFamilyMember: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Basic info
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var dateOfBirth: String?
    var age: Int?
    var relationship: String?
    var relationshipName: String?
    var isMinor: Bool
    var profileImageUrl: String?
    var immigrationStatus: String?
    var coParentingEnabled: Bool

    // Medical info (stored as JSON for flexibility)
    var medicalInfoJSON: Data?

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Relationships
    var familyCircle: CachedFamilyCircle?
    var familyCircleServerId: Int?

    init(
        serverId: Int? = nil,
        firstName: String?,
        lastName: String?,
        relationship: String?
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.firstName = firstName
        self.lastName = lastName
        self.relationship = relationship
        self.isMinor = false
        self.coParentingEnabled = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    var displayName: String {
        "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }

    static func from(_ apiModel: FamilyMemberBasic, circleId: Int?) -> CachedFamilyMember {
        let cached = CachedFamilyMember(
            serverId: apiModel.id,
            firstName: apiModel.firstName,
            lastName: apiModel.lastName,
            relationship: apiModel.relationship
        )
        cached.email = apiModel.email
        cached.phone = apiModel.phone
        cached.dateOfBirth = apiModel.dateOfBirth
        cached.age = apiModel.age
        cached.relationshipName = apiModel.relationshipName
        cached.isMinor = apiModel.isMinor ?? false
        cached.profileImageUrl = apiModel.profileImageUrl
        cached.immigrationStatus = apiModel.immigrationStatus
        cached.coParentingEnabled = apiModel.coParentingEnabled ?? false
        cached.familyCircleServerId = circleId
        cached.syncStatus = .synced
        cached.lastSyncedAt = Date()
        return cached
    }
}
```

### 1.4 Expense Cache Model

```swift
// File: Core/Offline/Models/CachedExpense.swift

import SwiftData
import Foundation

@Model
final class CachedExpense: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Core expense data
    var expenseDescription: String?
    var amount: Double
    var categoryId: Int?
    var categoryName: String?
    var categoryIcon: String?
    var budgetId: Int?
    var transactionDate: Date?
    var payee: String?
    var paidBy: String?
    var paidById: Int?
    var paymentMethod: String?
    var isRecurring: Bool
    var recurringFrequency: String?
    var status: String?
    var notes: String?

    // Receipt (stored locally)
    var localReceiptPath: String?
    var serverReceiptUrl: String?

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    init(
        serverId: Int? = nil,
        description: String?,
        amount: Double,
        categoryId: Int?
    ) {
        self.localId = UUID()
        self.serverId = serverId
        self.expenseDescription = description
        self.amount = amount
        self.categoryId = categoryId
        self.isRecurring = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    static func from(_ apiModel: Expense) -> CachedExpense {
        let cached = CachedExpense(
            serverId: apiModel.id,
            description: apiModel.description,
            amount: apiModel.amount ?? 0,
            categoryId: apiModel.categoryId
        )
        cached.categoryName = apiModel.category?.name
        cached.categoryIcon = apiModel.category?.icon
        cached.budgetId = apiModel.budgetId
        cached.payee = apiModel.payee
        cached.paidBy = apiModel.paidBy
        cached.paidById = apiModel.paidById
        cached.paymentMethod = apiModel.paymentMethod
        cached.isRecurring = apiModel.isRecurring ?? false
        cached.recurringFrequency = apiModel.recurringFrequency
        cached.status = apiModel.status?.rawValue
        cached.notes = apiModel.notes
        cached.serverReceiptUrl = apiModel.receiptUrl
        cached.syncStatus = .synced
        cached.lastSyncedAt = Date()

        // Parse transaction date
        if let dateStr = apiModel.transactionDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            cached.transactionDate = formatter.date(from: dateStr)
        }

        return cached
    }
}
```

### 1.5 Goal Cache Model

```swift
// File: Core/Offline/Models/CachedGoal.swift

import SwiftData
import Foundation

@Model
final class CachedGoal: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Goal data
    var title: String
    var goalDescription: String?
    var targetDate: Date?
    var progress: Int
    var status: String?
    var priority: String?
    var category: String?
    var categoryEmoji: String?

    // Goal type
    var goalType: String?
    var habitFrequency: String?
    var milestoneTarget: Int?
    var milestoneCurrent: Int?
    var milestoneUnit: String?

    // Assignment
    var assignmentType: String?
    var isKidGoal: Bool

    // Rewards
    var rewardsEnabled: Bool
    var rewardType: String?
    var rewardCustom: String?
    var rewardClaimed: Bool

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Tasks relationship
    @Relationship(deleteRule: .cascade, inverse: \CachedGoalTask.goal)
    var tasks: [CachedGoalTask]?

    init(serverId: Int? = nil, title: String) {
        self.localId = UUID()
        self.serverId = serverId
        self.title = title
        self.progress = 0
        self.isKidGoal = false
        self.rewardsEnabled = false
        self.rewardClaimed = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    static func from(_ apiModel: Goal) -> CachedGoal {
        let cached = CachedGoal(serverId: apiModel.id, title: apiModel.title)
        cached.goalDescription = apiModel.description
        cached.progress = apiModel.progress ?? 0
        cached.status = apiModel.status
        cached.priority = apiModel.priority
        cached.category = apiModel.category
        cached.categoryEmoji = apiModel.categoryEmoji
        cached.goalType = apiModel.goalType
        cached.habitFrequency = apiModel.habitFrequency
        cached.milestoneTarget = apiModel.milestoneTarget
        cached.milestoneCurrent = apiModel.milestoneCurrent
        cached.milestoneUnit = apiModel.milestoneUnit
        cached.assignmentType = apiModel.assignmentType
        cached.isKidGoal = apiModel.isKidGoal ?? false
        cached.rewardsEnabled = apiModel.rewardsEnabled ?? false
        cached.rewardType = apiModel.rewardType
        cached.rewardCustom = apiModel.rewardCustom
        cached.rewardClaimed = apiModel.rewardClaimed ?? false
        cached.syncStatus = .synced
        cached.lastSyncedAt = Date()

        if let dateStr = apiModel.targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            cached.targetDate = formatter.date(from: dateStr)
        }

        return cached
    }
}

@Model
final class CachedGoalTask: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    var title: String
    var taskDescription: String?
    var dueDate: Date?
    var dueTime: String?
    var priority: String?
    var status: String?
    var isRecurring: Bool
    var recurrencePattern: String?
    var assignedTo: String?

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Relationship
    var goal: CachedGoal?
    var goalServerId: Int?

    init(serverId: Int? = nil, title: String) {
        self.localId = UUID()
        self.serverId = serverId
        self.title = title
        self.isRecurring = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    var isCompleted: Bool {
        status == "completed"
    }
}
```

### 1.6 Journal Entry Cache Model

```swift
// File: Core/Offline/Models/CachedJournalEntry.swift

import SwiftData
import Foundation

@Model
final class CachedJournalEntry: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Journal data
    var title: String?
    var content: String?
    var entryType: String?
    var mood: String?
    var moodEmoji: String?
    var entryDate: Date?
    var entryTime: String?
    var isPinned: Bool
    var isDraft: Bool
    var visibility: String?

    // Tags stored as JSON array
    var tagsJSON: Data?

    // Local photo paths (for offline-created entries)
    var localPhotoPaths: [String]?

    // Server photo URLs
    var serverPhotoUrls: [String]?

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Conflict resolution
    var serverContent: String?  // Stores server version during conflict
    var conflictDetectedAt: Date?

    init(serverId: Int? = nil, title: String?, content: String?) {
        self.localId = UUID()
        self.serverId = serverId
        self.title = title
        self.content = content
        self.isPinned = false
        self.isDraft = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    static func from(_ apiModel: JournalEntry) -> CachedJournalEntry {
        let cached = CachedJournalEntry(
            serverId: apiModel.id,
            title: apiModel.title,
            content: apiModel.content
        )
        cached.entryType = apiModel.type
        cached.mood = apiModel.mood
        cached.moodEmoji = apiModel.moodEmoji
        cached.entryTime = apiModel.time
        cached.isPinned = apiModel.isPinned ?? false
        cached.isDraft = apiModel.isDraft ?? false
        cached.visibility = apiModel.visibility
        cached.serverPhotoUrls = apiModel.photos
        cached.syncStatus = .synced
        cached.lastSyncedAt = Date()

        // Encode tags as JSON
        if let tags = apiModel.tags {
            cached.tagsJSON = try? JSONEncoder().encode(tags)
        }

        // Parse date
        if let dateStr = apiModel.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            cached.entryDate = formatter.date(from: dateStr)
        }

        return cached
    }
}
```

### 1.7 Shopping List Cache Model

```swift
// File: Core/Offline/Models/CachedShoppingList.swift

import SwiftData
import Foundation

@Model
final class CachedShoppingList: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    var name: String
    var listDescription: String?
    var storeName: String?
    var color: String?
    var icon: String?
    var isDefault: Bool

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Items relationship
    @Relationship(deleteRule: .cascade, inverse: \CachedShoppingItem.shoppingList)
    var items: [CachedShoppingItem]?

    init(serverId: Int? = nil, name: String) {
        self.localId = UUID()
        self.serverId = serverId
        self.name = name
        self.isDefault = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    var itemsCount: Int { items?.count ?? 0 }
    var purchasedCount: Int { items?.filter { $0.isChecked }.count ?? 0 }

    static func from(_ apiModel: ShoppingList) -> CachedShoppingList {
        let cached = CachedShoppingList(serverId: apiModel.id, name: apiModel.name)
        cached.listDescription = apiModel.description
        cached.storeName = apiModel.storeName
        cached.color = apiModel.color
        cached.icon = apiModel.icon
        cached.isDefault = apiModel.isDefault ?? false
        cached.syncStatus = .synced
        cached.lastSyncedAt = Date()
        return cached
    }
}

@Model
final class CachedShoppingItem: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    var name: String
    var quantity: Int
    var unit: String?
    var category: String?
    var isChecked: Bool
    var price: Double?
    var notes: String?
    var priority: String?

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Relationship
    var shoppingList: CachedShoppingList?
    var shoppingListServerId: Int?

    init(serverId: Int? = nil, name: String) {
        self.localId = UUID()
        self.serverId = serverId
        self.name = name
        self.quantity = 1
        self.isChecked = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }
}
```

### 1.8 Asset Cache Model

```swift
// File: Core/Offline/Models/CachedAsset.swift

import SwiftData
import Foundation

@Model
final class CachedAsset: CacheableModel {
    @Attribute(.unique) var localId: UUID
    var serverId: Int?

    // Basic info
    var name: String
    var imageUrl: String?
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

    // Sync metadata
    var syncStatus: SyncStatus
    var lastSyncedAt: Date?
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    // Owners stored as JSON
    var ownersJSON: Data?

    init(serverId: Int? = nil, name: String) {
        self.localId = UUID()
        self.serverId = serverId
        self.name = name
        self.isInsured = false
        self.syncStatus = serverId != nil ? .synced : .pendingCreate
        self.localUpdatedAt = Date()
    }

    static func from(_ apiModel: Asset) -> CachedAsset {
        let cached = CachedAsset(serverId: apiModel.id, name: apiModel.name)
        cached.imageUrl = apiModel.imageUrl
        cached.assetCategory = apiModel.assetCategory
        cached.assetType = apiModel.assetType
        cached.assetDescription = apiModel.description
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
        cached.syncStatus = .synced
        cached.lastSyncedAt = Date()

        // Encode owners as JSON
        if let owners = apiModel.owners {
            cached.ownersJSON = try? JSONEncoder().encode(owners)
        }

        return cached
    }
}
```

### 1.9 SwiftData Container Setup

```swift
// File: Core/Offline/OfflineDataContainer.swift

import SwiftData
import Foundation

@MainActor
class OfflineDataContainer {
    static let shared = OfflineDataContainer()

    let container: ModelContainer
    let context: ModelContext

    private init() {
        let schema = Schema([
            CachedFamilyCircle.self,
            CachedFamilyMember.self,
            CachedExpense.self,
            CachedGoal.self,
            CachedGoalTask.self,
            CachedJournalEntry.self,
            CachedShoppingList.self,
            CachedShoppingItem.self,
            CachedAsset.self,
            PendingOperation.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
            context = ModelContext(container)
            context.autosaveEnabled = true
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

---

## Part 2: Outbox Format (Pending Operations Queue)

### 2.1 Pending Operation Model

```swift
// File: Core/Offline/PendingOperation.swift

import SwiftData
import Foundation

enum OperationType: String, Codable {
    case create
    case update
    case delete
    case toggle    // For quick actions like task completion
    case upload    // For file uploads
}

enum EntityType: String, Codable {
    case familyCircle
    case familyMember
    case expense
    case goal
    case goalTask
    case journalEntry
    case shoppingList
    case shoppingItem
    case asset
}

@Model
final class PendingOperation {
    @Attribute(.unique) var id: UUID

    // Operation details
    var operationType: OperationType
    var entityType: EntityType
    var localEntityId: UUID        // Links to cached entity
    var serverEntityId: Int?       // Server ID if known
    var parentServerId: Int?       // For nested entities (e.g., task's goalId)

    // Request data
    var endpoint: String           // API endpoint path
    var httpMethod: String         // GET, POST, PUT, DELETE
    var requestPayload: Data?      // JSON encoded request body

    // File upload data (if applicable)
    var localFilePath: String?
    var fileFieldName: String?

    // Metadata
    var createdAt: Date
    var retryCount: Int
    var maxRetries: Int
    var lastAttemptAt: Date?
    var lastError: String?

    // Priority (lower = higher priority)
    var priority: Int

    // Dependencies (operations that must complete first)
    var dependsOnOperationIds: [UUID]?

    init(
        operationType: OperationType,
        entityType: EntityType,
        localEntityId: UUID,
        endpoint: String,
        httpMethod: String
    ) {
        self.id = UUID()
        self.operationType = operationType
        self.entityType = entityType
        self.localEntityId = localEntityId
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.createdAt = Date()
        self.retryCount = 0
        self.maxRetries = 3
        self.priority = operationType == .delete ? 100 : 0  // Deletes processed last
    }

    var canRetry: Bool {
        retryCount < maxRetries
    }

    func incrementRetry(error: String) {
        retryCount += 1
        lastAttemptAt = Date()
        lastError = error
    }
}
```

### 2.2 Outbox Manager

```swift
// File: Core/Offline/OutboxManager.swift

import SwiftData
import Foundation

@Observable
@MainActor
class OutboxManager {
    static let shared = OutboxManager()

    private let context: ModelContext
    private var isSyncing = false

    var pendingCount: Int = 0
    var lastSyncError: String?

    private init() {
        self.context = OfflineDataContainer.shared.context
        updatePendingCount()
    }

    // MARK: - Queue Operations

    func queueCreate<T: CacheableModel>(
        entity: T,
        entityType: EntityType,
        endpoint: String,
        payload: Encodable
    ) throws {
        let operation = PendingOperation(
            operationType: .create,
            entityType: entityType,
            localEntityId: entity.localId,
            endpoint: endpoint,
            httpMethod: "POST"
        )
        operation.requestPayload = try JSONEncoder().encode(payload)

        context.insert(operation)
        try context.save()
        updatePendingCount()
    }

    func queueUpdate<T: CacheableModel>(
        entity: T,
        entityType: EntityType,
        endpoint: String,
        payload: Encodable
    ) throws {
        let operation = PendingOperation(
            operationType: .update,
            entityType: entityType,
            localEntityId: entity.localId,
            endpoint: endpoint,
            httpMethod: "PUT"
        )
        operation.serverEntityId = entity.serverId
        operation.requestPayload = try JSONEncoder().encode(payload)

        context.insert(operation)
        try context.save()
        updatePendingCount()
    }

    func queueDelete<T: CacheableModel>(
        entity: T,
        entityType: EntityType,
        endpoint: String
    ) throws {
        let operation = PendingOperation(
            operationType: .delete,
            entityType: entityType,
            localEntityId: entity.localId,
            endpoint: endpoint,
            httpMethod: "DELETE"
        )
        operation.serverEntityId = entity.serverId
        operation.priority = 100  // Process deletes last

        context.insert(operation)
        try context.save()
        updatePendingCount()
    }

    func queueToggle(
        entityType: EntityType,
        localEntityId: UUID,
        serverEntityId: Int,
        endpoint: String
    ) throws {
        let operation = PendingOperation(
            operationType: .toggle,
            entityType: entityType,
            localEntityId: localEntityId,
            endpoint: endpoint,
            httpMethod: "POST"
        )
        operation.serverEntityId = serverEntityId
        operation.priority = -10  // High priority for toggles

        context.insert(operation)
        try context.save()
        updatePendingCount()
    }

    // MARK: - Fetch Pending Operations

    func getPendingOperations() -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>(
            sortBy: [
                SortDescriptor(\.priority, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getOperationsForEntity(localId: UUID) -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>(
            predicate: #Predicate { $0.localEntityId == localId }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Remove Operations

    func removeOperation(_ operation: PendingOperation) {
        context.delete(operation)
        try? context.save()
        updatePendingCount()
    }

    func removeOperationsForEntity(localId: UUID) {
        let operations = getOperationsForEntity(localId: localId)
        operations.forEach { context.delete($0) }
        try? context.save()
        updatePendingCount()
    }

    // MARK: - Helpers

    private func updatePendingCount() {
        let descriptor = FetchDescriptor<PendingOperation>()
        pendingCount = (try? context.fetchCount(descriptor)) ?? 0
    }
}
```

### 2.3 Outbox JSON Format Example

```json
// Example of what gets stored in PendingOperation.requestPayload

// CREATE expense example
{
    "localId": "550e8400-e29b-41d4-a716-446655440000",
    "operationType": "create",
    "entityType": "expense",
    "endpoint": "/expenses",
    "httpMethod": "POST",
    "payload": {
        "description": "Groceries",
        "amount": 125.50,
        "category_id": 1,
        "transaction_date": "2025-01-25",
        "payment_method": "credit_card",
        "notes": "Weekly shopping"
    },
    "createdAt": "2025-01-25T10:30:00Z",
    "retryCount": 0
}

// UPDATE goal example
{
    "localId": "660e8400-e29b-41d4-a716-446655440001",
    "operationType": "update",
    "entityType": "goal",
    "serverEntityId": 42,
    "endpoint": "/goals/42",
    "httpMethod": "PUT",
    "payload": {
        "title": "Read 20 books",
        "progress": 45,
        "status": "in_progress"
    },
    "createdAt": "2025-01-25T11:00:00Z",
    "retryCount": 0
}

// TOGGLE task example (lightweight)
{
    "localId": "770e8400-e29b-41d4-a716-446655440002",
    "operationType": "toggle",
    "entityType": "goalTask",
    "serverEntityId": 128,
    "endpoint": "/tasks/128/toggle",
    "httpMethod": "POST",
    "payload": null,
    "createdAt": "2025-01-25T11:05:00Z",
    "priority": -10
}

// DELETE shopping item example
{
    "localId": "880e8400-e29b-41d4-a716-446655440003",
    "operationType": "delete",
    "entityType": "shoppingItem",
    "serverEntityId": 256,
    "endpoint": "/shopping/lists/5/items/256",
    "httpMethod": "DELETE",
    "payload": null,
    "createdAt": "2025-01-25T11:10:00Z",
    "priority": 100
}
```

---

## Part 3: Laravel Sync Endpoints

### 3.1 Database Migrations

```php
// database/migrations/2025_01_25_000001_add_sync_columns_to_tables.php

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Tables that need sync support
     */
    protected array $syncTables = [
        'family_circles',
        'family_members',
        'expenses',
        'goals',
        'goal_tasks',
        'journal_entries',
        'shopping_lists',
        'shopping_items',
        'assets',
    ];

    public function up(): void
    {
        foreach ($this->syncTables as $table) {
            if (Schema::hasTable($table)) {
                Schema::table($table, function (Blueprint $table) {
                    // Version number for optimistic locking
                    if (!Schema::hasColumn($table->getTable(), 'version')) {
                        $table->unsignedInteger('version')->default(1);
                    }

                    // Track which device last modified
                    if (!Schema::hasColumn($table->getTable(), 'last_modified_device')) {
                        $table->string('last_modified_device')->nullable();
                    }

                    // Soft delete support for sync
                    if (!Schema::hasColumn($table->getTable(), 'deleted_at')) {
                        $table->softDeletes();
                    }
                });
            }
        }

        // Create sync_logs table for tracking
        Schema::create('sync_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('tenant_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('device_id');
            $table->string('device_name')->nullable();
            $table->string('entity_type');
            $table->unsignedBigInteger('entity_id');
            $table->string('operation'); // create, update, delete
            $table->json('changes')->nullable();
            $table->timestamp('synced_at');
            $table->timestamps();

            $table->index(['user_id', 'entity_type', 'synced_at']);
            $table->index(['device_id', 'synced_at']);
        });

        // Create conflict_resolutions table
        Schema::create('conflict_resolutions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('entity_type');
            $table->unsignedBigInteger('entity_id');
            $table->json('server_data');
            $table->json('client_data');
            $table->string('resolution'); // server_wins, client_wins, merged
            $table->json('resolved_data')->nullable();
            $table->string('resolved_by')->nullable(); // user_id or 'auto'
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conflict_resolutions');
        Schema::dropIfExists('sync_logs');

        foreach ($this->syncTables as $table) {
            if (Schema::hasTable($table)) {
                Schema::table($table, function (Blueprint $table) {
                    $table->dropColumn(['version', 'last_modified_device']);
                    $table->dropSoftDeletes();
                });
            }
        }
    }
};
```

### 3.2 Sync Controller

```php
// app/Http/Controllers/Api/V1/SyncController.php

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\SyncService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class SyncController extends Controller
{
    public function __construct(
        protected SyncService $syncService
    ) {}

    /**
     * Get changes since last sync
     * GET /api/v1/sync/pull
     */
    public function pull(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'last_sync_at' => 'nullable|date',
            'device_id' => 'required|string',
            'entities' => 'nullable|array',
            'entities.*' => 'string|in:family_circles,family_members,expenses,goals,goal_tasks,journal_entries,shopping_lists,shopping_items,assets',
        ]);

        $lastSyncAt = $validated['last_sync_at']
            ? \Carbon\Carbon::parse($validated['last_sync_at'])
            : null;

        $entities = $validated['entities'] ?? [
            'family_circles',
            'family_members',
            'expenses',
            'goals',
            'goal_tasks',
            'journal_entries',
            'shopping_lists',
            'shopping_items',
            'assets'
        ];

        $changes = $this->syncService->getChangesSince(
            user: $request->user(),
            lastSyncAt: $lastSyncAt,
            entities: $entities
        );

        return response()->json([
            'success' => true,
            'data' => $changes,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    /**
     * Push local changes to server
     * POST /api/v1/sync/push
     */
    public function push(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_id' => 'required|string',
            'device_name' => 'nullable|string',
            'operations' => 'required|array',
            'operations.*.local_id' => 'required|uuid',
            'operations.*.operation_type' => 'required|in:create,update,delete,toggle',
            'operations.*.entity_type' => 'required|string',
            'operations.*.server_id' => 'nullable|integer',
            'operations.*.version' => 'nullable|integer',
            'operations.*.data' => 'nullable|array',
            'operations.*.created_at' => 'required|date',
        ]);

        $results = $this->syncService->processOperations(
            user: $request->user(),
            deviceId: $validated['device_id'],
            deviceName: $validated['device_name'] ?? null,
            operations: $validated['operations']
        );

        return response()->json([
            'success' => true,
            'results' => $results,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    /**
     * Resolve a conflict
     * POST /api/v1/sync/resolve
     */
    public function resolve(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'entity_type' => 'required|string',
            'entity_id' => 'required|integer',
            'resolution' => 'required|in:server_wins,client_wins,merged',
            'merged_data' => 'required_if:resolution,merged|array',
        ]);

        $result = $this->syncService->resolveConflict(
            user: $request->user(),
            entityType: $validated['entity_type'],
            entityId: $validated['entity_id'],
            resolution: $validated['resolution'],
            mergedData: $validated['merged_data'] ?? null
        );

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }

    /**
     * Get pending conflicts for user
     * GET /api/v1/sync/conflicts
     */
    public function conflicts(Request $request): JsonResponse
    {
        $conflicts = $this->syncService->getPendingConflicts($request->user());

        return response()->json([
            'success' => true,
            'conflicts' => $conflicts,
        ]);
    }
}
```

### 3.3 Sync Service

```php
// app/Services/SyncService.php

<?php

namespace App\Services;

use App\Models\User;
use App\Models\SyncLog;
use App\Models\ConflictResolution;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class SyncService
{
    /**
     * Entity type to Model class mapping
     */
    protected array $entityModels = [
        'family_circles' => \App\Models\FamilyCircle::class,
        'family_members' => \App\Models\FamilyMember::class,
        'expenses' => \App\Models\Expense::class,
        'goals' => \App\Models\Goal::class,
        'goal_tasks' => \App\Models\GoalTask::class,
        'journal_entries' => \App\Models\JournalEntry::class,
        'shopping_lists' => \App\Models\ShoppingList::class,
        'shopping_items' => \App\Models\ShoppingItem::class,
        'assets' => \App\Models\Asset::class,
    ];

    /**
     * Get all changes since last sync
     */
    public function getChangesSince(User $user, ?Carbon $lastSyncAt, array $entities): array
    {
        $changes = [
            'updated' => [],
            'deleted' => [],
        ];

        foreach ($entities as $entityType) {
            if (!isset($this->entityModels[$entityType])) {
                continue;
            }

            $model = $this->entityModels[$entityType];
            $query = $model::query()
                ->where('tenant_id', $user->current_tenant_id);

            // Get updated records
            if ($lastSyncAt) {
                $updatedRecords = (clone $query)
                    ->where('updated_at', '>', $lastSyncAt)
                    ->get();
            } else {
                // First sync - get all records
                $updatedRecords = (clone $query)->get();
            }

            if ($updatedRecords->isNotEmpty()) {
                $changes['updated'][$entityType] = $updatedRecords->map(function ($record) {
                    return array_merge($record->toArray(), [
                        'version' => $record->version,
                        'server_updated_at' => $record->updated_at->toIso8601String(),
                    ]);
                })->toArray();
            }

            // Get soft-deleted records since last sync
            if ($lastSyncAt) {
                $deletedRecords = $model::onlyTrashed()
                    ->where('tenant_id', $user->current_tenant_id)
                    ->where('deleted_at', '>', $lastSyncAt)
                    ->pluck('id')
                    ->toArray();

                if (!empty($deletedRecords)) {
                    $changes['deleted'][$entityType] = $deletedRecords;
                }
            }
        }

        return $changes;
    }

    /**
     * Process batch of operations from client
     */
    public function processOperations(
        User $user,
        string $deviceId,
        ?string $deviceName,
        array $operations
    ): array {
        $results = [];

        DB::beginTransaction();

        try {
            foreach ($operations as $op) {
                $result = $this->processOperation($user, $deviceId, $deviceName, $op);
                $results[] = $result;
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }

        return $results;
    }

    /**
     * Process single operation
     */
    protected function processOperation(
        User $user,
        string $deviceId,
        ?string $deviceName,
        array $op
    ): array {
        $entityType = $op['entity_type'];
        $operationType = $op['operation_type'];
        $localId = $op['local_id'];
        $serverId = $op['server_id'] ?? null;
        $clientVersion = $op['version'] ?? null;
        $data = $op['data'] ?? [];

        if (!isset($this->entityModels[$entityType])) {
            return [
                'local_id' => $localId,
                'status' => 'error',
                'error' => 'Unknown entity type',
            ];
        }

        $model = $this->entityModels[$entityType];

        try {
            switch ($operationType) {
                case 'create':
                    return $this->handleCreate($user, $model, $localId, $data, $deviceId, $deviceName, $entityType);

                case 'update':
                    return $this->handleUpdate($user, $model, $localId, $serverId, $clientVersion, $data, $deviceId, $deviceName, $entityType);

                case 'delete':
                    return $this->handleDelete($user, $model, $localId, $serverId, $deviceId, $entityType);

                case 'toggle':
                    return $this->handleToggle($user, $model, $localId, $serverId, $deviceId, $entityType);

                default:
                    return [
                        'local_id' => $localId,
                        'status' => 'error',
                        'error' => 'Unknown operation type',
                    ];
            }
        } catch (\Exception $e) {
            return [
                'local_id' => $localId,
                'status' => 'error',
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * Handle CREATE operation
     */
    protected function handleCreate(
        User $user,
        string $model,
        string $localId,
        array $data,
        string $deviceId,
        ?string $deviceName,
        string $entityType
    ): array {
        // Add tenant/user context
        $data['tenant_id'] = $user->current_tenant_id;
        $data['user_id'] = $user->id;
        $data['version'] = 1;
        $data['last_modified_device'] = $deviceId;

        $record = $model::create($data);

        // Log the sync
        $this->logSync($user, $deviceId, $entityType, $record->id, 'create', $data);

        return [
            'local_id' => $localId,
            'server_id' => $record->id,
            'status' => 'created',
            'version' => $record->version,
            'server_updated_at' => $record->updated_at->toIso8601String(),
        ];
    }

    /**
     * Handle UPDATE operation with conflict detection
     */
    protected function handleUpdate(
        User $user,
        string $model,
        string $localId,
        ?int $serverId,
        ?int $clientVersion,
        array $data,
        string $deviceId,
        ?string $deviceName,
        string $entityType
    ): array {
        if (!$serverId) {
            return [
                'local_id' => $localId,
                'status' => 'error',
                'error' => 'Server ID required for update',
            ];
        }

        $record = $model::where('tenant_id', $user->current_tenant_id)
            ->find($serverId);

        if (!$record) {
            return [
                'local_id' => $localId,
                'status' => 'error',
                'error' => 'Record not found',
            ];
        }

        // Check for conflict (optimistic locking)
        if ($clientVersion !== null && $record->version !== $clientVersion) {
            // Conflict detected!
            return $this->createConflict(
                user: $user,
                entityType: $entityType,
                record: $record,
                localId: $localId,
                clientData: $data,
                clientVersion: $clientVersion
            );
        }

        // No conflict - apply update
        $data['version'] = $record->version + 1;
        $data['last_modified_device'] = $deviceId;

        $record->update($data);

        $this->logSync($user, $deviceId, $entityType, $record->id, 'update', $data);

        return [
            'local_id' => $localId,
            'server_id' => $record->id,
            'status' => 'updated',
            'version' => $record->version,
            'server_updated_at' => $record->updated_at->toIso8601String(),
        ];
    }

    /**
     * Handle DELETE operation
     */
    protected function handleDelete(
        User $user,
        string $model,
        string $localId,
        ?int $serverId,
        string $deviceId,
        string $entityType
    ): array {
        if (!$serverId) {
            return [
                'local_id' => $localId,
                'status' => 'deleted', // Already doesn't exist on server
            ];
        }

        $record = $model::where('tenant_id', $user->current_tenant_id)
            ->find($serverId);

        if (!$record) {
            return [
                'local_id' => $localId,
                'status' => 'deleted',
            ];
        }

        $record->delete(); // Soft delete

        $this->logSync($user, $deviceId, $entityType, $serverId, 'delete', []);

        return [
            'local_id' => $localId,
            'server_id' => $serverId,
            'status' => 'deleted',
        ];
    }

    /**
     * Handle TOGGLE operation (e.g., task completion)
     */
    protected function handleToggle(
        User $user,
        string $model,
        string $localId,
        ?int $serverId,
        string $deviceId,
        string $entityType
    ): array {
        if (!$serverId) {
            return [
                'local_id' => $localId,
                'status' => 'error',
                'error' => 'Server ID required for toggle',
            ];
        }

        $record = $model::where('tenant_id', $user->current_tenant_id)
            ->find($serverId);

        if (!$record) {
            return [
                'local_id' => $localId,
                'status' => 'error',
                'error' => 'Record not found',
            ];
        }

        // Toggle based on entity type
        $toggleField = match ($entityType) {
            'goal_tasks' => 'status',
            'shopping_items' => 'is_checked',
            default => null,
        };

        if ($toggleField) {
            if ($toggleField === 'status') {
                $record->status = $record->status === 'completed' ? 'open' : 'completed';
            } else {
                $record->$toggleField = !$record->$toggleField;
            }

            $record->version = $record->version + 1;
            $record->last_modified_device = $deviceId;
            $record->save();
        }

        $this->logSync($user, $deviceId, $entityType, $serverId, 'toggle', []);

        return [
            'local_id' => $localId,
            'server_id' => $serverId,
            'status' => 'toggled',
            'version' => $record->version,
            'current_value' => $record->$toggleField ?? $record->status,
        ];
    }

    /**
     * Create conflict record
     */
    protected function createConflict(
        User $user,
        string $entityType,
        $record,
        string $localId,
        array $clientData,
        int $clientVersion
    ): array {
        ConflictResolution::create([
            'user_id' => $user->id,
            'entity_type' => $entityType,
            'entity_id' => $record->id,
            'server_data' => $record->toArray(),
            'client_data' => $clientData,
            'resolution' => 'pending',
        ]);

        return [
            'local_id' => $localId,
            'server_id' => $record->id,
            'status' => 'conflict',
            'server_version' => $record->version,
            'client_version' => $clientVersion,
            'server_data' => $record->toArray(),
        ];
    }

    /**
     * Resolve a conflict
     */
    public function resolveConflict(
        User $user,
        string $entityType,
        int $entityId,
        string $resolution,
        ?array $mergedData
    ): array {
        $model = $this->entityModels[$entityType] ?? null;

        if (!$model) {
            throw new \InvalidArgumentException('Unknown entity type');
        }

        $record = $model::where('tenant_id', $user->current_tenant_id)
            ->find($entityId);

        if (!$record) {
            throw new \Exception('Record not found');
        }

        $conflict = ConflictResolution::where('user_id', $user->id)
            ->where('entity_type', $entityType)
            ->where('entity_id', $entityId)
            ->where('resolution', 'pending')
            ->first();

        if ($resolution === 'client_wins' || $resolution === 'merged') {
            $dataToApply = $resolution === 'merged' ? $mergedData : $conflict->client_data;
            $dataToApply['version'] = $record->version + 1;
            $record->update($dataToApply);
        }
        // For 'server_wins', we don't need to do anything - server data is already correct

        if ($conflict) {
            $conflict->update([
                'resolution' => $resolution,
                'resolved_data' => $record->toArray(),
                'resolved_by' => $user->id,
            ]);
        }

        return [
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'resolution' => $resolution,
            'data' => $record->fresh()->toArray(),
        ];
    }

    /**
     * Get pending conflicts for user
     */
    public function getPendingConflicts(User $user): array
    {
        return ConflictResolution::where('user_id', $user->id)
            ->where('resolution', 'pending')
            ->get()
            ->toArray();
    }

    /**
     * Log sync operation
     */
    protected function logSync(
        User $user,
        string $deviceId,
        string $entityType,
        int $entityId,
        string $operation,
        array $changes
    ): void {
        SyncLog::create([
            'user_id' => $user->id,
            'tenant_id' => $user->current_tenant_id,
            'device_id' => $deviceId,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'operation' => $operation,
            'changes' => $changes,
            'synced_at' => now(),
        ]);
    }
}
```

### 3.4 Routes

```php
// routes/api.php (add to existing routes)

Route::prefix('v1')->middleware(['auth:sanctum'])->group(function () {
    // ... existing routes ...

    // Sync endpoints
    Route::prefix('sync')->group(function () {
        Route::get('/pull', [SyncController::class, 'pull']);
        Route::post('/push', [SyncController::class, 'push']);
        Route::post('/resolve', [SyncController::class, 'resolve']);
        Route::get('/conflicts', [SyncController::class, 'conflicts']);
    });
});
```

### 3.5 Models Update (Add SoftDeletes and Version)

```php
// Add to each syncable model (example for Expense)

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Expense extends Model
{
    use SoftDeletes;

    protected $fillable = [
        // ... existing fields ...
        'version',
        'last_modified_device',
    ];

    protected $casts = [
        // ... existing casts ...
        'version' => 'integer',
    ];
}
```

---

## Part 4: Conflict Resolution UI Patterns

### 4.1 Conflict Types and Strategies

```swift
// File: Core/Offline/ConflictResolver.swift

import Foundation

enum ConflictStrategy {
    case lastWriteWins      // Automatic - most recent change wins
    case serverWins         // Automatic - server always wins
    case clientWins         // Automatic - client always wins
    case userDecides        // Manual - show UI for user to choose
    case fieldLevelMerge    // Automatic - merge non-conflicting fields
}

struct ConflictConfiguration {
    let entityType: EntityType
    let strategy: ConflictStrategy
    let mergeableFields: [String]?  // For field-level merge

    static let configurations: [EntityType: ConflictConfiguration] = [
        // Tasks: Last write wins (simple toggle operations)
        .goalTask: ConflictConfiguration(
            entityType: .goalTask,
            strategy: .lastWriteWins,
            mergeableFields: nil
        ),

        // Shopping items: Last write wins
        .shoppingItem: ConflictConfiguration(
            entityType: .shoppingItem,
            strategy: .lastWriteWins,
            mergeableFields: nil
        ),

        // Journal entries: User decides (content is important)
        .journalEntry: ConflictConfiguration(
            entityType: .journalEntry,
            strategy: .userDecides,
            mergeableFields: ["title", "mood", "isPinned"]
        ),

        // Expenses: Server authoritative with field merge
        .expense: ConflictConfiguration(
            entityType: .expense,
            strategy: .fieldLevelMerge,
            mergeableFields: ["notes", "paymentMethod", "status"]
        ),

        // Assets: User decides (financial data is critical)
        .asset: ConflictConfiguration(
            entityType: .asset,
            strategy: .userDecides,
            mergeableFields: ["notes", "status", "storageLocation"]
        ),

        // Goals: Field-level merge
        .goal: ConflictConfiguration(
            entityType: .goal,
            strategy: .fieldLevelMerge,
            mergeableFields: ["progress", "status", "notes"]
        ),

        // Family circles: User decides
        .familyCircle: ConflictConfiguration(
            entityType: .familyCircle,
            strategy: .userDecides,
            mergeableFields: nil
        ),

        // Family members: User decides
        .familyMember: ConflictConfiguration(
            entityType: .familyMember,
            strategy: .userDecides,
            mergeableFields: nil
        ),

        // Shopping lists: Field merge
        .shoppingList: ConflictConfiguration(
            entityType: .shoppingList,
            strategy: .fieldLevelMerge,
            mergeableFields: ["name", "storeName", "color"]
        ),
    ]
}
```

### 4.2 Conflict Model for UI

```swift
// File: Core/Offline/SyncConflict.swift

import Foundation

struct SyncConflict: Identifiable {
    let id: UUID
    let entityType: EntityType
    let entityId: Int
    let localData: [String: Any]
    let serverData: [String: Any]
    let conflictedFields: [String]
    let detectedAt: Date

    var displayTitle: String {
        switch entityType {
        case .journalEntry:
            return localData["title"] as? String ?? "Journal Entry"
        case .expense:
            return localData["description"] as? String ?? "Expense"
        case .goal:
            return localData["title"] as? String ?? "Goal"
        case .asset:
            return localData["name"] as? String ?? "Asset"
        default:
            return "\(entityType) #\(entityId)"
        }
    }
}

enum ConflictResolution {
    case keepLocal
    case keepServer
    case merge([String: Any])
}
```

### 4.3 Conflict Resolution Views

```swift
// File: Features/Sync/Views/ConflictResolutionView.swift

import SwiftUI

struct ConflictResolutionView: View {
    let conflict: SyncConflict
    let onResolve: (ConflictResolution) -> Void

    @State private var selectedResolution: ConflictResolution?
    @State private var mergedValues: [String: Any] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    conflictHeader

                    // Comparison
                    comparisonSection

                    // Resolution options
                    resolutionOptions
                }
                .padding()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if let resolution = selectedResolution {
                            onResolve(resolution)
                        }
                    }
                    .disabled(selectedResolution == nil)
                }
            }
        }
    }

    private var conflictHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Sync Conflict Detected")
                .font(.headline)

            Text("This \(conflict.entityType.rawValue) was modified both on this device and on the server.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Changes")
                .font(.headline)

            ForEach(conflict.conflictedFields, id: \.self) { field in
                ConflictFieldRow(
                    fieldName: field,
                    localValue: conflict.localData[field],
                    serverValue: conflict.serverData[field],
                    selectedValue: $mergedValues[field]
                )
            }
        }
    }

    private var resolutionOptions: some View {
        VStack(spacing: 12) {
            Text("Choose Resolution")
                .font(.headline)

            ResolutionButton(
                title: "Keep My Changes",
                subtitle: "Use the version from this device",
                icon: "iphone",
                isSelected: selectedResolution.isKeepLocal,
                action: { selectedResolution = .keepLocal }
            )

            ResolutionButton(
                title: "Keep Server Version",
                subtitle: "Use the version from the server",
                icon: "cloud",
                isSelected: selectedResolution.isKeepServer,
                action: { selectedResolution = .keepServer }
            )

            if !conflict.conflictedFields.isEmpty {
                ResolutionButton(
                    title: "Merge Changes",
                    subtitle: "Combine both versions",
                    icon: "arrow.triangle.merge",
                    isSelected: selectedResolution.isMerge,
                    action: { selectedResolution = .merge(mergedValues) }
                )
            }
        }
    }
}

struct ConflictFieldRow: View {
    let fieldName: String
    let localValue: Any?
    let serverValue: Any?
    @Binding var selectedValue: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(fieldName.camelCaseToTitle())
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                // Local value
                ValueCard(
                    label: "This Device",
                    value: localValue,
                    isSelected: isLocalSelected,
                    onTap: { selectedValue = localValue }
                )

                // Server value
                ValueCard(
                    label: "Server",
                    value: serverValue,
                    isSelected: isServerSelected,
                    onTap: { selectedValue = serverValue }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var isLocalSelected: Bool {
        guard let selected = selectedValue else { return false }
        return String(describing: selected) == String(describing: localValue)
    }

    private var isServerSelected: Bool {
        guard let selected = selectedValue else { return false }
        return String(describing: selected) == String(describing: serverValue)
    }
}

struct ValueCard: View {
    let label: String
    let value: Any?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(displayValue)
                    .font(.body)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var displayValue: String {
        guard let value = value else { return "Empty" }
        return String(describing: value)
    }
}

struct ResolutionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
```

### 4.4 Journal-Specific Conflict View (Rich Text Diff)

```swift
// File: Features/Sync/Views/JournalConflictView.swift

import SwiftUI

struct JournalConflictView: View {
    let conflict: SyncConflict
    let onResolve: (ConflictResolution) -> Void

    @State private var showDiff = true
    @State private var editedContent = ""
    @State private var selectedTab = 0

    var localContent: String {
        conflict.localData["content"] as? String ?? ""
    }

    var serverContent: String {
        conflict.serverData["content"] as? String ?? ""
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Side by Side").tag(0)
                    Text("Diff View").tag(1)
                    Text("Edit Merged").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on tab
                TabView(selection: $selectedTab) {
                    sideBySideView.tag(0)
                    diffView.tag(1)
                    mergeEditorView.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Action buttons
                actionButtons
            }
            .navigationTitle("Journal Entry Conflict")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            editedContent = localContent
        }
    }

    private var sideBySideView: some View {
        HStack(spacing: 1) {
            VStack(alignment: .leading) {
                Label("This Device", systemImage: "iphone")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal)

                ScrollView {
                    Text(localContent)
                        .padding()
                }
                .background(Color.blue.opacity(0.05))
            }

            VStack(alignment: .leading) {
                Label("Server", systemImage: "cloud")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)

                ScrollView {
                    Text(serverContent)
                        .padding()
                }
                .background(Color.green.opacity(0.05))
            }
        }
    }

    private var diffView: some View {
        ScrollView {
            DiffTextView(original: serverContent, modified: localContent)
                .padding()
        }
    }

    private var mergeEditorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Edit the merged content:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            TextEditor(text: $editedContent)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                Button {
                    onResolve(.keepServer)
                } label: {
                    Label("Keep Server", systemImage: "cloud")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onResolve(.keepLocal)
                } label: {
                    Label("Keep Mine", systemImage: "iphone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Button {
                var merged = conflict.localData
                merged["content"] = editedContent
                onResolve(.merge(merged))
            } label: {
                Label("Save Merged Version", systemImage: "arrow.triangle.merge")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct DiffTextView: View {
    let original: String
    let modified: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(computeDiff(), id: \.id) { line in
                HStack(spacing: 8) {
                    Text(line.prefix)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(line.color)
                        .frame(width: 20)

                    Text(line.text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(line.color)
                        .background(line.backgroundColor)
                }
            }
        }
    }

    private func computeDiff() -> [DiffLine] {
        // Simple line-by-line diff
        let originalLines = original.components(separatedBy: .newlines)
        let modifiedLines = modified.components(separatedBy: .newlines)

        var result: [DiffLine] = []
        var i = 0, j = 0

        while i < originalLines.count || j < modifiedLines.count {
            if i >= originalLines.count {
                result.append(DiffLine(text: modifiedLines[j], type: .added))
                j += 1
            } else if j >= modifiedLines.count {
                result.append(DiffLine(text: originalLines[i], type: .removed))
                i += 1
            } else if originalLines[i] == modifiedLines[j] {
                result.append(DiffLine(text: originalLines[i], type: .unchanged))
                i += 1
                j += 1
            } else {
                result.append(DiffLine(text: originalLines[i], type: .removed))
                result.append(DiffLine(text: modifiedLines[j], type: .added))
                i += 1
                j += 1
            }
        }

        return result
    }
}

struct DiffLine: Identifiable {
    let id = UUID()
    let text: String
    let type: DiffType

    enum DiffType {
        case unchanged, added, removed
    }

    var prefix: String {
        switch type {
        case .unchanged: return " "
        case .added: return "+"
        case .removed: return "-"
        }
    }

    var color: Color {
        switch type {
        case .unchanged: return .primary
        case .added: return .green
        case .removed: return .red
        }
    }

    var backgroundColor: Color {
        switch type {
        case .unchanged: return .clear
        case .added: return .green.opacity(0.1)
        case .removed: return .red.opacity(0.1)
        }
    }
}
```

### 4.5 Sync Status Banner

```swift
// File: Features/Sync/Views/SyncStatusBanner.swift

import SwiftUI

struct SyncStatusBanner: View {
    @Environment(SyncManager.self) var syncManager
    @Environment(NetworkMonitor.self) var networkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            offlineBanner
        } else if syncManager.pendingCount > 0 {
            pendingSyncBanner
        } else if syncManager.hasConflicts {
            conflictsBanner
        }
    }

    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("You're offline. Changes will sync when connected.")
            Spacer()
        }
        .font(.caption)
        .padding(8)
        .background(Color.orange.opacity(0.2))
        .foregroundColor(.orange)
    }

    private var pendingSyncBanner: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("\(syncManager.pendingCount) changes pending sync")
            Spacer()
            Button("Sync Now") {
                Task { await syncManager.syncNow() }
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .font(.caption)
        .padding(8)
        .background(Color.blue.opacity(0.1))
    }

    private var conflictsBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("\(syncManager.conflictCount) conflicts need resolution")
            Spacer()
            Button("Resolve") {
                syncManager.showConflictResolution = true
            }
            .font(.caption)
            .buttonStyle(.borderedProminent)
        }
        .font(.caption)
        .padding(8)
        .background(Color.orange.opacity(0.1))
    }
}
```

---

## Part 5: Implementation Checklist

### Phase 1: Foundation
- [ ] Add SwiftData to project (iOS 17+ required)
- [ ] Create OfflineDataContainer
- [ ] Create NetworkMonitor
- [ ] Add sync columns migration to Laravel
- [ ] Create SyncLog and ConflictResolution models in Laravel

### Phase 2: Cache Models
- [ ] CachedFamilyCircle + CachedFamilyMember
- [ ] CachedExpense
- [ ] CachedGoal + CachedGoalTask
- [ ] CachedJournalEntry
- [ ] CachedShoppingList + CachedShoppingItem
- [ ] CachedAsset

### Phase 3: Outbox System
- [ ] PendingOperation model
- [ ] OutboxManager
- [ ] Queue operations for each entity type

### Phase 4: Sync Service
- [ ] Laravel SyncController
- [ ] Laravel SyncService
- [ ] iOS SyncManager
- [ ] Background sync on network change

### Phase 5: Conflict Resolution
- [ ] ConflictConfiguration setup
- [ ] ConflictResolutionView
- [ ] JournalConflictView
- [ ] Auto-resolution for simple entities

### Phase 6: UI Integration
- [ ] SyncStatusBanner in main views
- [ ] Offline indicators on entities
- [ ] Pull-to-refresh triggers sync
- [ ] Settings page sync controls

---

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/sync/pull` | Get changes since last sync |
| POST | `/api/v1/sync/push` | Push local changes to server |
| POST | `/api/v1/sync/resolve` | Resolve a conflict |
| GET | `/api/v1/sync/conflicts` | Get pending conflicts |

---

## Testing Strategy

1. **Unit Tests**: Test conflict resolution strategies
2. **Integration Tests**: Test sync operations end-to-end
3. **Offline Simulation**: Use Network Link Conditioner
4. **Conflict Scenarios**: Test all entity types with conflicts
5. **Data Integrity**: Verify no data loss during sync

---

This implementation provides a robust offline-first architecture while maintaining data consistency through optimistic locking and user-friendly conflict resolution.
