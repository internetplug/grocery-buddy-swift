import Foundation

struct RouteState: Codable, Equatable {
    enum Entrance: String, Codable { case left, right }
    var entrance: Entrance
    var stops: [String] // ordered categoryIds, last is "__checkout__"
}

let checkoutId = "__checkout__"
