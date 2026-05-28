import SwiftUI

@main
struct GroceryBuddyApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(.light)
        }
    }
}
