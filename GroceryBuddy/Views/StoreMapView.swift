import SwiftUI

struct StoreMapView: View {
    @EnvironmentObject var vm: AppViewModel
    var onSwitchToList: (() -> Void)? = nil
    @State private var editMode = false
    @State private var selectedCat: String? = nil
    @State private var addDeptOpen = false
    @State private var editDeptOpen = false
    @State private var entrancePickerOpen = false
    @State private var layoutManagerOpen = false
    @State private var showResetConfirmation = false
    @State private var isMapZoomed = false
    @State private var isReorderingRoute = false
    @State private var reorderItemsCat: String? = nil

    private let mapAspect: CGFloat = 1.5   // width : height

    var pendingCats: Set<String> { Set(vm.items.filter { !$0.checked }.map { $0.categoryId }) }
    var doneCats: Set<String>    { Set(vm.items.filter {  $0.checked }.map { $0.categoryId }) }
    var hasPendingItems: Bool    { !pendingCats.isEmpty }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                MapCanvasView(
                    editMode: editMode,
                    selectedCat: $selectedCat,
                    pendingCats: pendingCats,
                    doneCats: doneCats,
                    isZoomed: $isMapZoomed
                )
                .aspectRatio(mapAspect, contentMode: .fit)
                .padding(.horizontal, 14)
                mapEdgeLabels
                if !editMode {
                    routeButton
                        .padding(.horizontal, 14).padding(.top, 12)
                    if vm.route != nil, onSwitchToList != nil {
                        backToListButton
                            .padding(.horizontal, 14).padding(.top, 10)
                    }
                }
                // Add / Edit department buttons (edit mode)
                if editMode {
                    VStack(spacing: 8) {
                        Button { addDeptOpen = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Add Department")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appDark)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button { editDeptOpen = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Edit Departments")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.appDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1.5))
                        }
                    }
                    .padding(.horizontal, 14).padding(.top, 12)
                }
                if let r = vm.route, !r.stops.isEmpty {
                    routePanel(r)
                }
                selectedPanel
            }
            .padding(.bottom, 24)
            .contentShape(Rectangle())
            .onTapGesture { if editMode { selectedCat = nil } }
        }
        .scrollDisabled(isMapZoomed || (editMode && selectedCat != nil))
        .background(Color.appBg)
        .onChange(of: vm.route?.stops.isEmpty ?? true) { _, isEmpty in
            if isEmpty { isReorderingRoute = false }
        }
        .sheet(isPresented: $addDeptOpen) { AddDepartmentSheet() }
        .sheet(isPresented: $editDeptOpen) { EditDepartmentSheet() }
        .sheet(isPresented: $entrancePickerOpen) { EntrancePickerSheet() }
        .sheet(isPresented: $layoutManagerOpen) { LayoutManagerSheet() }
        .sheet(item: Binding(
            get: { reorderItemsCat.map { ReorderItemsTarget(id: $0) } },
            set: { reorderItemsCat = $0?.id }
        )) { target in
            ReorderItemsSheet(categoryId: target.id)
        }
        .alert("Reset Layout?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset to Default", role: .destructive) {
                vm.resetMapLayout()
            }
        } message: {
            Text("This will restore the default layout, bring back any deleted departments, and remove all custom departments along with their items.")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                (Text("Store").foregroundColor(.appDark) + Text("Map").foregroundColor(.appRed))
                    .font(.system(size: 27, weight: .black))
                Spacer()
                HStack(spacing: 8) {
                    // Layouts button
                    Button { layoutManagerOpen = true } label: {
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#5C6BC0"))
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E0E0E0"), lineWidth: 1.5))
                    }
                    // Edit button
                    Button {
                        withAnimation { editMode.toggle() }
                        selectedCat = nil
                        if editMode { vm.clearRoute() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: editMode ? "checkmark" : "pencil")
                                .font(.system(size: 13, weight: .semibold))
                            Text(editMode ? "Done" : "Edit Map")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(editMode ? .white : .appDark)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .frame(minWidth: 100)
                        .background(editMode ? Color.appDark : Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.08), radius: 3)
                    }
                }
            }

            Text(editMode ? "Tap to select · drag to move · corner to resize · pinch to zoom"
                 : vm.route != nil ? "Route active · tap stop to see items"
                 : "Tap a department to see your items")
                .font(.system(size: 12)).foregroundColor(.appGray)
                .lineLimit(2)

            // Legend
            HStack(spacing: 12) {
                legendDot(color: "#E91E2C", label: "Has items")
                legendDot(color: "#4CAF78", label: "All done")
                legendDot(color: "#E0E0E0", label: "Empty")
                Spacer()
                Button("Reset") { showResetConfirmation = true }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.appRed)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .overlay(Capsule().stroke(Color(hex: "#FFCDD2"), lineWidth: 1.5))
                    .opacity(editMode ? 1 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private func legendDot(color: String, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(Color(hex: color)).frame(width: 9, height: 9)
            Text(label).font(.system(size: 11)).foregroundColor(.appGray)
        }
    }

    // MARK: - Map edge labels (below the map border)
    private var mapEdgeLabels: some View {
        HStack(spacing: 0) {
            Text("Entrance")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(vm.route?.entrance == .left ? .appRed : .appGray)
            Spacer()
            Text("Checkout")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.appRed)
            Spacer()
            Text("Entrance")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(vm.route?.entrance == .right ? .appRed : .appGray)
        }
        .padding(.horizontal, 26)
        .padding(.top, 6)
    }

    // MARK: - Route button
    private var routeButton: some View {
        Button {
            if vm.route != nil { vm.clearRoute() }
            else { entrancePickerOpen = true }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: vm.route != nil ? "xmark" : "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                Text(vm.route != nil ? "Clear Route" : "Route")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(vm.route != nil ? .white : (hasPendingItems ? .appRed : Color(hex: "#B0B0B0")))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(vm.route != nil ? Color.appRed : (hasPendingItems ? Color(hex: "#FFF0F1") : Color(hex: "#F0F0F0")))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!hasPendingItems && vm.route == nil)
    }

    // MARK: - Back to list button
    private var backToListButton: some View {
        Button { onSwitchToList?() } label: {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
                Text("Back to Shopping List")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.appDark)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
    }

    // MARK: - Route panel
    private func routePanel(_ r: RouteState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#FFF0F1"))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "arrow.right").foregroundColor(.appRed).font(.system(size: 14)))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Your Route").font(.system(size: 15, weight: .black)).foregroundColor(.appDark)
                    Text("\(r.entrance == .left ? "Left" : "Right") entrance · \(r.stops.filter { $0 != checkoutId }.count) stops + checkout")
                        .font(.system(size: 11)).foregroundColor(.appGray)
                }
                Spacer()
                if r.stops.filter({ $0 != checkoutId }).count > 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isReorderingRoute.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isReorderingRoute ? "checkmark" : "arrow.up.arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                            Text(isReorderingRoute ? "Done" : "Reorder")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(isReorderingRoute ? .white : .appDark)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(isReorderingRoute ? Color.appRed : Color(hex: "#F0F0F0"))
                        .clipShape(Capsule())
                    }
                }
            }

            if isReorderingRoute {
                List {
                    ForEach(Array(r.stops.enumerated()), id: \.element) { idx, catId in
                        stopRowCard(idx: idx, catId: catId, r: r, showChevron: false)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .deleteDisabled(true)
                            .moveDisabled(catId == checkoutId)
                    }
                    .onMove { vm.moveRouteStops(from: $0, to: $1) }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                .frame(height: CGFloat(r.stops.count) * 78)
            } else {
                ForEach(Array(r.stops.enumerated()), id: \.element) { idx, catId in
                    if catId == checkoutId {
                        stopRowCard(idx: idx, catId: catId, r: r, showChevron: false)
                    } else {
                        Button { selectedCat = (selectedCat == catId ? nil : catId) } label: {
                            stopRowCard(idx: idx, catId: catId, r: r, showChevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    @ViewBuilder
    private func stopRowCard(idx: Int, catId: String, r: RouteState, showChevron: Bool) -> some View {
        if catId == checkoutId {
            let allDone = r.stops.filter { $0 != checkoutId }.allSatisfy { !pendingCats.contains($0) }
            HStack(spacing: 12) {
                Circle()
                    .fill(allDone ? Color.appGreen : Color.appRed)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if allDone { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white) }
                            else { Text("\(idx+1)").font(.system(size: 11, weight: .black)).foregroundColor(.white) }
                        }
                    )
                Text("🛒").font(.system(size: 20))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Checkout").font(.system(size: 14, weight: .semibold)).foregroundColor(allDone ? .appGreen : .white)
                    Text(allDone ? "Ready to go!" : "Front registers · center").font(.system(size: 11)).foregroundColor(Color(hex: "#8A8AAA"))
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 10)
            .background(allDone ? Color(hex: "#F0FFF4") : Color.appDark)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else if let cat = vm.categories.first(where: { $0.id == catId }) {
            let catItems = vm.items.filter { $0.categoryId == catId && !$0.checked }
            let isDone = catItems.isEmpty && vm.items.contains(where: { $0.categoryId == catId && $0.checked })
            HStack(spacing: 12) {
                Circle()
                    .fill(isDone ? Color.appGreen : Color(hex: cat.accentColor))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if isDone { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white) }
                            else { Text("\(idx+1)").font(.system(size: 11, weight: .black)).foregroundColor(.white) }
                        }
                    )
                Text(cat.emoji).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 1) {
                    Text(cat.name).font(.system(size: 14, weight: .semibold)).foregroundColor(isDone ? Color(hex: "#C0C0C0") : .appDark)
                    Text(isDone ? "Done ✓" : "\(catItems.count) item\(catItems.count != 1 ? "s" : "") left")
                        .font(.system(size: 11)).foregroundColor(.appGray)
                }
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.appGray)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 10)
            .background(Color(hex: isDone ? "#F0FFF4" : cat.color))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Selected category detail panel
    @ViewBuilder
    private var selectedPanel: some View {
        if !editMode, let id = selectedCat, let cat = vm.categories.first(where: { $0.id == id }) {
            let catItems = vm.items.filter { $0.categoryId == id }
            if !catItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(cat.emoji).font(.system(size: 20))
                        Text(cat.name).font(.system(size: 15, weight: .bold)).foregroundColor(.appDark)
                        Spacer()
                        Text("\(catItems.filter { !$0.checked }.count) left")
                            .font(.system(size: 12)).foregroundColor(.appGray)
                        if catItems.count > 1 {
                            Button { reorderItemsCat = id } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.appDark)
                                    .padding(6)
                                    .background(Color(hex: "#F0F0F0"))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    ForEach(catItems) { item in ItemRowView(item: item) }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.22), value: selectedCat)
            }
        }
    }
}

// MARK: - Map Canvas (isolated for performance)
// Owns only pan/zoom — the heavy zone content lives in MapContentView so
// per-frame pan updates don't re-evaluate the ForEach.
private struct MapCanvasView: View {
    @EnvironmentObject var vm: AppViewModel
    let editMode: Bool
    @Binding var selectedCat: String?
    let pendingCats: Set<String>
    let doneCats: Set<String>
    @Binding var isZoomed: Bool

    // Zoom/pan state. basePan holds the committed offset; panDelta is the
    // transient gesture delta. @GestureState bypasses normal @State invalidation
    // so live drag updates render every frame.
    @State private var zoomScale: CGFloat = 1
    @State private var baseZoom: CGFloat = 1
    @State private var basePan: CGSize = .zero
    @GestureState private var panDelta: CGSize = .zero
    @State private var isPinching: Bool = false

    private let mapAspect: CGFloat = 1.5
    private let minZoom: CGFloat = 1, maxZoom: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let canvasW = geo.size.width
            let canvasH = canvasW / mapAspect
            let cw = canvasW * zoomScale
            let ch = canvasH * zoomScale

            MapContentView(
                editMode: editMode,
                selectedCat: $selectedCat,
                pendingCats: pendingCats,
                doneCats: doneCats,
                canvasSize: CGSize(width: cw, height: ch),
                suppressTaps: isPinching
            )
            .frame(width: cw, height: ch)
            .offset(clampPan(
                CGSize(width: basePan.width + panDelta.width,
                       height: basePan.height + panDelta.height),
                scale: zoomScale, viewW: canvasW, viewH: canvasH
            ))
            .frame(width: canvasW, height: canvasH)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(editMode ? Color.appDark : (vm.route != nil ? Color.appRed : Color(hex: "#E0E0E0")), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
            .contentShape(Rectangle())
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        if !isPinching { isPinching = true }
                        zoomScale = min(max(baseZoom * value, minZoom), maxZoom)
                        basePan = clampPan(basePan, scale: zoomScale, viewW: canvasW, viewH: canvasH)
                    }
                    .onEnded { _ in
                        baseZoom = zoomScale
                        // Keep suppression on briefly so the final finger-lift
                        // doesn't get interpreted as a tap on a zone.
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            isPinching = false
                        }
                    }
            )
            .gesture(
                DragGesture()
                    .updating($panDelta) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        basePan = clampPan(
                            CGSize(width: basePan.width + value.translation.width,
                                   height: basePan.height + value.translation.height),
                            scale: zoomScale, viewW: canvasW, viewH: canvasH
                        )
                    },
                including: zoomScale > 1 ? .gesture : .subviews
            )
            .overlay(alignment: .topTrailing) {
                if zoomScale > 1 {
                    Button { resetZoom() } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appDark)
                            .frame(width: 32, height: 32)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    }
                    .accessibilityLabel("Reset map zoom")
                    .padding(10)
                }
            }
            .onChange(of: zoomScale) { _, newValue in
                let zoomed = newValue > 1
                if isZoomed != zoomed { isZoomed = zoomed }
            }
        }
    }

    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.25)) {
            zoomScale = 1; baseZoom = 1
            basePan = .zero
        }
    }

    private func clampPan(_ offset: CGSize, scale: CGFloat, viewW: CGFloat, viewH: CGFloat) -> CGSize {
        let maxX = viewW * (scale - 1) / 2
        let maxY = viewH * (scale - 1) / 2
        return CGSize(width: min(max(offset.width, -maxX), maxX),
                      height: min(max(offset.height, -maxY), maxY))
    }
}

// Holds the zone ForEach, route overlay, and entrance markers. Owns its own
// drag/resize override state so an active edit-mode drag doesn't touch vm.mapLayout
// every frame. Its inputs are independent of pan/zoom delta, so SwiftUI can skip
// re-evaluating its body while the user is panning.
private struct MapContentView: View {
    @EnvironmentObject var vm: AppViewModel
    let editMode: Bool
    @Binding var selectedCat: String?
    let pendingCats: Set<String>
    let doneCats: Set<String>
    let canvasSize: CGSize
    let suppressTaps: Bool

    @State private var dragging: String? = nil
    @State private var resizing: String? = nil
    @State private var origLayout: ZoneLayout = ZoneLayout(x:0,y:0,w:0,h:0)
    @State private var dragOverrideId: String? = nil
    @State private var dragOverrideLayout: ZoneLayout = ZoneLayout(x:0,y:0,w:0,h:0)

    private let minW = 0.06, minH = 0.12

    var body: some View {
        let cw = canvasSize.width
        let ch = canvasSize.height
        ZStack {
            ForEach(vm.categories) { cat in
                let baseLayout = vm.mapLayout[cat.id] ?? defaultZoneLayouts[cat.id] ?? ZoneLayout(x:0.3,y:0.3,w:0.2,h:0.15)
                let layout = (dragOverrideId == cat.id) ? dragOverrideLayout : baseLayout
                ZoneView(
                    category: cat,
                    layout: layout,
                    canvasSize: canvasSize,
                    editMode: editMode,
                    isSelected: selectedCat == cat.id,
                    hasPending: pendingCats.contains(cat.id),
                    allDone: !pendingCats.contains(cat.id) && doneCats.contains(cat.id),
                    inRoute: vm.route?.stops.contains(cat.id) == true,
                    notInRoute: vm.route != nil && vm.route?.stops.contains(cat.id) != true,
                    stopIndex: vm.route.flatMap { r in r.stops.firstIndex(of: cat.id).map { $0 + 1 } },
                    onTap: {
                        if suppressTaps { return }
                        selectedCat = (selectedCat == cat.id ? nil : cat.id)
                    },
                    onDelete: {
                        if selectedCat == cat.id { selectedCat = nil }
                        vm.deleteCategory(cat.id)
                    },
                    onDragChanged: { val in
                        if dragging == nil {
                            dragging = cat.id
                            origLayout = layout
                            dragOverrideId = cat.id
                        }
                        if dragging == cat.id {
                            let dx = val.translation.width / cw
                            let dy = val.translation.height / ch
                            let newX = min(max(origLayout.x + dx, 0), 1 - origLayout.w)
                            let newY = min(max(origLayout.y + dy, 0), 1 - origLayout.h)
                            dragOverrideLayout = ZoneLayout(x: newX, y: newY, w: origLayout.w, h: origLayout.h)
                        }
                    },
                    onDragEnded: { _ in
                        if let id = dragOverrideId {
                            vm.mapLayout[id] = dragOverrideLayout
                        }
                        dragging = nil
                        dragOverrideId = nil
                    },
                    onResizeChanged: { val in
                        if resizing == nil {
                            resizing = cat.id
                            origLayout = layout
                            dragOverrideId = cat.id
                        }
                        if resizing == cat.id {
                            let dw = val.translation.width / cw
                            let dh = val.translation.height / ch
                            let newW = min(max(origLayout.w + dw, minW), 1 - origLayout.x)
                            let newH = min(max(origLayout.h + dh, minH), 1 - origLayout.y)
                            dragOverrideLayout = ZoneLayout(x: origLayout.x, y: origLayout.y, w: newW, h: newH)
                        }
                    },
                    onResizeEnded: { _ in
                        if let id = dragOverrideId {
                            vm.mapLayout[id] = dragOverrideLayout
                        }
                        resizing = nil
                        dragOverrideId = nil
                    }
                )
            }

            if let r = vm.route {
                RouteOverlayView(route: r, layouts: vm.mapLayout, categories: vm.categories)
                    .frame(width: cw, height: ch)
            }
        }
    }
}
