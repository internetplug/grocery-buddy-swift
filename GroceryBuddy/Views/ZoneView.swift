import SwiftUI

struct ZoneView: View {
    let category: CustomCategory
    let layout: ZoneLayout
    let canvasSize: CGSize
    let editMode: Bool
    let isSelected: Bool
    let hasPending: Bool
    let allDone: Bool
    let inRoute: Bool
    let notInRoute: Bool
    let stopIndex: Int?
    let onTap: () -> Void
    let onDelete: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let onResizeChanged: (DragGesture.Value) -> Void
    let onResizeEnded: (DragGesture.Value) -> Void

    private var bgColor: Color {
        if isSelected { return Color(hex: category.accentColor) }
        if allDone { return Color(hex: "#F0FFF4") }
        return Color(hex: category.color)
    }
    private var borderColor: Color {
        if hasPending { return Color(hex: category.accentColor) }
        if allDone { return Color.appGreen }
        return Color.black.opacity(0.06)
    }
    private var borderWidth: CGFloat { (hasPending || allDone) ? 2 : 1.5 }

    var body: some View {
        let x = layout.x * canvasSize.width
        let y = layout.y * canvasSize.height
        let w = layout.w * canvasSize.width
        let h = layout.h * canvasSize.height

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: borderWidth))
                .shadow(color: inRoute ? Color.appRed.opacity(0.4) : .clear, radius: 0, x: 0, y: 0)
                .overlay(inRoute ? RoundedRectangle(cornerRadius: 10).stroke(Color.appRed, lineWidth: 2) : nil)
                .opacity(notInRoute ? 0.4 : 1)

            VStack(spacing: 2) {
                Text(category.emoji).font(.system(size: h > 50 ? 16 : 11))
                Text(category.name)
                    .font(.system(size: h > 50 ? 9 : 7, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(hex: category.textColor))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Stop number badge
            if let n = stopIndex {
                Text("\(n)")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 15, height: 15)
                    .background(Color.appRed)
                    .clipShape(Circle())
                    .offset(x: 3, y: 3)
            }

            // Status dot
            if hasPending || allDone {
                Circle()
                    .fill(allDone ? Color.appGreen : Color.appRed)
                    .frame(width: 7, height: 7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 3).padding(.trailing, editMode ? 18 : 3)
            }

            // Delete button (edit mode)
            if editMode {
                Button { onDelete() } label: {
                    Circle().fill(Color(hex: "#FF5252"))
                        .frame(width: 14, height: 14)
                        .overlay(Image(systemName: "xmark").font(.system(size: 7, weight: .bold)).foregroundColor(.white))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(2)
                .buttonStyle(.plain)
            }

            // Resize handle (edit mode)
            if editMode {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 14, height: 14)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(2)
                    .gesture(
                        DragGesture()
                            .onChanged { onResizeChanged($0) }
                            .onEnded { onResizeEnded($0) }
                    )
            }
        }
        .frame(width: w, height: h)
        .position(x: x + w/2, y: y + h/2)
        .gesture(
            editMode
            ? DragGesture()
                .onChanged { onDragChanged($0) }
                .onEnded { onDragEnded($0) }
            : nil
        )
        .onTapGesture { if !editMode { onTap() } }
    }
}
