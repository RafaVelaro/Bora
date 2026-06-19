import Foundation

/// Thin, dependency-free client over the Supabase REST + Auth API.
/// Handles email one-time-code auth, session persistence, token refresh, and
/// generic PostgREST requests.
@MainActor
final class BoraAPI {
    static let shared = BoraAPI()

    private let urlSession = URLSession.shared
    private let sessionKey = "bora.session.v1"
    private(set) var session: StoredSession?

    init() { load() }

    // MARK: Session state

    var isSignedIn: Bool { session != nil }
    var currentUserId: String? { session?.userId }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return }
        session = try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    private func persist() {
        if let session, let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }

    private func store(_ token: TokenResponse) {
        session = StoredSession(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            userId: token.user.id,
            email: token.user.email,
            expiresAt: token.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        )
        persist()
    }

    func signOut() {
        session = nil
        persist()
    }

    // MARK: URLs / headers

    private func base() throws -> URL {
        guard BoraConfig.isConfigured, let url = BoraConfig.baseURL else {
            throw BoraError.notConfigured
        }
        return url
    }

    private func headers(authed: Bool) -> [String: String] {
        let bearer = (authed ? session?.accessToken : nil) ?? BoraConfig.supabaseAnonKey
        return [
            "apikey": BoraConfig.supabaseAnonKey,
            "Authorization": "Bearer \(bearer)",
            "Content-Type": "application/json"
        ]
    }

    // MARK: Auth — email one-time code

    /// Send a 6-digit code (and/or magic link) to the email address.
    func sendEmailCode(_ email: String) async throws {
        let url = try base().appendingPathComponent("auth/v1/otp")
        let body = try JSONSerialization.data(withJSONObject: ["email": email, "create_user": true])
        _ = try await send(url, method: "POST", body: body, authed: false)
    }

    /// Verify the code the user typed; on success, stores the session.
    func verifyEmailCode(email: String, code: String) async throws {
        let url = try base().appendingPathComponent("auth/v1/verify")
        let body = try JSONSerialization.data(withJSONObject: [
            "type": "email", "email": email, "token": code
        ])
        let data = try await send(url, method: "POST", body: body, authed: false)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        store(token)
    }

    /// Refresh the access token if it has expired (or is about to).
    private func refreshIfNeeded() async throws {
        guard let session else { return }
        if let exp = session.expiresAt, exp.timeIntervalSinceNow > 60 { return }
        var comps = URLComponents(url: try base().appendingPathComponent("auth/v1/token"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        let body = try JSONSerialization.data(withJSONObject: ["refresh_token": session.refreshToken])
        let data = try await send(comps.url!, method: "POST", body: body, authed: false)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        store(token)
    }

    // MARK: Auth — email + password (temporary login for testing the backend)

    /// Create a new account. With "Confirm email" disabled, this returns a
    /// session immediately.
    func signUpWithPassword(email: String, password: String) async throws {
        let url = try base().appendingPathComponent("auth/v1/signup")
        let body = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        let data = try await send(url, method: "POST", body: body, authed: false)
        store(try JSONDecoder().decode(TokenResponse.self, from: data))
    }

    /// Sign in with email + password.
    func signInWithPassword(email: String, password: String) async throws {
        var comps = URLComponents(url: try base().appendingPathComponent("auth/v1/token"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        let body = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        let data = try await send(comps.url!, method: "POST", body: body, authed: false)
        store(try JSONDecoder().decode(TokenResponse.self, from: data))
    }

    // MARK: PostgREST

    /// GET rows from a table, decoding into `[T]`.
    func select<T: Decodable>(_ table: String,
                              query: [URLQueryItem] = [],
                              as type: T.Type) async throws -> [T] {
        try await refreshIfNeeded()
        var comps = URLComponents(url: try base().appendingPathComponent("rest/v1/\(table)"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = query
        let data = try await send(comps.url!, method: "GET", body: nil, authed: true)
        return try JSONDecoder().decode([T].self, from: data)
    }

    /// INSERT rows. When `returning` is true, the inserted rows are returned.
    @discardableResult
    func insert<Row: Encodable>(_ table: String,
                                rows: [Row],
                                returning: Bool = false) async throws -> Data {
        try await refreshIfNeeded()
        let url = try base().appendingPathComponent("rest/v1/\(table)")
        let body = try JSONEncoder().encode(rows)
        let prefer = returning ? "return=representation" : "return=minimal"
        return try await send(url, method: "POST", body: body, authed: true,
                              extraHeaders: ["Prefer": prefer])
    }

    /// DELETE rows matching the query.
    func delete(_ table: String, query: [URLQueryItem]) async throws {
        try await refreshIfNeeded()
        var comps = URLComponents(url: try base().appendingPathComponent("rest/v1/\(table)"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = query
        _ = try await send(comps.url!, method: "DELETE", body: nil, authed: true,
                           extraHeaders: ["Prefer": "return=minimal"])
    }

    /// Call a Postgres function (RPC).
    @discardableResult
    func rpc(_ name: String, body: [String: Any]) async throws -> Data {
        try await refreshIfNeeded()
        let url = try base().appendingPathComponent("rest/v1/rpc/\(name)")
        let data = try JSONSerialization.data(withJSONObject: body)
        return try await send(url, method: "POST", body: data, authed: true)
    }

    // MARK: Transport

    private func send(_ url: URL,
                      method: String,
                      body: Data?,
                      authed: Bool,
                      extraHeaders: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        for (k, v) in headers(authed: authed) { request.setValue(v, forHTTPHeaderField: k) }
        for (k, v) in extraHeaders { request.setValue(v, forHTTPHeaderField: k) }

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BoraError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw BoraError.server(Self.errorMessage(from: data, status: http.statusCode))
        }
        return data
    }

    private static func errorMessage(from data: Data, status: Int) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let msg = obj["msg"] as? String { return msg }
            if let msg = obj["message"] as? String { return msg }
            if let msg = obj["error_description"] as? String { return msg }
        }
        return "Request failed (\(status))."
    }
}
