import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var tab: Tab = .list
    @State private var authOpen = false

    enum Tab { case list, map }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if tab == .list {
                    GroceryListView(authOpen: $authOpen)
                } else {
                    StoreMapView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom tab bar
            HStack(spacing: 0) {
                tabButton(.list, icon: "list.bullet", label: "Shopping List")
                tabButton(.map,  icon: "map",         label: "Store Map")
            }
            .background(Color.white)
            .overlay(Divider(), alignment: .top)
        }
        .background(Color.appBg)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $authOpen) {
            if vm.isLoggedIn {
                AccountSheet()
            } else {
                AuthSheet()
            }
        }
    }

    @ViewBuilder
    private func tabButton(_ t: Tab, icon: String, label: String) -> some View {
        let active = tab == t
        Button { tab = t } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(active ? .appRed : Color(hex: "#B0B0B0"))
                Text(label)
                    .font(.system(size: 11, weight: active ? .semibold : .regular))
                    .foregroundColor(active ? .appRed : Color(hex: "#B0B0B0"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
        }
    }
}
