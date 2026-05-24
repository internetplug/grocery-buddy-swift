import Foundation

struct RouteComputer {
    // MARK: - Public API

    static func compute(
        entrance: RouteState.Entrance,
        categories: [CustomCategory],
        layouts: [String: ZoneLayout],
        pendingCategoryIds: Set<String>
    ) -> [String] {
        // Filter to eligible categories (have pending items and a layout)
        let eligible = categories.filter { cat in
            guard pendingCategoryIds.contains(cat.id) else { return false }
            let layout = layouts[cat.id] ?? defaultZoneLayouts[cat.id]
            return layout != nil
        }
        guard !eligible.isEmpty else { return [checkoutId] }

        // Set start point from entrance
        let start: (x: Double, y: Double) = entrance == .left ? (0.05, 1.0) : (0.95, 1.0)

        // Build ordered stop centers (stable ordering from eligible)
        let ids = eligible.map { $0.id }
        let stopCenters: [(x: Double, y: Double)] = ids.map { id in
            let l = layouts[id] ?? defaultZoneLayouts[id]!
            return (l.x + l.w / 2, l.y + l.h / 2)
        }

        let n = ids.count
        let stride = n + 2  // [start, stop0..stopN-1, checkout]
        let mat = buildDistMatrix(start: start, stops: stopCenters)

        // Choose algorithm based on stop count
        let heldKarpThreshold = 12
        let perm: [Int]
        if n <= heldKarpThreshold {
            perm = heldKarp(n: n, matStride: stride, mat: mat)
        } else {
            var p = nearestNeighborIndices(n: n, matStride: stride, mat: mat)
            twoOptImprove(route: &p, n: n, matStride: stride, mat: mat)
            perm = p
        }

        // Convert permutation back to category IDs and append checkout
        var route = perm.map { ids[$0] }
        route.append(checkoutId)
        return route
    }

    // MARK: - Private Helpers

    private static func dist(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double)) -> Double {
        let dx = a.x - b.x, dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Build distance matrix: index 0=start, 1..n=stops, n+1=checkout(0.5, 1.0)
    /// Returns flat array with stride (n+2)
    private static func buildDistMatrix(
        start: (x: Double, y: Double),
        stops: [(x: Double, y: Double)]
    ) -> [Double] {
        let n = stops.count
        let total = n + 2
        let checkout = (x: 0.5, y: 1.0)

        var pts = [(x: Double, y: Double)]()
        pts.reserveCapacity(total)
        pts.append(start)
        pts.append(contentsOf: stops)
        pts.append(checkout)

        var mat = [Double](repeating: 0.0, count: total * total)
        for i in 0..<total {
            for j in 0..<total {
                mat[i * total + j] = dist(pts[i], pts[j])
            }
        }
        return mat
    }

    /// Nearest-neighbor greedy: start at 0, repeatedly pick closest unvisited
    /// Returns permutation [0..<n] of stop indices
    private static func nearestNeighborIndices(
        n: Int,
        matStride: Int,
        mat: [Double]
    ) -> [Int] {
        var unvisited = Array(0..<n)
        var route = [Int]()
        route.reserveCapacity(n)

        var curIdx = 0  // start at index 0 (start point)
        while !unvisited.isEmpty {
            var bestJ = 0
            var bestD = Double.infinity
            for (pos, j) in unvisited.enumerated() {
                let d = mat[curIdx * matStride + (j + 1)]  // j+1 because index 0 is start
                if d < bestD {
                    bestD = d
                    bestJ = pos
                }
            }
            let next = unvisited.remove(at: bestJ)
            route.append(next)
            curIdx = next + 1  // next time start from this stop's index
        }
        return route
    }

    /// Held-Karp exact TSP using bitmask DP
    /// n <= 12 recommended; returns permutation [0..<n] of stop indices
    private static func heldKarp(
        n: Int,
        matStride: Int,
        mat: [Double]
    ) -> [Int] {
        let states = (1 << n) * n
        var dp = [Float](repeating: .infinity, count: states)
        var parent = [Int32](repeating: -1, count: states)

        // Seed: start (index 0) → each stop i (index i+1 in distance matrix)
        for i in 0..<n {
            dp[(1 << i) * n + i] = Float(mat[0 * matStride + (i + 1)])
        }

        // DP transitions: for each subset mask and last visited stop
        for mask in 1..<(1 << n) {
            let base = mask * n
            for last in 0..<n {
                guard mask & (1 << last) != 0 else { continue }
                let curCost = dp[base + last]
                guard curCost < .infinity else { continue }

                // Try extending to each unvisited stop
                for nxt in 0..<n {
                    guard mask & (1 << nxt) == 0 else { continue }
                    let newMask = mask | (1 << nxt)
                    let cost = curCost + Float(mat[(last + 1) * matStride + (nxt + 1)])
                    let idx = newMask * n + nxt
                    if cost < dp[idx] {
                        dp[idx] = cost
                        parent[idx] = Int32(last)
                    }
                }
            }
        }

        // Find best last stop before returning to checkout
        let fullMask = (1 << n) - 1
        let fullBase = fullMask * n
        var bestLast = 0
        var bestTotal = Float.infinity
        for i in 0..<n {
            let total = dp[fullBase + i] + Float(mat[(i + 1) * matStride + (n + 1)])
            if total < bestTotal {
                bestTotal = total
                bestLast = i
            }
        }

        // Reconstruct path by following parent pointers backwards
        var path = [Int]()
        path.reserveCapacity(n)
        var mask = fullMask
        var cur = bestLast
        while cur != -1 {
            path.append(cur)
            let prev = Int(parent[mask * n + cur])
            mask ^= (1 << cur)
            cur = prev
        }
        return path.reversed()
    }

    /// 2-opt improvement: iteratively reverse sub-segments to reduce total distance
    private static func twoOptImprove(
        route: inout [Int],
        n: Int,
        matStride: Int,
        mat: [Double]
    ) {
        guard route.count >= 2 else { return }

        var improved = true
        while improved {
            improved = false
            for i in 0..<route.count - 1 {
                for j in (i + 2)..<route.count {
                    // Current tour: start(0) → ... → route[i] → ... → route[j] → ... → checkout(n+1)
                    // We're considering reversing route[i+1...j]

                    let iNode = route[i] + 1  // convert to distance matrix index
                    let iPred = i == 0 ? 0 : route[i - 1] + 1
                    let jNode = route[j] + 1
                    let jSucc = j == route.count - 1 ? n + 1 : route[j + 1] + 1

                    let before = mat[iPred * matStride + iNode] + mat[jNode * matStride + jSucc]
                    let after = mat[iPred * matStride + jNode] + mat[iNode * matStride + jSucc]

                    if after < before - 1e-10 {
                        route[i + 1...j].reverse()
                        improved = true
                    }
                }
            }
        }
    }
}
