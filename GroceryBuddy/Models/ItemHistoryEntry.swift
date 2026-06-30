import Foundation

struct ItemHistoryEntry: Codable, Equatable {
    var name: String
    var categoryId: String
    var count: Int
    var lastAddedAt: TimeInterval
}
