import SwiftUI

private let defaultDeptEmojis = defaultCategories.map { $0.emoji }
private let customEmojis = ["🛒","🏪","🧺","🫙","🥡","🫕","🥗","🧆","🍱","🥘","🧇","🥞","🍳","🧈","🫒","🌿","🌾","🫚","🍶","🧋","🥤","🍵","☕","🍺","🍻","🧴","🪥","🧼","🪒","🧽","🪣","🧹","🪴","🌸","🐠","🐕","🐈","📦","🪑","💡","🔋","🧲","🛠️"]
private let emojiOptions = defaultDeptEmojis + customEmojis

// Extract unique default colors and add 5 distinct additional colors
private let allDepartmentColors: [(color: String, textColor: String, accentColor: String)] = {
    var seen = Set<String>()
    var colors: [(color: String, textColor: String, accentColor: String)] = []

    // Add unique default category colors
    for cat in defaultCategories {
        if !seen.contains(cat.color) {
            colors.append((color: cat.color, textColor: cat.textColor, accentColor: cat.accentColor))
            seen.insert(cat.color)
        }
    }

    // Add 5 distinct additional colors that complement the defaults
    let additionalColors: [(color: String, textColor: String, accentColor: String)] = [
        ("#FFCDD2", "#C62828", "#E53935"), // Deep red/rose
        ("#C8E6C9", "#2E7D32", "#43A047"), // Medium green
        ("#FFCCBC", "#D84315", "#FF7043"), // Deep orange
        ("#D1C4E9", "#512DA8", "#7E57C2"), // Deep purple
        ("#B2DFDB", "#00695C", "#00897B")  // Teal
    ]

    for color in additionalColors {
        if !seen.contains(color.color) {
            colors.append(color)
            seen.insert(color.color)
        }
    }

    return colors
}()

struct AddDepartmentSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var aisle = ""
    @State private var selectedEmoji = "🛒"
    @State private var colorIdx = 0

    private var palette: (color: String, textColor: String, accentColor: String) { allDepartmentColors[colorIdx] }
    private var usedAccents: Set<String> { Set(vm.categories.map { $0.accentColor }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Preview chip
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: palette.color))
                            .frame(width: 44, height: 44)
                            .overlay(Text(selectedEmoji).font(.system(size: 24)))
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "New Department" : name)
                                .font(.system(size: 17, weight: .black)).foregroundColor(.appDark)
                            Text("Adds to map & shopping list")
                                .font(.system(size: 12)).foregroundColor(.appGray)
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 20)

                    label("Department Name")
                    TextField("e.g. Organic Section, Wine Cellar…", text: $name)
                        .textFieldStyle(.plain).padding(12)
                        .background(Color(hex: "#F7F5F2"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1.5))
                        .padding(.horizontal, 20).padding(.bottom, 16)

                    label("Description (optional)")
                    TextField("e.g. Frozen goods, Pantry staples", text: $aisle)
                        .textFieldStyle(.plain).padding(12)
                        .background(Color(hex: "#F7F5F2"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1.5))
                        .padding(.horizontal, 20).padding(.bottom, 18)

                    label("Icon")

                    // Default department icons
                    if !defaultDeptEmojis.isEmpty {
                        Text("Default Departments")
                            .font(.system(size: 11, weight: .semibold)).foregroundColor(.appGray)
                            .padding(.horizontal, 20).padding(.bottom, 8)
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                            ForEach(defaultDeptEmojis, id: \.self) { e in
                                Button { selectedEmoji = e } label: {
                                    Text(e).font(.system(size: 20))
                                        .frame(width: 38, height: 38)
                                        .background(selectedEmoji == e ? Color(hex: palette.color) : Color(hex: "#F7F5F2"))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(selectedEmoji == e
                                            ? RoundedRectangle(cornerRadius: 10).stroke(Color(hex: palette.accentColor), lineWidth: 2)
                                            : RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1.5))
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.bottom, 16)
                    }

                    // Custom emoji icons
                    Text("Other Icons")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(.appGray)
                        .padding(.horizontal, 20).padding(.bottom, 8)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                        ForEach(customEmojis, id: \.self) { e in
                            Button { selectedEmoji = e } label: {
                                Text(e).font(.system(size: 20))
                                    .frame(width: 38, height: 38)
                                    .background(selectedEmoji == e ? Color(hex: palette.color) : Color(hex: "#F7F5F2"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(selectedEmoji == e
                                        ? RoundedRectangle(cornerRadius: 10).stroke(Color(hex: palette.accentColor), lineWidth: 2)
                                        : RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1.5))
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 18)

                    label("Color")
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 12), count: 6), spacing: 12) {
                        ForEach(allDepartmentColors.indices, id: \.self) { i in
                            Button { colorIdx = i } label: {
                                Circle()
                                    .fill(Color(hex: allDepartmentColors[i].accentColor))
                                    .frame(width: 38, height: 38)
                                    .overlay(colorIdx == i
                                        ? Circle().stroke(Color.appDark, lineWidth: 3)
                                        : Circle().stroke(Color.clear, lineWidth: 2))
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 24)

                    Button {
                        let t = name.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty else { return }
                        let cat = CustomCategory(
                            id: "cat_\(UUID().uuidString.prefix(8).lowercased())",
                            name: t,
                            emoji: selectedEmoji,
                            aisle: aisle.trimmingCharacters(in: .whitespaces),
                            color: palette.color,
                            textColor: palette.textColor,
                            accentColor: palette.accentColor,
                            builtin: false
                        )
                        vm.addCategory(cat)
                        // Give it a default layout
                        vm.mapLayout[cat.id] = ZoneLayout(x: 0.3, y: 0.3, w: 0.25, h: 0.18)
                        dismiss()
                    } label: {
                        Text("Add Department")
                            .font(.system(size: 17, weight: .black)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(hex: "#E0E0E0")
                                : Color(hex: palette.accentColor))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
                .padding(.top, 8)
            }
            .navigationTitle("New Department")
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
            // Auto-select first unused color
            let idx = allDepartmentColors.firstIndex { !usedAccents.contains($0.accentColor) } ?? 0
            colorIdx = idx
        }
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold)).foregroundColor(.appGray).tracking(0.8)
            .padding(.horizontal, 20).padding(.bottom, 8)
    }
}
