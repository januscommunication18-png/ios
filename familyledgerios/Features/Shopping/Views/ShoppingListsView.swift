import SwiftUI

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
        do {
            let response: ShoppingListsResponse = try await APIClient.shared.request(.shoppingLists)
            lists = response.lists ?? []
        } catch {
            errorMessage = "Failed to load lists"
        }
        isLoading = false
    }

    @MainActor
    func refreshLists() async {
        isRefreshing = true
        do {
            let response: ShoppingListsResponse = try await APIClient.shared.request(.shoppingLists)
            lists = response.lists ?? []
        } catch { }
        isRefreshing = false
    }

    @MainActor
    func loadList(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let response: ShoppingListDetailResponse = try await APIClient.shared.request(.shoppingList(id: id))
            if var list = response.list {
                list.items = response.items
                // Update counts from items
                if let items = response.items {
                    list.itemsCount = items.count
                    list.purchasedCount = items.filter { $0.isChecked == true }.count
                    list.uncheckedCount = items.filter { $0.isChecked != true }.count
                }
                selectedList = list
            } else if let items = response.items {
                // API might return items without a list wrapper - create a minimal list
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
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load list"
        }
        isLoading = false
    }

    @MainActor
    func refreshList(id: Int) async {
        do {
            let response: ShoppingListDetailResponse = try await APIClient.shared.request(.shoppingList(id: id))
            if var list = response.list {
                list.items = response.items
                // Update counts from items
                if let items = response.items {
                    list.itemsCount = items.count
                    list.purchasedCount = items.filter { $0.isChecked == true }.count
                    list.uncheckedCount = items.filter { $0.isChecked != true }.count
                }
                selectedList = list
            }
        } catch { }
    }

    @MainActor
    func toggleItem(listId: Int, itemId: Int) async {
        // Optimistically update UI by toggling the item locally first
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
        }

        do {
            // API returns wrapped response, but we don't need the result
            try await APIClient.shared.requestEmpty(.toggleShoppingItem(listId: listId, itemId: itemId))
        } catch { }

        // Refresh to sync with server
        await refreshList(id: listId)
    }

    @MainActor
    func addItem(listId: Int) async -> Bool {
        guard !newItemName.isEmpty else { return false }
        do {
            let body = AddShoppingItemRequest(
                name: newItemName,
                quantity: newItemQuantity > 1 ? newItemQuantity : nil,
                category: newItemCategory
            )
            // API returns {item: {...}} wrapped response
            let _: AddShoppingItemResponse = try await APIClient.shared.request(.addShoppingItem(listId: listId), body: body)
            newItemName = ""
            newItemQuantity = 1
            await refreshList(id: listId)
            return true
        } catch {
            // Item might still be added even if decode fails - refresh to check
            newItemName = ""
            newItemQuantity = 1
            await refreshList(id: listId)
            return true
        }
    }

    @MainActor
    func deleteItem(listId: Int, itemId: Int) async {
        do {
            try await APIClient.shared.requestEmpty(.deleteShoppingItem(listId: listId, itemId: itemId))
            await refreshList(id: listId)
        } catch { }
    }

    @MainActor
    func clearChecked(listId: Int) async {
        do {
            try await APIClient.shared.requestEmpty(.clearCheckedItems(listId: listId))
            await refreshList(id: listId)
        } catch { }
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
                                Text(list.name).font(AppTypography.headline)
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
    @State private var isStoreMode = false
    @State private var hasLoaded = false
    @State private var refreshID = UUID()
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        Group {
            if viewModel.isLoading && !hasLoaded {
                LoadingView(message: "Loading list...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.loadList(id: listId) }
                }
            } else if let list = viewModel.selectedList {
                if isStoreMode {
                    storeModeContent(list: list)
                        .id(refreshID)
                } else {
                    addModeContent(list: list)
                        .id(refreshID)
                }
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
                Button {
                    withAnimation { isStoreMode.toggle() }
                } label: {
                    Label(isStoreMode ? "Add Mode" : "Store Mode",
                          systemImage: isStoreMode ? "plus.circle" : "cart.fill")
                }
            }
        }
        .task {
            await viewModel.loadList(id: listId)
            hasLoaded = true
        }
        .refreshable { await viewModel.refreshList(id: listId) }
    }

    // MARK: - Add Mode Content

    private func addModeContent(list: ShoppingList) -> some View {
        VStack(spacing: 0) {
            // Quick Add Section
            quickAddSection

            // Stats Bar
            statsBar(list: list)

            // Items List
            ScrollView {
                LazyVStack(spacing: 8) {
                    let uncheckedItems = (list.items ?? []).filter { $0.isChecked != true }
                    let checkedItems = (list.items ?? []).filter { $0.isChecked == true }

                    // Unchecked Items by Category
                    let groupedItems = Dictionary(grouping: uncheckedItems) { $0.category ?? "other" }
                    ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                        if let items = groupedItems[category] {
                            categorySection(category: category, items: items)
                        }
                    }

                    // Checked Items
                    if !checkedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PURCHASED")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Button("Clear") {
                                    Task { await viewModel.clearChecked(listId: listId) }
                                }
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)

                            ForEach(checkedItems) { item in
                                itemRow(item: item, isStoreMode: false)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
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
                itemRow(item: item, isStoreMode: false)
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
        do {
            let body = CreateShoppingListRequest(
                name: name,
                storeName: selectedStore.isEmpty ? nil : stores.first { $0.0 == selectedStore }?.1,
                color: selectedColor
            )
            let _: CreateShoppingListResponse = try await APIClient.shared.request(.createShoppingList, body: body)
            await MainActor.run { router.goBack() }
        } catch {
            // Still go back on error - list might have been created
            await MainActor.run { router.goBack() }
        }
        isCreating = false
    }
}
