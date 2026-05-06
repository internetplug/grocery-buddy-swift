import SwiftUI

struct LayoutManagerSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var saveName = ""
    @State private var confirmDelete: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Save current
                    sectionLabel("Save Current Layout")
                    HStack(spacing: 8) {
                        TextField("e.g. My H-E-B, Weekend Layout…", text: $saveName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(hex: "#F7F5F2"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1.5))
                        Button("Save") {
                            let name = saveName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            vm.saveLayout(name: name)
                            saveName = ""
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(saveName.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: "#B0B0B0") : .white)
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(saveName.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: "#E8E8E8") : Color.appDark)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(saveName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 20)

                    // Saved slots
                    if vm.savedLayouts.isEmpty {
                        VStack(spacing: 10) {
                            Text("🗂️").font(.system(size: 36))
                            Text("No saved layouts yet").font(.system(size: 13)).foregroundColor(Color(hex: "#B0B0B0"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                    } else {
                        sectionLabel("Saved Layouts")
                        ForEach(vm.savedLayouts) { slot in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F0F0FF"))
                                    .frame(width: 38, height: 38)
                                    .overlay(Image(systemName: "map").foregroundColor(Color(hex: "#5C6BC0")))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(slot.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.appDark).lineLimit(1)
                                    Text("\(slot.layouts.count) zones")
                                        .font(.system(size: 11)).foregroundColor(.appGray)
                                }
                                Spacer()
                                Button("Load") {
                                    vm.loadLayout(slot)
                                    dismiss()
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(Color.appDark)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button(confirmDelete == slot.id ? "Sure?" : "✕") {
                                    if confirmDelete == slot.id { vm.deleteLayout(slot.id); confirmDelete = nil }
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
            .navigationTitle("Map Layouts")
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.appGray)
            .tracking(0.8)
            .padding(.horizontal, 20)
    }
}
