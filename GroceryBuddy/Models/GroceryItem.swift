import Foundation

struct GroceryItem: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var quantity: Int
    var categoryId: String
    var checked: Bool
    var addedAt: TimeInterval

    static func new(name: String, categoryId: String) -> GroceryItem {
        GroceryItem(
            id: UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "").prefix(8).description,
            name: name,
            quantity: 1,
            categoryId: categoryId,
            checked: false,
            addedAt: Date().timeIntervalSince1970 * 1000
        )
    }

    init(id: String, name: String, quantity: Int, categoryId: String, checked: Bool, addedAt: TimeInterval) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.categoryId = categoryId
        self.checked = checked
        self.addedAt = addedAt
    }

    // Lenient decoding so items synced before quantity was numeric (string or
    // missing) still load, defaulting to a count of 1.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        categoryId = try c.decode(String.self, forKey: .categoryId)
        checked = try c.decode(Bool.self, forKey: .checked)
        addedAt = try c.decode(TimeInterval.self, forKey: .addedAt)
        if let q = try? c.decode(Int.self, forKey: .quantity) {
            quantity = max(1, q)
        } else {
            quantity = 1
        }
    }
}
