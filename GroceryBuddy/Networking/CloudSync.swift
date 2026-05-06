import Foundation

@MainActor
class CloudSync: ObservableObject {
    private var debounceTask: Task<Void, Never>?
    private var loaded = false

    func onLogin(vm: AppViewModel) async {
        loaded = false
        if let data = await AuthClient.shared.loadUserData() {
            vm.items = data.items
            vm.categories = data.categories
            vm.mapLayout = data.mapLayout
            vm.savedLayouts = data.savedLayouts
            LocalStore.saveItems(data.items)
            LocalStore.saveCategories(data.categories)
            LocalStore.saveMapLayout(data.mapLayout)
            LocalStore.saveSavedLayouts(data.savedLayouts)
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
                savedLayouts: vm.savedLayouts
            )
            await AuthClient.shared.saveUserData(payload)
        }
    }
}
