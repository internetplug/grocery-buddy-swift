import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject var vm: AppViewModel
    @Binding var authOpen: Bool
    @State private var addOpen = false
    @State private var listManagerOpen = false
    @State private var clearAllConfirm = false
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable { case all, pending, done }

    var filteredItems: [GroceryItem] {
        switch filter {
        case .all:     return vm.items
        case .pending: return vm.items.filter { !$0.checked }
        case .done:    return vm.items.filter {  $0.checked }
        }
    }

    var grouped: [(category: CustomCategory, items: [GroceryItem])] {
        let orderedCats: [CustomCategory] = {
            guard let r = vm.route, !r.stops.isEmpty else { return vm.categories }
            let stopSet = Set(r.stops)
            let inRoute = r.stops.compactMap { id in vm.categories.first { $0.id == id } }
            let notInRoute = vm.categories.filter { !stopSet.contains($0.id) }
            return inRoute + notInRoute
        }()
        return orderedCats.compactMap { cat in
            let its = filteredItems.filter { $0.categoryId == cat.id }
            return its.isEmpty ? nil : (cat, its)
        }
    }

    var totalItems: Int  { vm.items.count }
    var checkedItems: Int { vm.items.filter { $0.checked }.count }
    var progress: Double { totalItems > 0 ? Double(checkedItems) / Double(totalItems) : 0 }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // Header
                    headerSection

                    if grouped.isEmpty {
                        emptyState
                    } else {
                        ForEach(grouped, id: \.category.id) { group in
                            let stopIdx = vm.route?.stops.firstIndex(of: group.category.id)
                            CategorySectionView(
                                category: group.category,
                                items: group.items,
                                stopNumber: stopIdx.map { $0 + 1 }
                            )
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 20)
                    }
                }
                .padding(.bottom, 140)
            }

            // FAB
            Button { addOpen = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(colors: [Color(hex: "#E91E2C"), Color(hex: "#C62828")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.appRed.opacity(0.4), radius: 12, y: 4)
            }
            .padding(.bottom, 80)
            .padding(.trailing, 24)
        }
        .sheet(isPresented: $addOpen) {
            AddItemSheet()
        }
        .sheet(isPresented: $listManagerOpen) {
            ItemListManagerSheet()
        }
        .alert("Clear entire list?", isPresented: $clearAllConfirm) {
            Button("Clear \(totalItems) item\(totalItems == 1 ? "" : "s")", role: .destructive) {
                vm.clearAll()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes every item from your list. This can't be undone.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    (Text("Grocery").foregroundColor(.appDark) + Text("Buddy").foregroundColor(.appRed))
                        .font(.system(size: 27, weight: .black))
                    Text("\(checkedItems)/\(totalItems) items checked off")
                        .font(.system(size: 12))
                        .foregroundColor(.appGray)
                    if let r = vm.route, !r.stops.isEmpty {
                        Label("Route active · \(r.entrance == .left ? "Left" : "Right") entrance",
                              systemImage: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.appRed)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: "#FFF0F1"))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // Account pill
                    Button { authOpen = true } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(vm.isLoggedIn ? Color.appRed : Color(hex: "#E0E0E0"))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Group {
                                        if vm.isLoggedIn, let name = vm.currentUser?.name ?? vm.currentUser?.email {
                                            Text(String(name.prefix(1)).uppercased())
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                            Text(vm.isLoggedIn ? (vm.currentUser?.name ?? "Account") : "Sign in")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(vm.isLoggedIn ? .appRed : .appGray)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.white)
                        .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1.5))
                        .clipShape(Capsule())
                    }

                    HStack(spacing: 8) {
                        // Saved lists button
                        Button { listManagerOpen = true } label: {
                            Image(systemName: "externaldrive.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#5C6BC0"))
                                .frame(width: 46, height: 46)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.08), radius: 5)
                        }

                        // Cart icon
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .frame(width: 46, height: 46)
                                .shadow(color: .black.opacity(0.08), radius: 5)
                                .overlay(Image(systemName: "cart").foregroundColor(.appRed).font(.system(size: 20)))
                            if totalItems > 0 {
                                Text(totalItems > 99 ? "99+" : "\(totalItems)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color.appRed)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }

            if totalItems > 0 {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "#E8E8E8")).frame(height: 6)
                            Capsule()
                                .fill(LinearGradient(colors: [Color.appRed, Color(hex: "#FF6B6B")],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * CGFloat(progress), height: 6)
                                .animation(.easeInOut(duration: 0.4), value: progress)
                        }
                    }
                    .frame(height: 6)
                    if progress == 1 {
                        Text("✓ All done! Happy shopping!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appGreen)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }

            // Filter + clear
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { f in
                    Button { filter = f } label: {
                        Text(f.rawValue.capitalized)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(filter == f ? .white : .appGray)
                            .padding(.horizontal, 16).padding(.vertical, 7)
                            .background(filter == f ? Color.appDark : Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(filter == f ? 0 : 0.06), radius: 2)
                    }
                }
                Spacer()
                if checkedItems > 0 {
                    Button("Clear done") { vm.clearChecked() }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appRed)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .overlay(Capsule().stroke(Color(hex: "#FFCDD2"), lineWidth: 1.5))
                }
                if totalItems > 0 {
                    Button("Clear all") { clearAllConfirm = true }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.appRed)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🛒").font(.system(size: 60))
            Text(filter == .done ? "Nothing checked off yet" : "Your list is empty")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appDark)
            Text(filter != .done ? "Tap + to add items organized by department" : "Check items off as you pick them up")
                .font(.system(size: 14))
                .foregroundColor(.appGray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 220)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
}
