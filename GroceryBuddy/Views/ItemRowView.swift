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

            Text(item.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(item.checked ? Color(hex: "#C8C8D4") : .appDark)
                .strikethrough(item.checked)
                .lineLimit(1)

            Spacer()

            // Quantity stepper
            HStack(spacing: 10) {
                Button { vm.decrementItem(item.id) } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(item.quantity > 1 ? .appDark : Color(hex: "#C8C8D4"))
                        .frame(width: 24, height: 24)
                        .background(Color(hex: "#F2F0ED"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(item.quantity <= 1)

                Text("\(item.quantity)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appDark)
                    .frame(minWidth: 16)

                Button { vm.incrementItem(item.id) } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appDark)
                        .frame(width: 24, height: 24)
                        .background(Color(hex: "#F2F0ED"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Button { vm.deleteItem(item.id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#C8C8D4"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
