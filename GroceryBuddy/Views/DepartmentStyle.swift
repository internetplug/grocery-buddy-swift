import SwiftUI

// Shared styling constants and picker controls for the department sheets
// (AddDepartmentSheet and EditDepartmentSheet's editor).

let departmentEmojiDefaults = defaultCategories.map { $0.emoji }
let departmentEmojiExtras = ["🛒","🏪","🧺","🫙","🥡","🫕","🥗","🧆","🍱","🥘","🧇","🥞","🍳","🧈","🫒","🌿","🌾","🫚","🍶","🧋","🥤","🍵","☕","🍺","🍻","🧴","🪥","🧼","🪒","🧽","🪣","🧹","🪴","🌸","🐠","🐕","🐈","📦","🪑","💡","🔋","🧲","🛠️"]

// Unique default category colors plus 5 distinct complementary options.
let departmentColorOptions: [(color: String, textColor: String, accentColor: String)] = {
    var seen = Set<String>()
    var colors: [(color: String, textColor: String, accentColor: String)] = []
    for cat in defaultCategories where !seen.contains(cat.color) {
        colors.append((color: cat.color, textColor: cat.textColor, accentColor: cat.accentColor))
        seen.insert(cat.color)
    }
    let additional: [(color: String, textColor: String, accentColor: String)] = [
        ("#FFCDD2", "#C62828", "#E53935"), // Deep red/rose
        ("#C8E6C9", "#2E7D32", "#43A047"), // Medium green
        ("#FFCCBC", "#D84315", "#FF7043"), // Deep orange
        ("#D1C4E9", "#512DA8", "#7E57C2"), // Deep purple
        ("#B2DFDB", "#00695C", "#00897B")  // Teal
    ]
    for c in additional where !seen.contains(c.color) {
        colors.append(c)
        seen.insert(c.color)
    }
    return colors
}()

/// Two labeled emoji grids ("Default Departments" / "Other Icons"). Emits its
/// sections directly into the parent VStack via Group so spacing matches the
/// hand-rolled originals.
struct DepartmentIconPicker: View {
    @Binding var selectedEmoji: String
    let palette: (color: String, textColor: String, accentColor: String)

    var body: some View {
        Group {
            sectionHeader("Default Departments")
            emojiGrid(departmentEmojiDefaults)
                .padding(.horizontal, 20).padding(.bottom, 16)
            sectionHeader("Other Icons")
            emojiGrid(departmentEmojiExtras)
                .padding(.horizontal, 20).padding(.bottom, 18)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold)).foregroundColor(.appGray)
            .padding(.horizontal, 20).padding(.bottom, 8)
    }

    private func emojiGrid(_ emojis: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
            ForEach(emojis, id: \.self) { e in
                Button { selectedEmoji = e } label: {
                    Text(e).font(.system(size: 20))
                        .frame(width: 38, height: 38)
                        .background(selectedEmoji == e ? Color(hex: palette.color) : Color(hex: "#F7F5F2"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(selectedEmoji == e
                            ? RoundedRectangle(cornerRadius: 10).stroke(Color(hex: palette.accentColor), lineWidth: 2)
                            : RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1.5))
                }
                .accessibilityLabel("Icon \(e)")
            }
        }
    }
}

struct DepartmentColorPicker: View {
    @Binding var colorIdx: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 12), count: 6), spacing: 12) {
            ForEach(departmentColorOptions.indices, id: \.self) { i in
                Button { colorIdx = i } label: {
                    Circle()
                        .fill(Color(hex: departmentColorOptions[i].accentColor))
                        .frame(width: 38, height: 38)
                        .overlay(colorIdx == i
                            ? Circle().stroke(Color.appDark, lineWidth: 3)
                            : Circle().stroke(Color.clear, lineWidth: 2))
                }
                .accessibilityLabel("Color option \(i + 1)")
            }
        }
    }
}
