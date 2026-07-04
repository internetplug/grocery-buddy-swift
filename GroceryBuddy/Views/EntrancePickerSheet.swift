import SwiftUI

struct EntrancePickerSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Which entrance are you using?")
                    .font(.system(size: 15))
                    .foregroundColor(.appGray)

                HStack(spacing: 16) {
                    entranceButton(.left,  label: "Left Entrance",  sub: "Bottom-left of your map")
                    entranceButton(.right, label: "Right Entrance", sub: "Bottom-right of your map")
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Plan My Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }

    private func entranceButton(_ entrance: RouteState.Entrance, label: String, sub: String) -> some View {
        Button {
            vm.planRoute(entrance: entrance)
            dismiss()
        } label: {
            VStack(spacing: 10) {
                Text("🚪").font(.system(size: 36))
                Text(label).font(.system(size: 17, weight: .black)).foregroundColor(.appRed)
                Text(sub).font(.system(size: 11)).foregroundColor(.appGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(hex: "#FFF5F5"))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appRed, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
