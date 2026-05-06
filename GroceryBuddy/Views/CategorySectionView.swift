import SwiftUI

struct CategorySectionView: View {
    @EnvironmentObject var vm: AppViewModel
    let category: CustomCategory
    let items: [GroceryItem]
    let stopNumber: Int?

    @State private var collapsed = false

    var checkedCount: Int { items.filter { $0.checked }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Button { withAnimation(.easeInOut(duration: 0.2)) { collapsed.toggle() } } label: {
                HStack(spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: category.color))
                            .frame(width: 38, height: 38)
                            .overlay(Text(category.emoji).font(.system(size: 20)))
                        if let n = stopNumber {
                            Text("\(n)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .frame(width: 17, height: 17)
                                .background(Color.appRed)
                                .clipShape(Circle())
                                .offset(x: -5, y: -5)
                        }
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(category.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.appDark)
                        Text("\(category.aisle) · \(checkedCount)/\(items.count)")
                            .font(.system(size: 11))
                            .foregroundColor(.appGray)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appGray)
                        .rotationEffect(.degrees(collapsed ? -90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: collapsed)
                }
            }
            .buttonStyle(.plain)

            if !collapsed {
                ForEach(items) { item in
                    ItemRowView(item: item)
                }
            }
        }
        .padding(.bottom, 12)
    }
}
