import Foundation

@MainActor
class CloudSync: ObservableObject {
    enum Status: Equatable {
        case idle      // signed out / nothing to do
        case syncing
        case synced
        case failed
    }

    @Published private(set) var status: Status = .idle
    private(set) var hasLoaded = false

    private var debounceTask: Task<Void, Never>?

    /// Fetches cloud data and reconciles it with local state. When merging is
    /// allowed (same account as last time, or no account was ever used on this
    /// device), local-only records survive instead of being overwritten; the
    /// merged result is pushed back to the cloud. If the fetch fails, syncing
    /// stays disabled (hasLoaded == false) so a stale local copy can never
    /// clobber the cloud — the app retries when it returns to the foreground.
    func onLogin(vm: AppViewModel, allowLocalMerge: Bool) async {
        hasLoaded = false
        status = .syncing

        let cloud: CloudData?
        do {
            cloud = try await AuthClient.shared.loadUserData()
        } catch {
            status = .failed
            return
        }

        let local = Self.snapshot(of: vm)
        let resolved: CloudData
        if let cloud {
            resolved = allowLocalMerge ? Self.merge(local: local, cloud: cloud) : cloud
        } else {
            // Empty account: whatever is on the device becomes the first upload.
            resolved = local
        }

        let refreshedCategories = LocalStore.refreshBuiltinDescriptions(resolved.categories)
        vm.items = resolved.items
        vm.categories = refreshedCategories
        vm.mapLayout = resolved.mapLayout
        vm.savedLayouts = resolved.savedLayouts
        vm.itemHistory = resolved.itemHistory ?? []
        vm.savedItemLists = resolved.savedItemLists ?? []
        LocalStore.saveItems(resolved.items)
        LocalStore.saveCategories(refreshedCategories)
        LocalStore.saveMapLayout(resolved.mapLayout)
        LocalStore.saveSavedLayouts(resolved.savedLayouts)
        LocalStore.saveItemHistory(vm.itemHistory)
        LocalStore.saveSavedItemLists(vm.savedItemLists)

        hasLoaded = true
        if resolved != cloud {
            scheduleSync(vm: vm)
        } else {
            status = .synced
        }
    }

    func onLogout() {
        hasLoaded = false
        debounceTask?.cancel()
        status = .idle
    }

    func scheduleSync(vm: AppViewModel) {
        guard hasLoaded else { return }
        debounceTask?.cancel()
        status = .syncing
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            let payload = Self.snapshot(of: vm)
            let ok = await AuthClient.shared.saveUserData(payload)
            guard !Task.isCancelled else { return }
            status = ok ? .synced : .failed
        }
    }

    /// Called when the app returns to the foreground.
    func retryIfFailed(vm: AppViewModel) {
        guard hasLoaded, status == .failed else { return }
        scheduleSync(vm: vm)
    }

    private static func snapshot(of vm: AppViewModel) -> CloudData {
        CloudData(
            items: vm.items,
            categories: vm.categories,
            mapLayout: vm.mapLayout,
            savedLayouts: vm.savedLayouts,
            itemHistory: vm.itemHistory,
            savedItemLists: vm.savedItemLists
        )
    }

    /// Union-based merge that never discards data. Cloud is the base; records
    /// that exist on both sides take the local version (the state the user is
    /// looking at), and local-only records are kept. Items deleted on another
    /// device may reappear — the deliberate trade-off is losing deletions over
    /// losing additions.
    static func merge(local: CloudData, cloud: CloudData) -> CloudData {
        var items = cloud.items
        for (i, item) in items.enumerated() {
            if let l = local.items.first(where: { $0.id == item.id }) { items[i] = l }
        }
        let cloudItemIds = Set(cloud.items.map { $0.id })
        items = local.items.filter { !cloudItemIds.contains($0.id) } + items

        var categories = cloud.categories
        for (i, cat) in categories.enumerated() {
            if let l = local.categories.first(where: { $0.id == cat.id }) { categories[i] = l }
        }
        let cloudCatIds = Set(cloud.categories.map { $0.id })
        categories += local.categories.filter { !cloudCatIds.contains($0.id) }

        var mapLayout = cloud.mapLayout
        for (id, zone) in local.mapLayout { mapLayout[id] = zone }

        let cloudLayoutIds = Set(cloud.savedLayouts.map { $0.id })
        let savedLayouts = local.savedLayouts.filter { !cloudLayoutIds.contains($0.id) } + cloud.savedLayouts

        let cloudListIds = Set((cloud.savedItemLists ?? []).map { $0.id })
        let savedItemLists = (local.savedItemLists ?? []).filter { !cloudListIds.contains($0.id) } + (cloud.savedItemLists ?? [])

        var history = cloud.itemHistory ?? []
        var historyIndex = [String: Int]()
        for (i, entry) in history.enumerated() {
            historyIndex["\(entry.categoryId)|\(entry.name.lowercased())"] = i
        }
        for entry in local.itemHistory ?? [] {
            let key = "\(entry.categoryId)|\(entry.name.lowercased())"
            if let i = historyIndex[key] {
                history[i].count = max(history[i].count, entry.count)
                history[i].lastAddedAt = max(history[i].lastAddedAt, entry.lastAddedAt)
            } else {
                historyIndex[key] = history.count
                history.append(entry)
            }
        }

        return CloudData(
            items: items,
            categories: categories,
            mapLayout: mapLayout,
            savedLayouts: savedLayouts,
            itemHistory: history,
            savedItemLists: savedItemLists
        )
    }
}
