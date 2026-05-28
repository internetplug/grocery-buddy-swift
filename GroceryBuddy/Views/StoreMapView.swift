import SwiftUI

struct StoreMapView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var editMode = false
    @State private var selectedCat: String? = nil
    @State private var addDeptOpen = false
    @State private var entrancePickerOpen = false
    @State private var layoutManagerOpen = false
    @State private var showResetConfirmation = false

    // Drag/resize state
    @State private var dragging: String? = nil
    @State private var resizing: String? = nil
    @State private var dragStart: CGPoint = .zero
    @State private var origLayout: ZoneLayout = ZoneLayout(x:0,y:0,w:0,h:0)

    private let minW = 0.10, minH = 0.08

    var pendingCats: Set<String> { Set(vm.items.filter { !$0.checked }.map { $0.categoryId }) }
    var doneCats: Set<String>    { Set(vm.items.filter {  $0.checked }.map { $0.categoryId }) }
    var hasPendingItems: Bool    { !pendingCats.isEmpty }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                mapCard
                // Add department button (edit mode)
                if editMode {
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
                    .padding(.horizontal, 14).padding(.top, 12)
                }
                if let r = vm.route, !r.stops.isEmpty {
                    routePanel(r)
                }
                selectedPanel
            }
            .padding(.bottom, 24)
        }
        .background(Color.appBg)
        .sheet(isPresented: $addDeptOpen) { AddDepartmentSheet() }
        .sheet(isPresented: $entrancePickerOpen) { EntrancePickerSheet() }
        .sheet(isPresented: $layoutManagerOpen) { LayoutManagerSheet() }
        .alert("Reset Layout?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset to Default", role: .destructive) {
                vm.resetMapLayout()
            }
        } message: {
            Text("This will restore the default layout and bring back any deleted departments.")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("StoreMap").font(.system(size: 27, weight: .black)).foregroundColor(.appDark)
                    .overlay(Text("Store").font(.system(size: 27, weight: .black)).foregroundColor(.appDark) +
                             Text("Map").font(.system(size: 27, weight: .black)).foregroundColor(.appRed), alignment: .leading)
                Spacer()
                HStack(spacing: 8) {
                    // Layouts button
                    Button { layoutManagerOpen = true } label: {
                        Image(systemName: "tray")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#5C6BC0"))
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E0E0E0"), lineWidth: 1.5))
                    }
                    // Route button
                    Button {
                        if vm.route != nil { vm.clearRoute() }
                        else { entrancePickerOpen = true }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: vm.route != nil ? "xmark" : "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                            Text(vm.route != nil ? "Clear Route" : "Route")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(vm.route != nil ? .white : (hasPendingItems ? .appRed : Color(hex: "#B0B0B0")))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .frame(minWidth: 100)
                        .background(vm.route != nil ? Color.appRed : (hasPendingItems ? Color(hex: "#FFF0F1") : Color(hex: "#F0F0F0")))
                        .clipShape(Capsule())
                    }
                    .disabled(!hasPendingItems && vm.route == nil)
                    .opacity(editMode ? 0 : 1)
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

            Text(editMode ? "Drag to move · corner to resize · + to add"
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

    // MARK: - Map Canvas
    private var mapCard: some View {
        GeometryReader { geo in
            let canvasW = geo.size.width
            let canvasH = canvasW * 1.1

            ZStack {
                // Zones
                ForEach(vm.categories) { cat in
                    let layout = vm.mapLayout[cat.id] ?? defaultZoneLayouts[cat.id] ?? ZoneLayout(x:0.3,y:0.3,w:0.2,h:0.15)
                    ZoneView(
                        category: cat,
                        layout: layout,
                        canvasSize: CGSize(width: canvasW, height: canvasH),
                        editMode: editMode,
                        isSelected: selectedCat == cat.id,
                        hasPending: pendingCats.contains(cat.id),
                        allDone: !pendingCats.contains(cat.id) && doneCats.contains(cat.id),
                        inRoute: vm.route?.stops.contains(cat.id) == true,
                        notInRoute: vm.route != nil && vm.route?.stops.contains(cat.id) != true,
                        stopIndex: vm.route.flatMap { r in r.stops.firstIndex(of: cat.id).map { $0 + 1 } },
                        onTap: { selectedCat = (selectedCat == cat.id ? nil : cat.id) },
                        onDelete: { vm.deleteCategory(cat.id) },
                        onDragChanged: { val in
                            if dragging == nil { dragging = cat.id; dragStart = val.startLocation; origLayout = layout }
                            if dragging == cat.id {
                                let dx = val.translation.width / canvasW
                                let dy = val.translation.height / canvasH
                                let newX = min(max(origLayout.x + dx, 0), 1 - origLayout.w)
                                let newY = min(max(origLayout.y + dy, 0), 1 - origLayout.h)
                                vm.mapLayout[cat.id] = ZoneLayout(x: newX, y: newY, w: origLayout.w, h: origLayout.h)
                            }
                        },
                        onDragEnded: { _ in dragging = nil; LocalStore.saveMapLayout(vm.mapLayout) },
                        onResizeChanged: { val in
                            if resizing == nil { resizing = cat.id; origLayout = layout }
                            if resizing == cat.id {
                                let dw = val.translation.width / canvasW
                                let dh = val.translation.height / canvasH
                                let newW = min(max(origLayout.w + dw, minW), 1 - origLayout.x)
                                let newH = min(max(origLayout.h + dh, minH), 1 - origLayout.y)
                                vm.mapLayout[cat.id] = ZoneLayout(x: origLayout.x, y: origLayout.y, w: newW, h: newH)
                            }
                        },
                        onResizeEnded: { _ in resizing = nil; LocalStore.saveMapLayout(vm.mapLayout) }
                    )
                }

                // Route overlay
                if let r = vm.route {
                    RouteOverlayView(route: r, layouts: vm.mapLayout, categories: vm.categories)
                        .frame(width: canvasW, height: canvasH)
                }

                // Store entrance and checkout dots
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(vm.route?.entrance == .left ? Color.appRed : Color(hex: "#E0E0E0"))
                                .frame(width: 12, height: 12)
                            Text("Entrance")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.appGray)
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.appRed)
                                .frame(width: 12, height: 12)
                            Text("Checkout")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.appGray)
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            Circle()
                                .fill(vm.route?.entrance == .right ? Color.appRed : Color(hex: "#E0E0E0"))
                                .frame(width: 12, height: 12)
                            Text("Entrance")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.appGray)
                        }
                    }
                    .frame(height: 40)
                    .padding(.horizontal, 12)
                }
                .frame(width: canvasW, height: canvasH)

            }
            .frame(width: canvasW, height: canvasH)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(editMode ? Color.appDark : (vm.route != nil ? Color.appRed : Color(hex: "#E0E0E0")), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
        }
        .aspectRatio(1/1.1, contentMode: .fit)
        .padding(.horizontal, 14)
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
            }

            ForEach(Array(r.stops.enumerated()), id: \.element) { idx, catId in
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
                    Button { selectedCat = (selectedCat == catId ? nil : catId) } label: {
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
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.appGray)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 10)
                        .background(Color(hex: isDone ? "#F0FFF4" : cat.color))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
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

    // MARK: - Selected category detail panel
    @ViewBuilder
    private var selectedPanel: some View {
        if let id = selectedCat, let cat = vm.categories.first(where: { $0.id == id }) {
            let catItems = vm.items.filter { $0.categoryId == id }
            if !catItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(cat.emoji).font(.system(size: 20))
                        Text(cat.name).font(.system(size: 15, weight: .bold)).foregroundColor(.appDark)
                        Spacer()
                        Text("\(catItems.filter { !$0.checked }.count) left")
                            .font(.system(size: 12)).foregroundColor(.appGray)
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
