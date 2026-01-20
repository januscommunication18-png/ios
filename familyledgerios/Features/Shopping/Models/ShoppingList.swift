import Foundation

struct ShoppingList: Codable, Identifiable, Equatable {
    let id: Int
    var name: String
    let description: String?
    let storeName: String?
    let color: String?
    let icon: String?
    let isDefault: Bool?
    var itemsCount: Int?
    var purchasedCount: Int?
    var uncheckedCount: Int?
    let progressPercentageValue: StringOrDouble?
    var items: [ShoppingItem]?
    let createdAt: String?
    let updatedAt: String?

    var progressPercentage: Double? { progressPercentageValue?.doubleValue }

    enum CodingKeys: String, CodingKey {
        case id, name, description, color, icon, items
        case storeName = "store_name"
        case isDefault = "is_default"
        case itemsCount = "items_count"
        case purchasedCount = "purchased_count"
        case uncheckedCount = "unchecked_count"
        case progressPercentageValue = "progress_percentage"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: Int, name: String, description: String? = nil, storeName: String? = nil,
         color: String? = nil, icon: String? = nil, isDefault: Bool? = nil,
         itemsCount: Int? = nil, purchasedCount: Int? = nil, uncheckedCount: Int? = nil,
         progressPercentageValue: StringOrDouble? = nil, items: [ShoppingItem]? = nil,
         createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.storeName = storeName
        self.color = color
        self.icon = icon
        self.isDefault = isDefault
        self.itemsCount = itemsCount
        self.purchasedCount = purchasedCount
        self.uncheckedCount = uncheckedCount
        self.progressPercentageValue = progressPercentageValue
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
        lhs.id == rhs.id &&
        lhs.items?.count == rhs.items?.count &&
        lhs.name == rhs.name
    }
}

struct ShoppingItem: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let quantity: Int?
    let unit: String?
    let category: String?
    let isChecked: Bool?
    let isPurchased: Bool?
    let priceValue: StringOrDouble?
    let formattedPrice: String?
    let notes: String?
    let priority: String?
    let addedBy: String?
    let createdAt: String?
    let updatedAt: String?

    var price: Double? { priceValue?.doubleValue }

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, category, notes, priority
        case isChecked = "is_checked"
        case isPurchased = "is_purchased"
        case priceValue = "price"
        case formattedPrice = "formatted_price"
        case addedBy = "added_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(id: Int, name: String, quantity: Int? = nil, unit: String? = nil,
         category: String? = nil, isChecked: Bool? = nil, isPurchased: Bool? = nil,
         priceValue: StringOrDouble? = nil, formattedPrice: String? = nil,
         notes: String? = nil, priority: String? = nil, addedBy: String? = nil,
         createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.isPurchased = isPurchased
        self.priceValue = priceValue
        self.formattedPrice = formattedPrice
        self.notes = notes
        self.priority = priority
        self.addedBy = addedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        isChecked = try container.decodeIfPresent(Bool.self, forKey: .isChecked)
        isPurchased = try container.decodeIfPresent(Bool.self, forKey: .isPurchased)
        priceValue = try container.decodeIfPresent(StringOrDouble.self, forKey: .priceValue)
        formattedPrice = try container.decodeIfPresent(String.self, forKey: .formattedPrice)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        addedBy = try container.decodeIfPresent(String.self, forKey: .addedBy)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        // Handle quantity as either Int or String
        if let intQty = try? container.decodeIfPresent(Int.self, forKey: .quantity) {
            quantity = intQty
        } else if let strQty = try? container.decodeIfPresent(String.self, forKey: .quantity) {
            quantity = Int(strQty)
        } else {
            quantity = nil
        }
    }

    static func == (lhs: ShoppingItem, rhs: ShoppingItem) -> Bool {
        lhs.id == rhs.id && lhs.isChecked == rhs.isChecked
    }
}

struct ShoppingListsResponse: Codable {
    let lists: [ShoppingList]?
    let stats: ShoppingStats?
}

struct ShoppingStats: Codable {
    let totalLists: Int?
    let totalItems: Int?
    let completedItems: Int?
    let pendingItems: Int?

    enum CodingKeys: String, CodingKey {
        case totalLists = "total_lists"
        case totalItems = "total_items"
        case completedItems = "completed_items"
        case pendingItems = "pending_items"
    }
}

struct ShoppingListDetailResponse: Codable {
    let list: ShoppingList?
    let items: [ShoppingItem]?
    let stats: ShoppingDetailStats?
}

struct ShoppingDetailStats: Codable {
    let totalItems: Int?
    let purchasedItems: Int?
    let pendingItems: Int?
    let progressPercentageValue: StringOrDouble?

    var progressPercentage: Double? { progressPercentageValue?.doubleValue }

    enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case purchasedItems = "purchased_items"
        case pendingItems = "pending_items"
        case progressPercentageValue = "progress_percentage"
    }
}
