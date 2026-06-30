import SwiftUI

struct ItemListManagerSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var saveName = ""
    @State private var confirmDelete: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionLabel("Save Current List")
                    HStack(spacing: 8) {
                        TextField("e.g. Weekly Groceries, Party Run…", text: $saveName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(hex: "#F7F5F2"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1.5))
                        Button("Save") {
                            let name = saveName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            vm.saveItemList(name: name)
                            saveName = ""
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(canSave ? .white : Color(hex: "#B0B0B0"))
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(canSave ? Color.appDark : Color(hex: "#E8E8E8"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(!canSave)
                    }
                    .padding(.horizontal, 20)

                    if vm.items.isEmpty {
                        Text("Your list is empty — add items first to save them.")
                            .font(.system(size: 12))
                            .foregroundColor(.appGray)
                            .padding(.horizontal, 20)
                    }

                    if vm.savedItemLists.isEmpty {
                        VStack(spacing: 10) {
                            Text("📝").font(.system(size: 36))
                            Text("No saved lists yet").font(.system(size: 13)).foregroundColor(Color(hex: "#B0B0B0"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                    } else {
                        sectionLabel("Saved Lists")
                        ForEach(vm.savedItemLists) { slot in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F0F0FF"))
                                    .frame(width: 38, height: 38)
                                    .overlay(Image(systemName: "list.bullet").foregroundColor(Color(hex: "#5C6BC0")))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(slot.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.appDark).lineLimit(1)
                                    Text("\(slot.items.count) item\(slot.items.count != 1 ? "s" : "")")
                                        .font(.system(size: 11)).foregroundColor(.appGray)
                                }
                                Spacer()
                                Button("Load") {
                                    vm.loadItemList(slot)
                                    dismiss()
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(Color.appDark)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button(confirmDelete == slot.id ? "Sure?" : "✕") {
                                    if confirmDelete == slot.id { vm.deleteItemList(slot.id); confirmDelete = nil }
                                    else { confirmDelete = slot.id }
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(confirmDelete == slot.id ? .appRed : Color(hex: "#B0B0B0"))
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                    confirmDelete == slot.id ? Color.appRed : Color.appBorder, lineWidth: 1.5))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Saved Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var canSave: Bool {
        !saveName.trimmingCharacters(in: .whitespaces).isEmpty && !vm.items.isEmpty
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appGray)
            .tracking(0.8)
            .padding(.horizontal, 20)
    }
}
