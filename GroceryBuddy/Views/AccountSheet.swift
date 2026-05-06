import SwiftUI

struct AccountSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    private var initials: String {
        let src = vm.currentUser?.name ?? vm.currentUser?.email ?? "?"
        return String(src.prefix(1)).uppercased()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Avatar + info
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.appRed)
                        .frame(width: 72, height: 72)
                        .overlay(Text(initials).font(.system(size: 30, weight: .black)).foregroundColor(.white))

                    VStack(spacing: 4) {
                        Text(vm.currentUser?.name ?? "Account")
                            .font(.system(size: 22, weight: .black)).foregroundColor(.appDark)
                        Text(vm.currentUser?.email ?? "")
                            .font(.system(size: 14)).foregroundColor(.appGray)
                    }
                }
                .padding(.top, 32).padding(.bottom, 24)

                // Sync status
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.appGreen)
                    Text("Your list & map are synced to the cloud")
                        .font(.system(size: 13)).foregroundColor(Color(hex: "#2E7D32"))
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(hex: "#F0FFF4"))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appGreen.opacity(0.3), lineWidth: 1.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20).padding(.bottom, 28)

                Spacer()

                Button {
                    Task {
                        await vm.signOut()
                        dismiss()
                    }
                } label: {
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#FFF0F1"))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#FFCDD2"), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
