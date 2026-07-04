import SwiftUI

struct AccountSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    private var initials: String {
        let src = vm.currentUser?.name ?? vm.currentUser?.email ?? "?"
        return String(src.prefix(1)).uppercased()
    }

    private var syncBanner: (icon: String, text: String, tint: Color, bg: Color) {
        switch vm.sync.status {
        case .synced:
            return ("checkmark.circle.fill", "Your list & map are synced to the cloud",
                    .appGreen, Color(hex: "#F0FFF4"))
        case .syncing:
            return ("arrow.triangle.2.circlepath", "Syncing your changes…",
                    .appGray, Color(hex: "#F7F5F2"))
        case .failed:
            return ("exclamationmark.triangle.fill", "Couldn't sync — will retry automatically",
                    .appRed, Color(hex: "#FFF0F1"))
        case .idle:
            return ("icloud", "Waiting to sync",
                    .appGray, Color(hex: "#F7F5F2"))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Avatar + info
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.appRed)
                            .frame(width: 72, height: 72)
                            .overlay(Text(initials).font(.system(size: 30, weight: .black)).foregroundColor(.white))

                        VStack(spacing: 4) {
                            Text(vm.currentUser?.name ?? "Account")
                                .font(.system(size: 22, weight: .black)).foregroundColor(.appDark)
                            Text(vm.currentUser?.email ?? "")
                                .font(.system(size: 14)).foregroundColor(.appGray)
                        }
                    }
                    .padding(.top, 24).padding(.bottom, 20)

                    // Sync status
                    HStack(spacing: 8) {
                        Image(systemName: syncBanner.icon).foregroundColor(syncBanner.tint)
                        Text(syncBanner.text)
                            .font(.system(size: 13)).foregroundColor(syncBanner.tint)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(syncBanner.bg)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(syncBanner.tint.opacity(0.3), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20).padding(.bottom, 24)

                    // Manage account
                    VStack(spacing: 0) {
                        NavigationLink { EditNameView() } label: {
                            manageRow(icon: "pencil", label: "Edit Name")
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { ChangePasswordView() } label: {
                            manageRow(icon: "key", label: "Change Password")
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { DeleteAccountView() } label: {
                            manageRow(icon: "trash", label: "Delete Account", tint: .appRed)
                        }
                    }
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ECECEC"), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20).padding(.bottom, 24)

                    Button {
                        Task {
                            await vm.signOut()
                            dismiss()
                        }
                    } label: {
                        Text("Sign Out")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#FFF0F1"))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#FFCDD2"), lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        // Account deletion happens in a pushed view, where `dismiss` would only
        // pop the navigation stack; close the whole sheet once signed out so it
        // doesn't swap to the sign-in form in place.
        .onChange(of: vm.isLoggedIn) { _, loggedIn in
            if !loggedIn { dismiss() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func manageRow(icon: String, label: String, tint: Color = .appDark) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint == .appDark ? .appGray : tint)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#C7C7CC"))
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - Edit Name

private struct EditNameView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var error = ""
    @State private var loading = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var canSubmit: Bool {
        !trimmedName.isEmpty && trimmedName != vm.currentUser?.name && !loading
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                fieldLabel("Name")
                TextField("Your name", text: $name)
                    .textContentType(.name)
                    .submitLabel(.done)
                    .onSubmit { if canSubmit { Task { await submit() } } }
                    .accountFieldStyle()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                errorBanner(error)

                submitButton("Save", enabled: canSubmit, loading: loading) {
                    Task { await submit() }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Edit Name")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { name = vm.currentUser?.name ?? "" }
    }

    private func submit() async {
        error = ""
        loading = true
        do {
            try await vm.updateName(trimmedName)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

// MARK: - Change Password

private struct ChangePasswordView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var error = ""
    @State private var loading = false

    private var canSubmit: Bool {
        !current.isEmpty && !newPassword.isEmpty && !confirm.isEmpty && !loading
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                fieldLabel("Current password")
                SecureField("Your current password", text: $current)
                    .textContentType(.password)
                    .accountFieldStyle()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                fieldLabel("New password")
                SecureField("Min 8 characters", text: $newPassword)
                    .textContentType(.newPassword)
                    .accountFieldStyle()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                fieldLabel("Confirm new password")
                SecureField("Repeat new password", text: $confirm)
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .onSubmit { if canSubmit { Task { await submit() } } }
                    .accountFieldStyle()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                errorBanner(error)

                submitButton("Change Password", enabled: canSubmit, loading: loading) {
                    Task { await submit() }
                }

                Text("You'll stay signed in on this device. Any other devices will be signed out.")
                    .font(.system(size: 12))
                    .foregroundColor(.appGray)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
            .padding(.top, 20)
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        error = ""
        guard newPassword.count >= 8 else {
            error = "New password must be at least 8 characters."
            return
        }
        guard newPassword == confirm else {
            error = "New passwords don't match."
            return
        }
        guard newPassword != current else {
            error = "New password must be different from the current one."
            return
        }
        loading = true
        do {
            try await vm.changePassword(current: current, new: newPassword)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

// MARK: - Delete Account

private struct DeleteAccountView: View {
    @EnvironmentObject var vm: AppViewModel

    @State private var password = ""
    @State private var error = ""
    @State private var loading = false
    @State private var confirming = false

    private var canSubmit: Bool { !password.isEmpty && !loading }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.appRed)
                    Text("This permanently deletes your account and all data synced to the cloud. It can't be undone.\n\nThe list and map currently on this device will stay on the device.")
                        .font(.system(size: 13))
                        .foregroundColor(.appDark)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#FFF0F1"))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#FFCDD2"), lineWidth: 1.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                fieldLabel("Confirm your password")
                SecureField("Your password", text: $password)
                    .textContentType(.password)
                    .accountFieldStyle()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                errorBanner(error)

                Button {
                    confirming = true
                } label: {
                    Group {
                        if loading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Delete My Account")
                                .font(.system(size: 17, weight: .black))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSubmit ? Color.appRed : Color(hex: "#E0E0E0"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canSubmit)
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete your account?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Delete Account & Cloud Data", role: .destructive) {
                Task { await submit() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account and cloud data will be permanently deleted. This can't be undone.")
        }
    }

    private func submit() async {
        error = ""
        loading = true
        do {
            // On success the sheet closes itself via the root's isLoggedIn observer.
            try await vm.deleteAccount(password: password)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

// MARK: - Shared styling

private func fieldLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 11, weight: .semibold)).foregroundColor(.appGray).tracking(0.8)
        .padding(.horizontal, 20).padding(.bottom, 8)
}

@ViewBuilder
private func errorBanner(_ error: String) -> some View {
    if !error.isEmpty {
        Text(error)
            .font(.system(size: 13))
            .foregroundColor(.appRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(hex: "#FFF0F1"))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#FFCDD2"), lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
    }
}

private func submitButton(_ title: String, enabled: Bool, loading: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Group {
            if loading {
                ProgressView().tint(.white)
            } else {
                Text(title).font(.system(size: 17, weight: .black))
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(enabled ? Color.appRed : Color(hex: "#E0E0E0"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .disabled(!enabled)
    .padding(.horizontal, 20)
}

private extension View {
    func accountFieldStyle() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color(hex: "#F7F5F2"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ECECEC"), lineWidth: 1.5))
    }
}
