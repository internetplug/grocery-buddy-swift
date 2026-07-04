import Foundation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var items: [GroceryItem] = LocalStore.loadItems()
    @Published var categories: [CustomCategory] = LocalStore.loadCategories()
    @Published var mapLayout: [String: ZoneLayout] = LocalStore.loadMapLayout()
    @Published var savedLayouts: [SavedLayoutSlot] = LocalStore.loadSavedLayouts()
    @Published var savedItemLists: [SavedItemListSlot] = LocalStore.loadSavedItemLists()
    @Published var itemHistory: [ItemHistoryEntry] = LocalStore.loadItemHistory()
    @Published var route: RouteState? = LocalStore.loadRoute()
    @Published var currentUser: AuthUser? = LocalStore.loadUser()

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
        $savedItemLists.dropFirst().sink { LocalStore.saveSavedItemLists($0) }.store(in: &cancellables)
        $itemHistory.dropFirst().sink { LocalStore.saveItemHistory($0) }.store(in: &cancellables)
        $route.dropFirst().sink { LocalStore.saveRoute($0) }.store(in: &cancellables)

        // Nested ObservableObjects don't propagate automatically; forward sync
        // status changes so views observing the view model re-render.
        sync.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Cloud sync on data change when logged in
        Publishers.CombineLatest4($items, $categories, $mapLayout, $savedLayouts)
            .dropFirst()
            .sink { [weak self] _, _, _, _ in
                guard let self, self.currentUser != nil else { return }
                self.sync.scheduleSync(vm: self)
            }
            .store(in: &cancellables)
        $itemHistory.dropFirst()
            .sink { [weak self] _ in
                guard let self, self.currentUser != nil else { return }
                self.sync.scheduleSync(vm: self)
            }
            .store(in: &cancellables)
        $savedItemLists.dropFirst()
            .sink { [weak self] _ in
                guard let self, self.currentUser != nil else { return }
                self.sync.scheduleSync(vm: self)
            }
            .store(in: &cancellables)

        Task { await checkSession() }
    }

    var isLoggedIn: Bool { currentUser != nil }

    func checkSession() async {
        switch await AuthClient.shared.getSession() {
        case .signedIn(let user):
            await establishSession(user)
        case .signedOut:
            currentUser = nil
            LocalStore.saveUser(nil)
        case .unreachable:
            // Offline — keep the last-known signed-in presentation; syncing
            // stays disabled until a session check succeeds on foreground.
            break
        }
    }

    /// Call when the app returns to the foreground: re-establishes the session
    /// if the initial check failed offline, and retries a failed upload.
    func appBecameActive() {
        guard currentUser != nil else { return }
        if !sync.hasLoaded {
            Task { await checkSession() }
        } else {
            sync.retryIfFailed(vm: self)
        }
    }

    private func establishSession(_ user: AuthUser) async {
        // Local data may only merge into the same account it came from (or a
        // first sign-in on a device that never had an account).
        let lastAccount = LocalStore.lastAccountId()
        let allowMerge = lastAccount == nil || lastAccount == user.id
        currentUser = user
        LocalStore.saveUser(user)
        LocalStore.saveLastAccountId(user.id)
        await sync.onLogin(vm: self, allowLocalMerge: allowMerge)
    }

    // MARK: - Item actions
    func addItem(name: String, categoryId: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !categoryId.isEmpty else { return }
        recordHistory(name: trimmed, categoryId: categoryId)
        items.insert(GroceryItem.new(name: trimmed, categoryId: categoryId), at: 0)
    }

    func incrementItem(_ id: String) {
        if let i = items.firstIndex(where: { $0.id == id }) {
            items[i].quantity += 1
        }
    }

    func decrementItem(_ id: String) {
        if let i = items.firstIndex(where: { $0.id == id }) {
            items[i].quantity = max(1, items[i].quantity - 1)
        }
    }

    private func recordHistory(name: String, categoryId: String) {
        let key = name.lowercased()
        let now = Date().timeIntervalSince1970 * 1000
        if let i = itemHistory.firstIndex(where: { $0.categoryId == categoryId && $0.name.lowercased() == key }) {
            itemHistory[i].count += 1
            itemHistory[i].lastAddedAt = now
        } else {
            itemHistory.append(ItemHistoryEntry(name: name, categoryId: categoryId, count: 1, lastAddedAt: now))
        }
        // History is synced in full on every change, so keep it bounded.
        let maxEntries = 500
        if itemHistory.count > maxEntries {
            itemHistory.sort { $0.lastAddedAt > $1.lastAddedAt }
            itemHistory.removeLast(itemHistory.count - maxEntries)
        }
    }

    func rankedHistory(for categoryId: String) -> [String] {
        let now = Date().timeIntervalSince1970 * 1000
        let weekMs: TimeInterval = 7 * 24 * 60 * 60 * 1000
        let monthMs: TimeInterval = 30 * 24 * 60 * 60 * 1000
        return itemHistory
            .filter { $0.categoryId == categoryId }
            .map { e -> (String, Double) in
                let age = now - e.lastAddedAt
                let boost: Double = age < weekMs ? 2.0 : (age < monthMs ? 1.0 : 0.0)
                return (e.name, Double(e.count) + boost)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
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

    func clearAll() {
        items.removeAll()
    }

    // MARK: - Category actions
    func updateCategories(_ cats: [CustomCategory]) {
        categories = cats
    }

    func addCategory(_ cat: CustomCategory) {
        categories.append(cat)
    }

    func updateCategory(_ cat: CustomCategory) {
        if let idx = categories.firstIndex(where: { $0.id == cat.id }) {
            categories[idx] = cat
        }
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
        await establishSession(user)
    }

    func signUp(email: String, password: String, name: String) async throws {
        let user = try await AuthClient.shared.signUp(email: email, password: password, name: name)
        await establishSession(user)
    }

    func signOut() async {
        await AuthClient.shared.signOut()
        sync.onLogout()
        currentUser = nil
        LocalStore.saveUser(nil)
    }

    func updateName(_ name: String) async throws {
        try await AuthClient.shared.updateName(name)
        if var user = currentUser {
            user.name = name
            currentUser = user
            LocalStore.saveUser(user)
        }
    }

    func changePassword(current: String, new: String) async throws {
        try await AuthClient.shared.changePassword(current: current, new: new)
    }

    /// Deletes the account and its cloud data on the server, then returns this
    /// device to the signed-out state. Local list data stays on the device.
    func deleteAccount(password: String) async throws {
        try await AuthClient.shared.deleteAccount(password: password)
        sync.onLogout()
        currentUser = nil
        LocalStore.saveUser(nil)
        LocalStore.clearLastAccountId()
    }

    // MARK: - Route
    func planRoute(entrance: RouteState.Entrance) {
        let pending = Set(items.filter { !$0.checked }.map { $0.categoryId })
        let stops = RouteComputer.compute(entrance: entrance, categories: categories, layouts: mapLayout, pendingCategoryIds: pending)
        route = RouteState(entrance: entrance, stops: stops)
    }

    func clearRoute() { route = nil }

    /// Reorders the category stops in the active route. Checkout is pinned to the end and
    /// cannot be moved or have other stops moved past it.
    func moveRouteStops(from source: IndexSet, to destination: Int) {
        guard var r = route else { return }
        let lastCatIndex = r.stops.count - 1 // checkout sits here
        let filteredSources = source.filter { $0 < lastCatIndex }
        guard !filteredSources.isEmpty else { return }
        let clampedDest = min(destination, lastCatIndex)
        r.stops.move(fromOffsets: IndexSet(filteredSources), toOffset: clampedDest)
        route = r
    }

    /// Reorders items belonging to a single category. `source` and `destination` are indices
    /// within that category's filtered list; this translates them back into the global `items` array.
    func moveItems(in categoryId: String, from source: IndexSet, to destination: Int) {
        let categoryItemIndices = items.enumerated()
            .filter { $0.element.categoryId == categoryId }
            .map { $0.offset }
        guard !categoryItemIndices.isEmpty else { return }

        let movedGlobalIndices = source.compactMap { idx -> Int? in
            guard idx < categoryItemIndices.count else { return nil }
            return categoryItemIndices[idx]
        }
        guard !movedGlobalIndices.isEmpty else { return }

        let destGlobal: Int
        if destination >= categoryItemIndices.count {
            destGlobal = (categoryItemIndices.last ?? -1) + 1
        } else {
            destGlobal = categoryItemIndices[destination]
        }

        items.move(fromOffsets: IndexSet(movedGlobalIndices), toOffset: destGlobal)
    }

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
        mapLayout = slot.layouts

        var newCategories = defaultCategories.filter { !slot.deletedCategoryIds.contains($0.id) }
        newCategories.append(contentsOf: slot.customCategories)
        categories = newCategories

        let keepIds = Set(newCategories.map { $0.id })
        items.removeAll { !keepIds.contains($0.categoryId) }
        if route?.stops.contains(where: { $0 != checkoutId && !keepIds.contains($0) }) == true {
            route = nil
        }
    }

    func deleteLayout(_ id: String) {
        savedLayouts.removeAll { $0.id == id }
    }

    // MARK: - Saved item lists
    func saveItemList(name: String) {
        let slot = SavedItemListSlot(
            id: UUID().uuidString,
            name: name,
            items: items,
            savedAt: Date().timeIntervalSince1970 * 1000
        )
        savedItemLists.insert(slot, at: 0)
    }

    func loadItemList(_ slot: SavedItemListSlot) {
        let knownCategoryIds = Set(categories.map { $0.id })
        items = slot.items.filter { knownCategoryIds.contains($0.categoryId) }
        if route?.stops.isEmpty == false { route = nil }
    }

    func deleteItemList(_ id: String) {
        savedItemLists.removeAll { $0.id == id }
    }

    func resetMapLayout() {
        let customIds = Set(categories.filter { !$0.builtin }.map { $0.id })
        if !customIds.isEmpty {
            categories.removeAll { customIds.contains($0.id) }
            items.removeAll { customIds.contains($0.categoryId) }
            if route?.stops.contains(where: { customIds.contains($0) }) == true { route = nil }
        }
        mapLayout = defaultZoneLayouts
        // Restore any deleted default categories
        for defaultCat in defaultCategories {
            if !categories.contains(where: { $0.id == defaultCat.id }) {
                categories.append(defaultCat)
            }
        }
    }
}
