import SwiftUI

struct RouteOverlayView: View {
    let route: RouteState
    let layouts: [String: ZoneLayout]
    let categories: [CustomCategory]

    private func routePoints(for size: CGSize) -> [CGPoint] {
        let startX = route.entrance == .left ? 0.05 * size.width : 0.95 * size.width
        let startPt = CGPoint(x: startX, y: size.height)

        var points: [CGPoint] = [startPt]
        for id in route.stops {
            if id == checkoutId {
                points.append(CGPoint(x: 0.5 * size.width, y: size.height))
            } else {
                let layout = layouts[id] ?? defaultZoneLayouts[id]
                if let l = layout {
                    points.append(CGPoint(x: (l.x + l.w/2) * size.width,
                                          y: (l.y + l.h/2) * size.height))
                }
            }
        }
        return points
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let points = routePoints(for: size)

            if points.count >= 2 {
                Path { path in
                    path.move(to: points[0])
                    for pt in points.dropFirst() { path.addLine(to: pt) }
                }
                .stroke(
                    Color.appRed.opacity(0.75),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4])
                )

                // Direction dots at midpoints
                ForEach(0..<points.count-1, id: \.self) { i in
                    let mid = CGPoint(x: (points[i].x + points[i+1].x)/2,
                                      y: (points[i].y + points[i+1].y)/2)
                    Circle()
                        .fill(Color.appRed)
                        .frame(width: 5, height: 5)
                        .position(mid)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
