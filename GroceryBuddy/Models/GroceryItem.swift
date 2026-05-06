import Foundation

struct GroceryItem: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var quantity: String
    var categoryId: String
    var checked: Bool
    var addedAt: TimeInterval

    static func new(name: String, quantity: String, categoryId: String) -> GroceryItem {
        GroceryItem(
            id: UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "").prefix(8).description,
            name: name,
            quantity: quantity,
            categoryId: categoryId,
            checked: false,
            addedAt: Date().timeIntervalSince1970 * 1000
        )
    }
}
