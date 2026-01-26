import SwiftData
import Foundation

@MainActor
final class OfflineDataContainer {
    static let shared = OfflineDataContainer()

    let container: ModelContainer
    let context: ModelContext

    // Alias for convenience
    var mainContext: ModelContext { context }

    private init() {
        let schema = Schema([
            CachedShoppingList.self,
            CachedShoppingItem.self,
            CachedGoal.self,
            CachedGoalTask.self,
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
            print("[OfflineDataContainer] Successfully initialized SwiftData container")
        } catch {
            fatalError("[OfflineDataContainer] Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Helper Methods

    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    func clearAllData() throws {
        try context.delete(model: CachedShoppingList.self)
        try context.delete(model: CachedShoppingItem.self)
        try context.delete(model: CachedGoal.self)
        try context.delete(model: CachedGoalTask.self)
        try context.delete(model: CachedAsset.self)
        try context.delete(model: PendingOperation.self)
        try save()
        print("[OfflineDataContainer] Cleared all cached data")
    }
}
