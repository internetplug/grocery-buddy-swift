import Foundation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var items: [GroceryItem] = LocalStore.loadItems()
    @Published var categories: [CustomCategory] = LocalStore.loadCategories()
    @Published var mapLayout: [String: ZoneLayout] = LocalStore.loadMapLayout()
    @Published var savedLayouts: [SavedLayoutSlot] = LocalStore.loadSavedLayouts()
    @Published var route: RouteState? = nil
    @Published var currentUser: AuthUser? = nil
    @Published var isCheckingSession = true

    let sync = CloudSync()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Persist locally on every change
        $items.dropFirst().sink { LocalStore.saveItems($0) }.store(in: &cancellables)
        $categories.dropFirst().sink { LocalStore.saveCategories($0) }.store(in: &cancellables)
        $mapLayout.dropFirst()
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { LocalStore.saveMapLayout($0) }.store(in: &cancellables)
        $savedLayouts.dropFirst().sink { LocalStore.saveSavedLayouts($0) }.store(in: &cancellables)

        // Cloud sync on data change when logged in
        Publishers.CombineLatest4($items, $categories, $mapLayout, $savedLayouts)
            .dropFirst()
            .sink { [weak self] _, _, _, _ in
                guard let self, self.currentUser != nil else { return }
                self.sync.scheduleSync(vm: self)
            }
            .store(in: &cancellables)

        Task { await checkSession() }
    }

    var isLoggedIn: Bool { currentUser != nil }

    func checkSession() async {
        isCheckingSession = true
        currentUser = await AuthClient.shared.getSession()
        if currentUser != nil { await sync.onLogin(vm: self) }
        isCheckingSession = false
    }

    // MARK: - Item actions
    func addItem(name: String, quantity: String, categoryId: String) {
        items.insert(GroceryItem.new(name: name, quantity: quantity, categoryId: categoryId), at: 0)
    }

    func toggleItem(_ id: String) {
        if let i = items.firstIndex(where: { $0.id == id }) {
            items[i].checked.toggle()
        }
    }

    func deleteItem(_ id: String) {
        items.removeAll { $0.id == id }
    }

    func clearChecked() {
        items.removeAll { $0.checked }
    }

    // MARK: - Category actions
    func updateCategories(_ cats: [CustomCategory]) {
        categories = cats
    }

    func addCategory(_ cat: CustomCategory) {
        categories.append(cat)
    }

    func deleteCategory(_ id: String) {
        categories.removeAll { $0.id == id }
        items.removeAll { $0.categoryId == id }
        mapLayout.removeValue(forKey: id)
        if route?.stops.contains(id) == true { route = nil }
    }

    // MARK: - Auth
    func signIn(email: String, password: String) async throws {
        let user = try await AuthClient.shared.signIn(email: email, password: password)
        currentUser = user
        await sync.onLogin(vm: self)
    }

    func signUp(email: String, password: String, name: String) async throws {
        let user = try await AuthClient.shared.signUp(email: email, password: password, name: name)
        currentUser = user
        await sync.onLogin(vm: self)
    }

    func signOut() async {
        try? await AuthClient.shared.signOut()
        sync.onLogout()
        currentUser = nil
    }

    // MARK: - Route
    func planRoute(entrance: RouteState.Entrance) {
        let pending = Set(items.filter { !$0.checked }.map { $0.categoryId })
        let stops = RouteComputer.compute(entrance: entrance, categories: categories, layouts: mapLayout, pendingCategoryIds: pending)
        route = RouteState(entrance: entrance, stops: stops)
    }

    func clearRoute() { route = nil }

    // MARK: - Map layout
    func updateZone(_ id: String, layout: ZoneLayout) {
        mapLayout[id] = layout
    }

    // MARK: - Saved layouts
    func saveLayout(name: String) {
        let deletedIds = defaultCategories.compactMap { defaultCat in
            categories.contains(where: { $0.id == defaultCat.id }) ? nil : defaultCat.id
        }
        let customCats = categories.filter { !$0.builtin }
        let slot = SavedLayoutSlot(
            id: UUID().uuidString,
            name: name,
            layouts: mapLayout,
            deletedCategoryIds: deletedIds,
            customCategories: customCats,
            savedAt: Date().timeIntervalSince1970 * 1000
        )
        savedLayouts.insert(slot, at: 0)
    }

    func loadLayout(_ slot: SavedLayoutSlot) {
        var merged = defaultZoneLayouts
        for (k, v) in slot.layouts { merged[k] = v }
        mapLayout = merged

        var newCategories = defaultCategories.filter { !slot.deletedCategoryIds.contains($0.id) }
        newCategories.append(contentsOf: slot.customCategories)
        categories = newCategories
    }

    func deleteLayout(_ id: String) {
        savedLayouts.removeAll { $0.id == id }
    }

    func resetMapLayout() {
        mapLayout = defaultZoneLayouts
        // Restore any deleted default categories
        for defaultCat in defaultCategories {
            if !categories.contains(where: { $0.id == defaultCat.id }) {
                categories.append(defaultCat)
            }
        }
    }
}
