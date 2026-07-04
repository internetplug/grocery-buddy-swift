import SwiftUI

struct EditDepartmentSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var editingId: String? = nil
    @State private var confirmDeleteId: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(vm.categories) { cat in
                        HStack(spacing: 8) {
                            Button { editingId = cat.id } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: cat.color))
                                        .frame(width: 44, height: 44)
                                        .overlay(Text(cat.emoji).font(.system(size: 22)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cat.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.appDark).lineLimit(1)
                                        if !cat.aisle.trimmingCharacters(in: .whitespaces).isEmpty {
                                            Text(cat.aisle).font(.system(size: 11)).foregroundColor(.appGray).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.appGray)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)

                            Button {
                                if confirmDeleteId == cat.id {
                                    vm.deleteCategory(cat.id)
                                    confirmDeleteId = nil
                                } else {
                                    confirmDeleteId = cat.id
                                }
                            } label: {
                                Group {
                                    if confirmDeleteId == cat.id {
                                        Text("Sure?")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.appRed)
                                            .padding(.horizontal, 10)
                                    } else {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(hex: "#B0B0B0"))
                                    }
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                                    confirmDeleteId == cat.id ? Color.appRed : Color.appBorder, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 24)
            }
            .background(Color.appBg)
            .navigationTitle("Edit Departments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(item: $editingId) { id in
                if let cat = vm.categories.first(where: { $0.id == id }) {
                    DepartmentEditorView(category: cat) { updated in
                        vm.updateCategory(updated)
                        editingId = nil
                    }
                }
            }
            .onChange(of: editingId) { _, _ in confirmDeleteId = nil }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct DepartmentEditorView: View {
    let category: CustomCategory
    let onSave: (CustomCategory) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var aisle: String
    @State private var selectedEmoji: String
    @State private var colorIdx: Int

    init(category: CustomCategory, onSave: @escaping (CustomCategory) -> Void) {
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category.name)
        _aisle = State(initialValue: category.aisle)
        _selectedEmoji = State(initialValue: category.emoji)
        let idx = departmentColorOptions.firstIndex(where: { $0.accentColor == category.accentColor }) ?? 0
        _colorIdx = State(initialValue: idx)
    }

    private var palette: (color: String, textColor: String, accentColor: String) { departmentColorOptions[colorIdx] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: palette.color))
                        .frame(width: 44, height: 44)
                        .overlay(Text(selectedEmoji).font(.system(size: 24)))
                    VStack(alignment: .leading) {
                        Text(name.isEmpty ? "Department" : name)
                            .font(.system(size: 17, weight: .black)).foregroundColor(.appDark)
                        if !aisle.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text(aisle)
                                .font(.system(size: 12)).foregroundColor(.appGray)
                        }
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

                if !category.builtin {
                    label("Description")
                    TextField("e.g. Frozen goods, Pantry staples", text: $aisle)
                        .textFieldStyle(.plain).padding(12)
                        .background(Color(hex: "#F7F5F2"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1.5))
                        .padding(.horizontal, 20).padding(.bottom, 18)
                }

                label("Icon")
                DepartmentIconPicker(selectedEmoji: $selectedEmoji, palette: palette)

                label("Color")
                DepartmentColorPicker(colorIdx: $colorIdx)
                    .padding(.horizontal, 20).padding(.bottom, 24)

                Button {
                    let t = name.trimmingCharacters(in: .whitespaces)
                    guard !t.isEmpty else { return }
                    var updated = category
                    updated.name = t
                    updated.aisle = aisle.trimmingCharacters(in: .whitespaces).isEmpty ? category.aisle : aisle
                    updated.emoji = selectedEmoji
                    updated.color = palette.color
                    updated.textColor = palette.textColor
                    updated.accentColor = palette.accentColor
                    onSave(updated)
                    dismiss()
                } label: {
                    Text("Save Changes")
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
        .background(Color.appBg)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold)).foregroundColor(.appGray).tracking(0.8)
            .padding(.horizontal, 20).padding(.bottom, 8)
    }
}
