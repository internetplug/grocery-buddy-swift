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
        return cats
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
}
