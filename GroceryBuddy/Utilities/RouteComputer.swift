import Foundation

struct RouteComputer {
    static func compute(
        entrance: RouteState.Entrance,
        categories: [CustomCategory],
        layouts: [String: ZoneLayout],
        pendingCategoryIds: Set<String>
    ) -> [String] {
        let eligible = categories.filter { cat in
            guard pendingCategoryIds.contains(cat.id) else { return false }
            let layout = layouts[cat.id] ?? defaultZoneLayouts[cat.id]
            return layout != nil
        }
        guard !eligible.isEmpty else { return [checkoutId] }

        let start: (x: Double, y: Double) = entrance == .left ? (0.05, 1.0) : (0.95, 1.0)
        var centers: [String: (x: Double, y: Double)] = [:]
        for cat in eligible {
            let layout = layouts[cat.id] ?? defaultZoneLayouts[cat.id]
            if let l = layout {
                centers[cat.id] = (l.x + l.w / 2, l.y + l.h / 2)
            }
        }

        var unvisited = Set(eligible.map { $0.id })
        var route: [String] = []
        var cur = start

        while !unvisited.isEmpty {
            var nearest: String? = nil
            var nearestDist = Double.infinity
            for id in unvisited {
                if let c = centers[id] {
                    let d = hypot(c.x - cur.x, c.y - cur.y)
                    if d < nearestDist { nearestDist = d; nearest = id }
                }
            }
            guard let next = nearest else { break }
            route.append(next)
            cur = centers[next]!
            unvisited.remove(next)
        }

        route.append(checkoutId)
        return route
    }
}
