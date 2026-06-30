import Foundation

struct LocalStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Items
    static func loadItems() -> [GroceryItem] {
        guard let data = UserDefaults.standard.data(forKey: "gb_items"),
              let items = try? decoder.decode([GroceryItem].self, from: data) else { return [] }
        return items
    }
    static func saveItems(_ items: [GroceryItem]) {
        UserDefaults.standard.set(try? encoder.encode(items), forKey: "gb_items")
    }

    // MARK: - Categories
    static func loadCategories() -> [CustomCategory] {
        guard let data = UserDefaults.standard.data(forKey: "gb_categories"),
              let cats = try? decoder.decode([CustomCategory].self, from: data) else { return defaultCategories }
        return refreshBuiltinDescriptions(cats)
    }

    // Built-in descriptions are code-owned: replace `aisle` on any built-in
    // category with the value from defaultCategories. Custom categories pass through.
    static func refreshBuiltinDescriptions(_ cats: [CustomCategory]) -> [CustomCategory] {
        let defaultsById = Dictionary(uniqueKeysWithValues: defaultCategories.map { ($0.id, $0) })
        return cats.map { cat in
            guard cat.builtin, let def = defaultsById[cat.id] else { return cat }
            var updated = cat
            updated.aisle = def.aisle
            return updated
        }
    }

    static func saveCategories(_ cats: [CustomCategory]) {
        UserDefaults.standard.set(try? encoder.encode(cats), forKey: "gb_categories")
    }

    // MARK: - Map Layout
    static func loadMapLayout() -> [String: ZoneLayout] {
        guard let data = UserDefaults.standard.data(forKey: "gb_map_layout"),
              let layouts = try? decoder.decode([String: ZoneLayout].self, from: data) else { return [:] }
        return layouts
    }
    static func saveMapLayout(_ layouts: [String: ZoneLayout]) {
        UserDefaults.standard.set(try? encoder.encode(layouts), forKey: "gb_map_layout")
    }

    // MARK: - Saved Layouts
    static func loadSavedLayouts() -> [SavedLayoutSlot] {
        guard let data = UserDefaults.standard.data(forKey: "gb_saved_layouts"),
              let slots = try? decoder.decode([SavedLayoutSlot].self, from: data) else { return [] }
        return slots
    }
    static func saveSavedLayouts(_ slots: [SavedLayoutSlot]) {
        UserDefaults.standard.set(try? encoder.encode(slots), forKey: "gb_saved_layouts")
    }

    // MARK: - Saved Item Lists
    static func loadSavedItemLists() -> [SavedItemListSlot] {
        guard let data = UserDefaults.standard.data(forKey: "gb_saved_item_lists"),
              let slots = try? decoder.decode([SavedItemListSlot].self, from: data) else { return [] }
        return slots
    }
    static func saveSavedItemLists(_ slots: [SavedItemListSlot]) {
        UserDefaults.standard.set(try? encoder.encode(slots), forKey: "gb_saved_item_lists")
    }

    // MARK: - Item History
    static func loadItemHistory() -> [ItemHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: "gb_item_history"),
              let h = try? decoder.decode([ItemHistoryEntry].self, from: data) else { return [] }
        return h
    }
    static func saveItemHistory(_ h: [ItemHistoryEntry]) {
        UserDefaults.standard.set(try? encoder.encode(h), forKey: "gb_item_history")
    }
}
