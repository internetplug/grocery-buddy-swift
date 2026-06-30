import Foundation

struct AuthUser: Codable {
    var id: String
    var name: String
    var email: String
}

struct AuthSession: Codable {
    var user: AuthUser
}

actor AuthClient {
    static let shared = AuthClient()
    private let base: String = {
        #if targetEnvironment(simulator)
        // The simulator shares the Mac's network, so talk to the local dev server
        // (`npm run dev` in grocery-buddy-api). A physical device can't reach the
        // Mac's localhost, so device/Release builds use APIBaseURL from Info.plist.
        return "http://localhost:8787"
        #else
        // APIBaseURL comes from GroceryBuddy/Info.plist (INFOPLIST_FILE), which
        // resolves to the deployed Worker URL via the API_BASE_URL build setting.
        if let url = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
           !url.isEmpty, !url.contains("REPLACE_ME") {
            return url.hasSuffix("/") ? String(url.dropLast()) : url
        }
        fatalError("APIBaseURL missing — set it in GroceryBuddy/Info.plist (INFOPLIST_FILE)")
        #endif
    }()

    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        return URLSession(configuration: config)
    }()

    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String) async throws -> AuthUser {
        let url = URL(string: "\(base)/api/auth/sign-up/email")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["email": email, "password": password, "name": name])
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["message"] ?? "Sign up failed"
            throw AuthError.message(msg)
        }
        let result = try JSONDecoder().decode(SignUpResponse.self, from: data)
        return result.user
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> AuthUser {
        let url = URL(string: "\(base)/api/auth/sign-in/email")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["email": email, "password": password])
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["message"] ?? "Sign in failed"
            throw AuthError.message(msg)
        }
        let result = try JSONDecoder().decode(SignInResponse.self, from: data)
        return result.user
    }

    // MARK: - Sign Out
    func signOut() async throws {
        let url = URL(string: "\(base)/api/auth/sign-out")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try? await session.data(for: req)
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
    }

    // MARK: - Get Session
    func getSession() async -> AuthUser? {
        let url = URL(string: "\(base)/api/auth/get-session")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        guard let (data, resp) = try? await session.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let result = try? JSONDecoder().decode(SessionResponse.self, from: data) else { return nil }
        return result.user
    }

    // MARK: - User Data
    func loadUserData() async -> CloudData? {
        let url = URL(string: "\(base)/api/user-data")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        guard let (data, resp) = try? await session.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let wrapper = try? JSONDecoder().decode(UserDataResponse.self, from: data) else { return nil }
        return wrapper.data
    }

    func saveUserData(_ payload: CloudData) async {
        let url = URL(string: "\(base)/api/user-data")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(payload)
        _ = try? await session.data(for: req)
    }
}

// MARK: - Response types
private struct SignUpResponse: Codable { var user: AuthUser }
private struct SignInResponse: Codable { var user: AuthUser }
private struct SessionResponse: Codable { var user: AuthUser? }
private struct UserDataResponse: Codable { var data: CloudData? }

struct CloudData: Codable {
    var items: [GroceryItem]
    var categories: [CustomCategory]
    var mapLayout: [String: ZoneLayout]
    var savedLayouts: [SavedLayoutSlot]
    var itemHistory: [ItemHistoryEntry]? = nil
    var savedItemLists: [SavedItemListSlot]? = nil
}

enum AuthError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case .message(let m) = self { return m }
        return "Unknown error"
    }
}
