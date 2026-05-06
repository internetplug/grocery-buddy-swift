import SwiftUI

struct AddItemSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var quantity = ""
    @State private var selectedCategoryId: String = ""

    private var categories: [CustomCategory] { vm.categories }
    private var activeCategory: CustomCategory? { categories.first { $0.id == selectedCategoryId } ?? categories.first }

    private var suggestions: [String] {
        let all = categoryItems[selectedCategoryId] ?? []
        if name.count > 1 {
            return Array(all.filter { $0.lowercased().contains(name.lowercased()) }.prefix(8))
        }
        return Array(all.prefix(8))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Category picker
                    label("H-E-B Department")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories) { cat in
                                let active = cat.id == selectedCategoryId
                                Button { selectedCategoryId = cat.id } label: {
                                    HStack(spacing: 4) {
                                        Text(cat.emoji).font(.system(size: 13))
                                        Text(cat.name).font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(active ? .white : Color(hex: cat.textColor))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(active ? Color(hex: cat.accentColor) : Color(hex: cat.color))
                                    .clipShape(Capsule())
                                    .overlay(active ? nil : Capsule().stroke(Color(hex: "#ECECEC"), lineWidth: 1.5))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)

                    if let cat = activeCategory {
                        Text("📍 \(cat.aisle)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: cat.textColor))
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Color(hex: cat.color))
                            .clipShape(Capsule())
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    // Item name
                    label("Item Name")
                    TextField("e.g. \(categoryItems[selectedCategoryId]?.first ?? "Item")", text: $name)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(hex: "#F7F5F2"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ECECEC"), lineWidth: 1.5))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        .submitLabel(.done)

                    // Suggestions
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { s in
                                    Button { name = s } label: {
                                        Text(s)
                                            .font(.system(size: 13))
                                            .foregroundColor(activeCategory.map { Color(hex: $0.textColor) } ?? .appGray)
                                            .padding(.horizontal, 12).padding(.vertical, 5)
                                            .background(activeCategory.map { Color(hex: $0.color) } ?? Color(hex: "#F0F0F0"))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke((activeCategory.map { Color(hex: $0.accentColor) } ?? .appGray).opacity(0.3), lineWidth: 1.5))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 14)
                    }

                    // Quantity
                    label("Quantity (optional)")
                    TextField("e.g. 2 lbs, 1 bag, 3 cans", text: $quantity)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(hex: "#F7F5F2"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ECECEC"), lineWidth: 1.5))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .submitLabel(.done)

                    // Add button
                    Button {
                        let t = name.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty, let cat = activeCategory else { return }
                        vm.addItem(name: t, quantity: quantity.trimmingCharacters(in: .whitespaces), categoryId: cat.id)
                        name = ""; quantity = ""
                        dismiss()
                    } label: {
                        Text("Add to List")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(hex: "#E0E0E0")
                                : (activeCategory.map { Color(hex: $0.accentColor) } ?? .appRed))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            selectedCategoryId = vm.categories.first?.id ?? ""
        }
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appGray)
            .tracking(0.8)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }
}
