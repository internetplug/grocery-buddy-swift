import SwiftUI

struct ItemRowView: View {
    @EnvironmentObject var vm: AppViewModel
    let item: GroceryItem

    var body: some View {
        HStack(spacing: 12) {
            // Check circle
            Button { vm.toggleItem(item.id) } label: {
                ZStack {
                    Circle()
                        .strokeBorder(item.checked ? Color.clear : Color(hex: "#C8C8D4"), lineWidth: 2)
                        .background(Circle().fill(item.checked ? Color.appGreen : Color.clear))
                        .frame(width: 26, height: 26)
                    if item.checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: item.checked)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(item.checked ? Color(hex: "#C8C8D4") : .appDark)
                    .strikethrough(item.checked)
                    .lineLimit(1)
                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.system(size: 12))
                        .foregroundColor(.appGray)
                }
            }

            Spacer()

            Button { vm.deleteItem(item.id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#C8C8D4"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
