import SwiftUI

struct AuthSheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var error = ""
    @State private var loading = false

    enum Mode { case signIn, signUp }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var canSubmit: Bool { !trimmedEmail.isEmpty && !password.isEmpty && !loading }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Mode toggle
                    HStack(spacing: 0) {
                        modeTab(.signIn, label: "Sign In")
                        modeTab(.signUp, label: "Sign Up")
                    }
                    .background(Color(hex: "#F5F5F5"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    if mode == .signUp {
                        label("Name (optional)")
                        field("Your name", text: $name)
                    }

                    label("Email")
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .fieldStyle()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)

                    label("Password")
                    SecureField(mode == .signUp ? "Min 8 characters" : "Your password", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        .submitLabel(.go)
                        .onSubmit { if canSubmit { Task { await submit() } } }
                        .fieldStyle()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    if !error.isEmpty {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.appRed)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color(hex: "#FFF0F1"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#FFCDD2"), lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if loading {
                                ProgressView().tint(.white)
                            } else {
                                Text(mode == .signIn ? "Sign In" : "Create Account")
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
                    .padding(.bottom, 40)
                }
                .padding(.top, 8)
            }
            .navigationTitle(mode == .signIn ? "Sign In" : "Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func submit() async {
        error = ""
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            error = "Enter a valid email address."
            return
        }
        if mode == .signUp && password.count < 8 {
            error = "Password must be at least 8 characters."
            return
        }
        loading = true
        do {
            if mode == .signIn {
                try await vm.signIn(email: trimmedEmail, password: password)
            } else {
                let n = name.trimmingCharacters(in: .whitespaces)
                try await vm.signUp(email: trimmedEmail, password: password,
                                    name: n.isEmpty ? String(trimmedEmail.split(separator: "@").first ?? "") : n)
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    @ViewBuilder
    private func modeTab(_ m: Mode, label: String) -> some View {
        Button { withAnimation { mode = m; error = "" } } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(mode == m ? .appDark : .appGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(mode == m ? Color.white : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .shadow(color: mode == m ? .black.opacity(0.1) : .clear, radius: 2)
                .padding(4)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold)).foregroundColor(.appGray).tracking(0.8)
            .padding(.horizontal, 20).padding(.bottom, 8)
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .fieldStyle()
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
    }
}

private extension View {
    func fieldStyle() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color(hex: "#F7F5F2"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ECECEC"), lineWidth: 1.5))
    }
}
