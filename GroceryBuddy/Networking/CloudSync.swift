import Foundation

@MainActor
class CloudSync: ObservableObject {
    private var debounceTask: Task<Void, Never>?
    private var loaded = false

    func onLogin(vm: AppViewModel) async {
        loaded = false
        if let data = await AuthClient.shared.loadUserData() {
            let refreshedCategories = LocalStore.refreshBuiltinDescriptions(data.categories)
            vm.items = data.items
            vm.categories = refreshedCategories
            vm.mapLayout = data.mapLayout
            vm.savedLayouts = data.savedLayouts
            vm.itemHistory = data.itemHistory ?? []
            vm.savedItemLists = data.savedItemLists ?? []
            LocalStore.saveItems(data.items)
            LocalStore.saveCategories(refreshedCategories)
            LocalStore.saveMapLayout(data.mapLayout)
            LocalStore.saveSavedLayouts(data.savedLayouts)
            LocalStore.saveItemHistory(vm.itemHistory)
            LocalStore.saveSavedItemLists(vm.savedItemLists)
        }
        loaded = true
    }

    func onLogout() {
        loaded = false
        debounceTask?.cancel()
    }

    func scheduleSync(vm: AppViewModel) {
        guard loaded else { return }
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            let payload = CloudData(
                items: vm.items,
                categories: vm.categories,
                mapLayout: vm.mapLayout,
                savedLayouts: vm.savedLayouts,
                itemHistory: vm.itemHistory,
                savedItemLists: vm.savedItemLists
            )
            await AuthClient.shared.saveUserData(payload)
        }
    }
}
