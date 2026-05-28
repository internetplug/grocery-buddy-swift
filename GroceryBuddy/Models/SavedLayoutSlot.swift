import Foundation

struct SavedLayoutSlot: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var layouts: [String: ZoneLayout]
    var deletedCategoryIds: [String] = []
    var customCategories: [CustomCategory] = []
    var savedAt: TimeInterval
}
