import Foundation

struct SavedLayoutSlot: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var layouts: [String: ZoneLayout]
    var savedAt: TimeInterval
}
