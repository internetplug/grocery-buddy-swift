import Foundation

struct SavedItemListSlot: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var items: [GroceryItem]
    var savedAt: TimeInterval
}
