import SwiftUI
import SwiftData
import UIKit

struct AddShoppingItemRequest: Encodable {
    let name: String
    let quantity: Int?
    let category: String?
}

struct AddShoppingItemResponse: Decodable {
    let item: ShoppingItem?
}

@Observable
final class ShoppingViewModel {
    var lists: [ShoppingList] = []
    var selectedList: ShoppingList?
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?

    // Offline state
    var isOffline: Bool { !NetworkMonitor.shared.isConnected }
    var hasPendingChanges: Bool { OutboxManager.shared.pendingCount > 0 }

    // Form fields for adding items
    var newItemName = ""
    var newItemQuantity = 1
    var newItemCategory = "other"

    // Categories
    static let categories = [
        ("produce", "Produce", "leaf.fill"),
        ("dairy", "Dairy", "drop.fill"),
        ("meat", "Meat", "fork.knife"),
        ("bakery", "Bakery", "birthday.cake.fill"),
        ("frozen", "Frozen", "snowflake"),
        ("beverages", "Beverages", "cup.and.saucer.fill"),
        ("snacks", "Snacks", "popcorn.fill"),
        ("household", "Household", "house.fill"),
        ("pharmacy", "Pharmacy", "cross.case.fill"),
        ("other", "Other", "cart.fill")
    ]

    @MainActor
    func loadLists() async {
        isLoading = lists.isEmpty

        // Try to load from cache first if offline
        if isOffline {
            loadListsFromCache()
            isLoading = false
            return
        }

        // Sync pending changes first when online
        await SyncManager.shared.syncIfNeeded()

        do {
            let response: ShoppingListsResponse = try await APIClient.shared.request(.shoppingLists)
            var serverLists = response.lists ?? []
            // Cache the lists
            cacheListsToLocal(serverLists)
            // Merge with any local-only lists that haven't synced yet
            let pendingLists = getPendingLocalLists()
            serverLists.append(contentsOf: pendingLists)
            lists = serverLists
        } catch {
            // Fall back to cache on error
            loadListsFromCache()
            if lists.isEmpty {
                errorMessage = "Failed to load lists"
            }
        }
        isLoading = false
    }

    @MainActor
    func refreshLists() async {
        isRefreshing = true

        // Sync pending changes first if online
        if !isOffline {
            await SyncManager.shared.syncIfNeeded()
        }

        do {
            let response: ShoppingListsResponse = try await APIClient.shared.request(.shoppingLists)
            var serverLists = response.lists ?? []
            cacheListsToLocal(serverLists)
            // Merge with any local-only lists that haven't synced yet
            let pendingLists = getPendingLocalLists()
            serverLists.append(contentsOf: pendingLists)
            lists = serverLists
        } catch {
            loadListsFromCache()
        }
        isRefreshing = false
    }

    /// Get locally-created lists that haven't been synced to server yet
    @MainActor
    private func getPendingLocalLists() -> [ShoppingList] {
        let context = OfflineDataContainer.shared.context
        let pendingCreateStatus = SyncStatus.pendingCreate.rawValue
        let descriptor = FetchDescriptor<CachedShoppingList>(
            predicate: #Predicate<CachedShoppingList> { cached in
                cached.syncStatus == pendingCreateStatus
            }
        )

        guard let pendingCached = try? context.fetch(descriptor) else { return [] }

        return pendingCached.map { cached in
            let displayId = -abs(cached.localId.hashValue)
            return ShoppingList(
                id: displayId,
                name: cached.name,
                description: cached.listDescription,
                storeName: cached.storeName,
                color: cached.color,
                icon: cached.icon,
                isDefault: cached.isDefault,
                itemsCount: cached.itemsCount,
                purchasedCount: cached.purchasedCount,
                uncheckedCount: cached.uncheckedCount,
                localId: cached.localId
            )
        }
    }

    @MainActor
    func loadList(id: Int) async {
        isLoading = true
        errorMessage = nil

        // If ID is negative, this is an offline-created list - load from cache only
        if id < 0 {
            if let cached = loadListFromCache(serverId: id) {
                selectedList = cached
            } else {
                errorMessage = "List not found"
            }
            isLoading = false
            return
        }

        // Try cache first if offline
        if isOffline {
            if let cached = loadListFromCache(serverId: id) {
                selectedList = cached
                isLoading = false
                return
            }
        }

        do {
            let response: ShoppingListDetailResponse = try await APIClient.shared.request(.shoppingList(id: id))
            if var list = response.list {
                list.items = response.items
                if let items = response.items {
                    list.itemsCount = items.count
                    list.purchasedCount = items.filter { $0.isChecked == true }.count
                    list.uncheckedCount = items.filter { $0.isChecked != true }.count
                }
                selectedList = list
                // Cache list with items
                cacheListDetailToLocal(list)
            } else if let items = response.items {
                let list = ShoppingList(
                    id: id,
                    name: "Shopping List",
                    itemsCount: items.count,
                    purchasedCount: items.filter { $0.isChecked == true }.count,
                    uncheckedCount: items.filter { $0.isChecked != true }.count,
                    items: items
                )
                selectedList = list
            } else {
                errorMessage = "List not found"
            }
        } catch let error as APIError {
            // Try cache on error
            if let cached = loadListFromCache(serverId: id) {
                selectedList = cached
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            if let cached = loadListFromCache(serverId: id) {
                selectedList = cached
            } else {
                errorMessage = "Failed to load list"
            }
        }
        isLoading = false
    }

    @MainActor
    func refreshList(id: Int) async {
        // Offline-created lists (negative ID) - just reload from cache
        if id < 0 || isOffline {
            if let cached = loadListFromCache(serverId: id) {
                selectedList = cached
            }
            return
        }

        do {
            let response: ShoppingListDetailResponse = try await APIClient.shared.request(.shoppingList(id: id))
            if var list = response.list {
                list.items = response.items
                if let items = response.items {
                    list.itemsCount = items.count
                    list.purchasedCount = items.filter { $0.isChecked == true }.count
                    list.uncheckedCount = items.filter { $0.isChecked != true }.count
                }
                selectedList = list
                cacheListDetailToLocal(list)
            }
        } catch { }
    }

    @MainActor
    func toggleItem(listId: Int, itemId: Int) async {
        // Optimistically update UI
        if var list = selectedList, var items = list.items,
           let index = items.firstIndex(where: { $0.id == itemId }) {
            let item = items[index]
            let newItem = ShoppingItem(
                id: item.id,
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                category: item.category,
                isChecked: !(item.isChecked ?? false),
                isPurchased: !(item.isChecked ?? false),
                priceValue: item.priceValue,
                formattedPrice: item.formattedPrice,
                notes: item.notes,
                priority: item.priority,
                addedBy: item.addedBy,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            )
            items[index] = newItem
            list.items = items
            selectedList = list

            // Update cache
            toggleItemInCache(listServerId: listId, itemServerId: itemId)
        }

        if isOffline {
            // Queue for later sync
            queueToggleItem(listId: listId, itemId: itemId)
            return
        }

        do {
            try await APIClient.shared.requestEmpty(.toggleShoppingItem(listId: listId, itemId: itemId))
        } catch {
            // Queue for retry if failed
            queueToggleItem(listId: listId, itemId: itemId)
        }

        await refreshList(id: listId)
    }

    @MainActor
    func addItem(listId: Int) async -> Bool {
        guard !newItemName.isEmpty else { return false }

        let itemName = newItemName
        let itemQty = newItemQuantity
        let itemCat = newItemCategory

        // Reset form immediately for better UX
        newItemName = ""
        newItemQuantity = 1

        if isOffline {
            // Add to cache and queue
            addItemToCache(listServerId: listId, name: itemName, quantity: itemQty, category: itemCat)
            return true
        }

        do {
            let body = AddShoppingItemRequest(
                name: itemName,
                quantity: itemQty > 1 ? itemQty : nil,
                category: itemCat
            )
            let _: AddShoppingItemResponse = try await APIClient.shared.request(.addShoppingItem(listId: listId), body: body)
            await refreshList(id: listId)
            return true
        } catch {
            // Add to cache on error
            addItemToCache(listServerId: listId, name: itemName, quantity: itemQty, category: itemCat)
            await refreshList(id: listId)
            return true
        }
    }

    @MainActor
    func deleteItem(listId: Int, itemId: Int) async {
        // Optimistically remove from UI
        if var list = selectedList, var items = list.items {
            items.removeAll { $0.id == itemId }
            list.items = items
            selectedList = list

            // Remove from cache
            deleteItemFromCache(listServerId: listId, itemServerId: itemId)
        }

        if isOffline {
            queueDeleteItem(listId: listId, itemId: itemId)
            return
        }

        do {
            try await APIClient.shared.requestEmpty(.deleteShoppingItem(listId: listId, itemId: itemId))
            await refreshList(id: listId)
        } catch {
            queueDeleteItem(listId: listId, itemId: itemId)
        }
    }

    @MainActor
    func clearChecked(listId: Int) async {
        if isOffline {
            // Clear checked items from cache
            clearCheckedItemsFromCache(listServerId: listId)
            if let cached = loadListFromCache(serverId: listId) {
                selectedList = cached
            }
            return
        }

        do {
            try await APIClient.shared.requestEmpty(.clearCheckedItems(listId: listId))
            await refreshList(id: listId)
        } catch { }
    }

    // MARK: - Cache Operations

    @MainActor
    private func loadListsFromCache() {
        let context = OfflineDataContainer.shared.context
        let deletedStatus = SyncStatus.pendingDelete.rawValue
        let descriptor = FetchDescriptor<CachedShoppingList>(
            predicate: #Predicate<CachedShoppingList> { cached in
                cached.syncStatus != deletedStatus
            },
            sortBy: [SortDescriptor(\CachedShoppingList.localUpdatedAt, order: .reverse)]
        )

        if let cachedLists = try? context.fetch(descriptor) {
            lists = cachedLists.map { cached in
                // Use negative hash for offline-created lists (no server ID yet)
                let displayId = cached.serverId ?? -abs(cached.localId.hashValue)
                return ShoppingList(
                    id: displayId,
                    name: cached.name,
                    description: cached.listDescription,
                    storeName: cached.storeName,
                    color: cached.color,
                    icon: cached.icon,
                    isDefault: cached.isDefault,
                    itemsCount: cached.itemsCount,
                    purchasedCount: cached.purchasedCount,
                    uncheckedCount: cached.uncheckedCount,
                    localId: cached.localId  // Store localId for offline lookup
                )
            }
        }
    }

    @MainActor
    private func cacheListsToLocal(_ apiLists: [ShoppingList]) {
        let context = OfflineDataContainer.shared.context

        for apiList in apiLists {
            let serverId = apiList.id
            let descriptor = FetchDescriptor<CachedShoppingList>(
                predicate: #Predicate { $0.serverId == serverId }
            )

            if let existing = try? context.fetch(descriptor).first {
                // Update existing if synced
                if existing.currentSyncStatus == .synced {
                    existing.name = apiList.name
                    existing.listDescription = apiList.description
                    existing.storeName = apiList.storeName
                    existing.color = apiList.color
                    existing.icon = apiList.icon
                    existing.isDefault = apiList.isDefault ?? false
                    existing.lastSyncedAt = Date()
                }
            } else {
                // Create new
                let cached = CachedShoppingList.from(apiList)
                context.insert(cached)
            }
        }

        try? context.save()
    }

    @MainActor
    private func loadListFromCache(serverId: Int, localId: UUID? = nil) -> ShoppingList? {
        let context = OfflineDataContainer.shared.context
        var cached: CachedShoppingList?

        // If negative ID or localId provided, search by localId
        if serverId < 0 || localId != nil {
            // Fetch all and filter in Swift (UUID comparisons don't work well in #Predicate)
            let allDescriptor = FetchDescriptor<CachedShoppingList>()
            if let allLists = try? context.fetch(allDescriptor) {
                if let lid = localId {
                    cached = allLists.first { $0.localId == lid }
                } else {
                    // Find by hash match
                    cached = allLists.first { -abs($0.localId.hashValue) == serverId }
                }
            }
        } else {
            // Normal server ID lookup
            let descriptor = FetchDescriptor<CachedShoppingList>(
                predicate: #Predicate { $0.serverId == serverId }
            )
            cached = try? context.fetch(descriptor).first
        }

        guard let cached = cached else { return nil }

        // Fetch items for this list
        let deletedStatus = SyncStatus.pendingDelete.rawValue
        let listLocalId = cached.localId
        let listServerId = cached.serverId

        // Items can be associated by serverId or by parent relationship
        let allItemsDescriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate<CachedShoppingItem> { item in
                item.syncStatus != deletedStatus
            }
        )

        let allItems = (try? context.fetch(allItemsDescriptor)) ?? []
        let cachedItems = allItems.filter { item in
            // Match by serverId if available, or by parent relationship
            if let sid = listServerId, item.shoppingListServerId == sid {
                return true
            }
            // Check if parent relationship matches
            if item.shoppingList?.localId == listLocalId {
                return true
            }
            return false
        }

        let items = cachedItems.map { item in
            ShoppingItem(
                id: item.serverId ?? -abs(item.localId.hashValue),
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                category: item.category,
                isChecked: item.isChecked,
                isPurchased: item.isChecked,
                priceValue: item.price.map { StringOrDouble.double($0) },
                notes: item.notes,
                priority: item.priority
            )
        }

        let displayId = cached.serverId ?? -abs(cached.localId.hashValue)
        return ShoppingList(
            id: displayId,
            name: cached.name,
            description: cached.listDescription,
            storeName: cached.storeName,
            color: cached.color,
            icon: cached.icon,
            isDefault: cached.isDefault,
            itemsCount: items.count,
            purchasedCount: items.filter { $0.isChecked == true }.count,
            uncheckedCount: items.filter { $0.isChecked != true }.count,
            items: items,
            localId: cached.localId
        )
    }

    @MainActor
    private func cacheListDetailToLocal(_ list: ShoppingList) {
        let context = OfflineDataContainer.shared.context
        let serverId = list.id

        // Cache list
        let listDescriptor = FetchDescriptor<CachedShoppingList>(
            predicate: #Predicate { $0.serverId == serverId }
        )

        let cachedList: CachedShoppingList
        if let existing = try? context.fetch(listDescriptor).first {
            if existing.currentSyncStatus == .synced {
                existing.updateFromServer(list)
            }
            cachedList = existing
        } else {
            cachedList = CachedShoppingList.from(list)
            context.insert(cachedList)
        }

        // Cache items
        if let items = list.items {
            for item in items {
                let itemServerId = item.id
                let itemDescriptor = FetchDescriptor<CachedShoppingItem>(
                    predicate: #Predicate { $0.serverId == itemServerId }
                )

                if let existingItem = try? context.fetch(itemDescriptor).first {
                    if existingItem.currentSyncStatus == .synced {
                        existingItem.updateFromServer(item)
                    }
                } else {
                    let cachedItem = CachedShoppingItem.from(item, listServerId: serverId)
                    cachedItem.shoppingList = cachedList
                    context.insert(cachedItem)
                }
            }
        }

        try? context.save()
    }

    @MainActor
    private func toggleItemInCache(listServerId: Int, itemServerId: Int) {
        let context = OfflineDataContainer.shared.context
        let descriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate { $0.serverId == itemServerId }
        )

        if let item = try? context.fetch(descriptor).first {
            item.toggle()
            try? context.save()
        }
    }

    @MainActor
    private func addItemToCache(listServerId: Int, name: String, quantity: Int, category: String) {
        let context = OfflineDataContainer.shared.context
        var parentList: CachedShoppingList?

        // Find parent list - handle offline-created lists with negative IDs
        if listServerId < 0 {
            // Search by localId hash
            let allDescriptor = FetchDescriptor<CachedShoppingList>()
            if let allLists = try? context.fetch(allDescriptor) {
                parentList = allLists.first { -abs($0.localId.hashValue) == listServerId }
            }
        } else {
            let listDescriptor = FetchDescriptor<CachedShoppingList>(
                predicate: #Predicate { $0.serverId == listServerId }
            )
            parentList = try? context.fetch(listDescriptor).first
        }

        // Use parent's serverId if available, otherwise nil for offline lists
        let actualServerId = parentList?.serverId

        let newItem = CachedShoppingItem(
            name: name,
            quantity: quantity,
            category: category,
            shoppingListServerId: actualServerId
        )

        if let parentList = parentList {
            newItem.shoppingList = parentList
        }

        context.insert(newItem)

        // Only queue for sync if we have a valid server ID (i.e., list was synced)
        if let actualServerId = actualServerId {
            do {
                try OutboxManager.shared.queueCreate(
                    entityType: .shoppingItem,
                    localEntityId: newItem.localId,
                    endpoint: "/shopping/\(actualServerId)/items",
                    payload: newItem.toCreateRequest(),
                    parentServerId: actualServerId
                )
            } catch {
                print("[ShoppingViewModel] Failed to queue item creation: \(error)")
            }
        } else {
            // For offline-created lists, items will be synced when the list is synced
            print("[ShoppingViewModel] Item added to offline list - will sync when list syncs")
        }

        try? context.save()

        // Update selectedList
        if let cached = loadListFromCache(serverId: listServerId) {
            selectedList = cached
        }
    }

    @MainActor
    private func deleteItemFromCache(listServerId: Int, itemServerId: Int) {
        let context = OfflineDataContainer.shared.context
        let descriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate { $0.serverId == itemServerId }
        )

        if let item = try? context.fetch(descriptor).first {
            item.markAsDeleted()
            try? context.save()
        }
    }

    @MainActor
    private func clearCheckedItemsFromCache(listServerId: Int) {
        let context = OfflineDataContainer.shared.context
        let descriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate { $0.shoppingListServerId == listServerId && $0.isChecked == true }
        )

        if let items = try? context.fetch(descriptor) {
            for item in items {
                item.markAsDeleted()
            }
            try? context.save()
        }
    }

    // MARK: - Queue Operations

    @MainActor
    private func queueToggleItem(listId: Int, itemId: Int) {
        let context = OfflineDataContainer.shared.context
        let descriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate { $0.serverId == itemId }
        )

        if let item = try? context.fetch(descriptor).first {
            do {
                try OutboxManager.shared.queueToggle(
                    entityType: .shoppingItem,
                    localEntityId: item.localId,
                    serverId: itemId,
                    endpoint: "/shopping/\(listId)/items/\(itemId)/toggle"
                )
            } catch {
                print("[ShoppingViewModel] Failed to queue toggle: \(error)")
            }
        }
    }

    @MainActor
    private func queueDeleteItem(listId: Int, itemId: Int) {
        let context = OfflineDataContainer.shared.context
        let descriptor = FetchDescriptor<CachedShoppingItem>(
            predicate: #Predicate { $0.serverId == itemId }
        )

        if let item = try? context.fetch(descriptor).first {
            do {
                try OutboxManager.shared.queueDelete(
                    entityType: .shoppingItem,
                    localEntityId: item.localId,
                    serverId: itemId,
                    endpoint: "/shopping/\(listId)/items/\(itemId)"
                )
            } catch {
                print("[ShoppingViewModel] Failed to queue delete: \(error)")
            }
        }
    }
}

struct ShoppingListsView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ShoppingViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading lists...")
            } else if viewModel.lists.isEmpty {
                EmptyStateView.noShoppingLists { router.navigate(to: .createShoppingList) }
            } else {
                List(viewModel.lists) { list in
                    Button { router.navigate(to: .shoppingList(id: list.id)) } label: {
                        HStack {
                            Image(systemName: "cart.fill").foregroundColor(AppColors.shopping)
                            VStack(alignment: .leading) {
                                HStack(spacing: 6) {
                                    Text(list.name).font(AppTypography.headline)
                                    // Pending indicator for offline-created lists
                                    if list.isOfflineCreated {
                                        Text("Pending")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange)
                                            .cornerRadius(4)
                                    }
                                }
                                Text("\(list.uncheckedCount ?? 0) remaining").font(AppTypography.caption).foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Text("\(Int(list.progressPercentage ?? 0))%").font(AppTypography.labelMedium).foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Shopping Lists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.navigate(to: .createShoppingList) } label: { Image(systemName: "plus") }
            }
        }
        .task { await viewModel.loadLists() }
    }
}

struct ShoppingDetailView: View {
    let listId: Int
    @State private var viewModel = ShoppingViewModel()
    // @State private var isStoreMode = false // Commented out - Store Mode disabled for now
    @State private var hasLoaded = false
    @State private var refreshID = UUID()
    @FocusState private var isAddFieldFocused: Bool
    @State private var showShareSheet = false
    @State private var showPrintError = false

    var body: some View {
        Group {
            if viewModel.isLoading && !hasLoaded {
                LoadingView(message: "Loading list...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadList(id: listId) }
                }
            } else if let list = viewModel.selectedList {
                // Store Mode commented out for now
                // if isStoreMode {
                //     storeModeContent(list: list)
                //         .id(refreshID)
                // } else {
                    addModeContent(list: list)
                        .id(refreshID)
                // }
            } else if !viewModel.isLoading {
                // No list and not loading - show error
                VStack(spacing: 16) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textTertiary)
                    Text("Unable to load shopping list")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                    Button("Try Again") {
                        Task { await viewModel.loadList(id: listId) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LoadingView(message: "Loading list...")
            }
        }
        .navigationTitle(viewModel.selectedList?.name ?? "Shopping List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // Share/Print Menu
                Menu {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        printList()
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                }

                // Store Mode Toggle - Commented out for now
                // Button {
                //     withAnimation { isStoreMode.toggle() }
                // } label: {
                //     Label(isStoreMode ? "Add Mode" : "Store Mode",
                //           systemImage: isStoreMode ? "plus.circle" : "cart.fill")
                // }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let list = viewModel.selectedList {
                ShareSheet(activityItems: [generateShareText(list: list)])
            }
        }
        .alert("Print Error", isPresented: $showPrintError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to print. Please make sure a printer is available.")
        }
        .task {
            await viewModel.loadList(id: listId)
            hasLoaded = true
        }
        .refreshable { await viewModel.refreshList(id: listId) }
    }

    // MARK: - Share/Print/Email Functions

    private func generateShareText(list: ShoppingList) -> String {
        var text = "🛒 \(list.name)\n"
        if let items = list.items {
            let uncheckedItems = items.filter { $0.isChecked != true }
            let checkedItems = items.filter { $0.isChecked == true }

            if !uncheckedItems.isEmpty {
                text += "\n📋 To Buy:\n"
                for item in uncheckedItems {
                    let qty = item.quantity ?? 1
                    text += "• \(item.name)\(qty > 1 ? " ×\(qty)" : "")\n"
                }
            }

            if !checkedItems.isEmpty {
                text += "\n✅ Purchased:\n"
                for item in checkedItems {
                    let qty = item.quantity ?? 1
                    text += "• \(item.name)\(qty > 1 ? " ×\(qty)" : "")\n"
                }
            }
        }
        text += "\n— Shared from Meet Olliee"
        return text
    }

    private func printList() {
        guard let list = viewModel.selectedList else { return }

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = list.name

        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo

        // Create printable content
        let formatter = UIMarkupTextPrintFormatter(markupText: generatePrintHTML(list: list))
        formatter.perPageContentInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
        printController.printFormatter = formatter

        printController.present(animated: true) { _, completed, error in
            if !completed && error != nil {
                showPrintError = true
            }
        }
    }

    private func generatePrintHTML(list: ShoppingList) -> String {
        var html = """
        <html>
        <head>
            <style>
                body { font-family: -apple-system, Helvetica, Arial, sans-serif; }
                h1 { font-size: 24px; margin-bottom: 4px; }
                h2 { font-size: 16px; color: #666; margin-top: 20px; }
                .date { color: #999; font-size: 12px; margin-bottom: 20px; }
                ul { list-style: none; padding: 0; }
                li { padding: 8px 0; border-bottom: 1px solid #eee; }
                .checkbox { display: inline-block; width: 16px; height: 16px; border: 2px solid #ccc; border-radius: 4px; margin-right: 12px; }
                .checked { text-decoration: line-through; color: #999; }
            </style>
        </head>
        <body>
            <h1>\(list.name)</h1>
            <p class="date">\(Date().formatted(date: .long, time: .omitted))</p>
        """

        if let items = list.items {
            let uncheckedItems = items.filter { $0.isChecked != true }
            let checkedItems = items.filter { $0.isChecked == true }

            if !uncheckedItems.isEmpty {
                html += "<h2>To Buy (\(uncheckedItems.count))</h2><ul>"
                for item in uncheckedItems {
                    let qty = item.quantity ?? 1
                    html += "<li><span class=\"checkbox\"></span>\(item.name)\(qty > 1 ? " ×\(qty)" : "")</li>"
                }
                html += "</ul>"
            }

            if !checkedItems.isEmpty {
                html += "<h2>Purchased (\(checkedItems.count))</h2><ul>"
                for item in checkedItems {
                    let qty = item.quantity ?? 1
                    html += "<li class=\"checked\">✓ \(item.name)\(qty > 1 ? " ×\(qty)" : "")</li>"
                }
                html += "</ul>"
            }
        }

        html += "</body></html>"
        return html
    }

    private func emailList() {
        guard let list = viewModel.selectedList else { return }

        let subject = "Shopping List: \(list.name)"
        let body = generateShareText(list: list)

        // URL encode the subject and body
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Add Mode Content

    private func addModeContent(list: ShoppingList) -> some View {
        VStack(spacing: 0) {
            // Quick Add Section
            quickAddSection

            // Stats Bar
            statsBar(list: list)

            // Items List with swipe support
            let uncheckedItems = (list.items ?? []).filter { $0.isChecked != true }
            let checkedItems = (list.items ?? []).filter { $0.isChecked == true }
            let groupedItems = Dictionary(grouping: uncheckedItems) { $0.category ?? "other" }

            List {
                // Unchecked Items by Category
                ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                    if let items = groupedItems[category] {
                        Section {
                            ForEach(items) { item in
                                itemRowForList(item: item)
                            }
                        } header: {
                            let categoryInfo = ShoppingViewModel.categories.first { $0.0 == category } ?? ("other", "Other", "cart.fill")
                            HStack(spacing: 8) {
                                Image(systemName: categoryInfo.2)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.shopping)
                                Text(categoryInfo.1.uppercased())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }

                // Checked Items
                if !checkedItems.isEmpty {
                    Section {
                        ForEach(checkedItems) { item in
                            itemRowForList(item: item)
                        }
                    } header: {
                        HStack {
                            Text("PURCHASED")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Button("Clear") {
                                Task { await viewModel.clearChecked(listId: listId) }
                            }
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func itemRowForList(item: ShoppingItem) -> some View {
        let isChecked = item.isChecked == true

        return HStack(spacing: 12) {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isChecked ? AppColors.success : AppColors.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(isChecked ? AppColors.textTertiary : AppColors.textPrimary)
                        .strikethrough(isChecked)

                    // Pending indicator for offline-created items
                    if item.isOfflineCreated {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            if let qty = item.quantity, qty > 1 {
                Text("×\(qty)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.shopping)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.shopping.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await viewModel.toggleItem(listId: listId, itemId: item.id)
                refreshID = UUID()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                Task {
                    await viewModel.toggleItem(listId: listId, itemId: item.id)
                    refreshID = UUID()
                }
            } label: {
                Label(isChecked ? "Unmark" : "Purchased", systemImage: isChecked ? "arrow.uturn.backward" : "cart.badge.checkmark")
            }
            .tint(isChecked ? .orange : AppColors.success)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteItem(listId: listId, itemId: item.id)
                    refreshID = UUID()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var quickAddSection: some View {
        VStack(spacing: 12) {
            // Add Item Field
            HStack(spacing: 12) {
                TextField("Add item...", text: $viewModel.newItemName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .focused($isAddFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        Task {
                            await viewModel.addItem(listId: listId)
                            refreshID = UUID()
                        }
                    }

                Button {
                    Task {
                        await viewModel.addItem(listId: listId)
                        refreshID = UUID()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(AppColors.shopping)
                        .cornerRadius(12)
                }
                .disabled(viewModel.newItemName.isEmpty)
            }

            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShoppingViewModel.categories, id: \.0) { category in
                        Button {
                            viewModel.newItemCategory = category.0
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.2)
                                    .font(.system(size: 10))
                                Text(category.1)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.newItemCategory == category.0 ? AppColors.shopping : Color(.systemGray5))
                            .foregroundColor(viewModel.newItemCategory == category.0 ? .white : AppColors.textPrimary)
                            .cornerRadius(16)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppColors.background)
    }

    private func statsBar(list: ShoppingList) -> some View {
        let items = list.items ?? []
        let toBuy = items.filter { $0.isChecked != true }.count
        let done = items.filter { $0.isChecked == true }.count

        return HStack {
            HStack(spacing: 4) {
                Text("\(toBuy)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.warning)
                Text("to buy")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Pending sync indicator for offline-created lists
            if list.isOfflineCreated {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                    Text("Pending Sync")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange)
                .cornerRadius(6)

                Spacer()
            }

            HStack(spacing: 4) {
                Text("\(done)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.success)
                Text("done")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.background)
    }

    private func categorySection(category: String, items: [ShoppingItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                let categoryInfo = ShoppingViewModel.categories.first { $0.0 == category } ?? ("other", "Other", "cart.fill")
                Image(systemName: categoryInfo.2)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.shopping)
                Text(categoryInfo.1.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ForEach(items) { item in
                swipeableItemRow(item: item)
            }
        }
    }

    private func swipeableItemRow(item: ShoppingItem) -> some View {
        let isChecked = item.isChecked == true

        return HStack(spacing: 12) {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isChecked ? AppColors.success : AppColors.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(isChecked ? AppColors.textTertiary : AppColors.textPrimary)
                        .strikethrough(isChecked)

                    // Pending indicator for offline-created items
                    if item.isOfflineCreated {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            if let qty = item.quantity, qty > 1 {
                Text("×\(qty)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.shopping)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.shopping.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(AppColors.background)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                Task {
                    await viewModel.toggleItem(listId: listId, itemId: item.id)
                    refreshID = UUID()
                }
            } label: {
                Label(isChecked ? "Unmark" : "Purchased", systemImage: isChecked ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(isChecked ? .orange : AppColors.success)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteItem(listId: listId, itemId: item.id)
                    refreshID = UUID()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func itemRow(item: ShoppingItem, isStoreMode: Bool) -> some View {
        let isChecked = item.isChecked == true

        return Button {
            Task {
                await viewModel.toggleItem(listId: listId, itemId: item.id)
                refreshID = UUID()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: isStoreMode ? 28 : 22))
                    .foregroundColor(isChecked ? AppColors.success : AppColors.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(isStoreMode ? AppTypography.headline : AppTypography.bodyMedium)
                        .foregroundColor(isChecked ? AppColors.textTertiary : AppColors.textPrimary)
                        .strikethrough(isChecked)

                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                if let qty = item.quantity, qty > 1 {
                    Text("×\(qty)")
                        .font(.system(size: isStoreMode ? 16 : 14, weight: .medium))
                        .foregroundColor(AppColors.shopping)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.shopping.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, isStoreMode ? 16 : 12)
            .background(AppColors.background)
            .cornerRadius(isStoreMode ? 16 : 0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, isStoreMode ? 16 : 0)
    }

    // MARK: - Store Mode Content

    private func storeModeContent(list: ShoppingList) -> some View {
        let items = list.items ?? []
        let uncheckedItems = items.filter { $0.isChecked != true }
        let checkedItems = items.filter { $0.isChecked == true }
        let total = items.count
        let progress = total > 0 ? Double(checkedItems.count) / Double(total) : 0

        return VStack(spacing: 0) {
            // Store Mode Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(list.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Store Mode")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(uncheckedItems.count)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("items left")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(AppColors.shopping)

            // Items List
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Unchecked Items
                    ForEach(uncheckedItems) { item in
                        storeItemCard(item: item, isChecked: false)
                    }

                    // Checked Items
                    if !checkedItems.isEmpty {
                        HStack {
                            Text("DONE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        ForEach(checkedItems) { item in
                            storeItemCard(item: item, isChecked: true)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private func storeItemCard(item: ShoppingItem, isChecked: Bool) -> some View {
        Button {
            Task {
                await viewModel.toggleItem(listId: listId, itemId: item.id)
                refreshID = UUID()
            }
        } label: {
            HStack(spacing: 16) {
                // Large Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isChecked ? AppColors.success : Color(.systemGray3), lineWidth: 3)
                        .frame(width: 44, height: 44)

                    if isChecked {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.success)
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Item Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isChecked ? AppColors.textTertiary : AppColors.textPrimary)
                            .strikethrough(isChecked)

                        if let qty = item.quantity, qty > 1 {
                            Text("×\(qty)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.shopping)
                                .cornerRadius(8)
                        }
                    }

                    if let category = item.category {
                        let categoryInfo = ShoppingViewModel.categories.first { $0.0 == category } ?? ("other", "Other", "cart.fill")
                        HStack(spacing: 4) {
                            Image(systemName: categoryInfo.2)
                                .font(.system(size: 10))
                            Text(categoryInfo.1)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(isChecked ? AppColors.success.opacity(0.1) : AppColors.background)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isChecked ? AppColors.success.opacity(0.3) : Color(.systemGray4), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CreateShoppingListRequest: Encodable {
    let name: String
    let storeName: String?
    let color: String

    enum CodingKeys: String, CodingKey {
        case name
        case storeName = "store_name"
        case color
    }
}

struct CreateShoppingListResponse: Decodable {
    let list: ShoppingList?
}

struct CreateShoppingListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ShoppingViewModel()
    @State private var name = ""
    @State private var selectedStore = ""
    @State private var selectedColor = "emerald"
    @State private var isCreating = false

    // Stores matching web app
    private let stores: [(String, String)] = [
        ("", "No specific store"),
        ("grocery", "Grocery Store"),
        ("costco", "Costco"),
        ("sams_club", "Sam's Club"),
        ("target", "Target"),
        ("walmart", "Walmart"),
        ("amazon", "Amazon"),
        ("whole_foods", "Whole Foods"),
        ("trader_joes", "Trader Joe's"),
        ("pharmacy", "Pharmacy"),
        ("home_depot", "Home Depot"),
        ("lowes", "Lowe's"),
        ("other", "Other")
    ]

    // Colors matching web app
    private let colors: [(String, String, Color)] = [
        ("emerald", "Emerald", Color(red: 16/255, green: 185/255, blue: 129/255)),
        ("teal", "Teal", Color(red: 20/255, green: 184/255, blue: 166/255)),
        ("sky", "Sky", Color(red: 14/255, green: 165/255, blue: 233/255)),
        ("blue", "Blue", Color(red: 59/255, green: 130/255, blue: 246/255)),
        ("violet", "Violet", Color(red: 139/255, green: 92/255, blue: 246/255)),
        ("amber", "Amber", Color(red: 245/255, green: 158/255, blue: 11/255)),
        ("orange", "Orange", Color(red: 249/255, green: 115/255, blue: 22/255)),
        ("rose", "Rose", Color(red: 244/255, green: 63/255, blue: 94/255))
    ]

    var body: some View {
        Form {
            // List Name Section
            Section {
                TextField("e.g., Weekly Groceries, Costco Run", text: $name)
            } header: {
                HStack {
                    Text("List Name")
                    Text("*").foregroundColor(.red)
                }
            }

            // Store Section
            Section {
                Picker("Store", selection: $selectedStore) {
                    ForEach(stores, id: \.0) { store in
                        Text(store.1).tag(store.0)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Store (Optional)")
            }

            // Color Section
            Section {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 44))
                ], spacing: 12) {
                    ForEach(colors, id: \.0) { color in
                        Button {
                            selectedColor = color.0
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color.2)
                                    .frame(width: 40, height: 40)

                                if selectedColor == color.0 {
                                    Circle()
                                        .stroke(color.2, lineWidth: 3)
                                        .frame(width: 50, height: 50)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Color")
            }
        }
        .navigationTitle("Create Shopping List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { await createList() }
                }
                .disabled(name.isEmpty || isCreating)
            }
        }
        .disabled(isCreating)
        .overlay {
            if isCreating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Creating...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
        }
    }

    private func createList() async {
        isCreating = true

        let storeName = selectedStore.isEmpty ? nil : stores.first { $0.0 == selectedStore }?.1

        // Check if offline
        print("[CreateList] NetworkMonitor.isConnected = \(NetworkMonitor.shared.isConnected)")
        if !NetworkMonitor.shared.isConnected {
            print("[CreateList] OFFLINE - Creating locally")
            await createListOffline(name: name, storeName: storeName, color: selectedColor)
            await MainActor.run { router.goBack() }
            isCreating = false
            return
        }

        do {
            print("[CreateList] ONLINE - Sending to server...")
            let body = CreateShoppingListRequest(
                name: name,
                storeName: storeName,
                color: selectedColor
            )
            let response: CreateShoppingListResponse = try await APIClient.shared.request(.createShoppingList, body: body)
            print("[CreateList] SUCCESS - Server created list with ID: \(response.list?.id ?? -1)")
            await MainActor.run { router.goBack() }
        } catch {
            print("[CreateList] ERROR - \(error). Falling back to offline creation.")
            await createListOffline(name: name, storeName: storeName, color: selectedColor)
            await MainActor.run { router.goBack() }
        }
        isCreating = false
    }

    @MainActor
    private func createListOffline(name: String, storeName: String?, color: String) {
        let context = OfflineDataContainer.shared.context

        let newList = CachedShoppingList(
            name: name,
            storeName: storeName,
            color: color
        )

        context.insert(newList)

        // Queue for sync
        do {
            try OutboxManager.shared.queueCreate(
                entityType: .shoppingList,
                localEntityId: newList.localId,
                endpoint: "/api/v1/shopping",
                payload: newList.toCreateRequest()
            )
        } catch {
            print("[CreateShoppingListView] Failed to queue list creation: \(error)")
        }

        try? context.save()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
