import SwiftUI

struct ReorderItemsTarget: Identifiable, Equatable {
    let id: String
}

struct ReorderItemsSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    let categoryId: String

    private var category: CustomCategory? {
        vm.categories.first(where: { $0.id == categoryId })
    }

    private var categoryItems: [GroceryItem] {
        vm.items.filter { $0.categoryId == categoryId }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categoryItems) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.checked ? .appGreen : .appGray)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appDark)
                                    .strikethrough(item.checked)
                                if item.quantity > 1 {
                                    Text("Qty \(item.quantity)").font(.system(size: 11)).foregroundColor(.appGray)
                                }
                            }
                            Spacer()
                        }
                        .deleteDisabled(true)
                    }
                    .onMove { vm.moveItems(in: categoryId, from: $0, to: $1) }
                } footer: {
                    Text("Drag the handles to change the order of items in this department.")
                        .font(.system(size: 12))
                        .foregroundColor(.appGray)
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(category.map { "Reorder \($0.name)" } ?? "Reorder Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
