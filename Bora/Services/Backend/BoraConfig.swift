import Foundation

/// Backend configuration. Paste your Supabase project values here.
///
/// The **anon (publishable) key** is safe to embed in the app — Row-Level
/// Security protects the data. NEVER put the `service_role` key here.
///
/// While these are empty, the app runs in local mock mode (sample friends),
/// exactly as before. As soon as both are filled, the sign-in + live sync
/// path turns on.
enum BoraConfig {
    /// e.g. "https://abcdefgh.supabase.co"
    static let supabaseURL = ""

    /// The "anon" / "publishable" key from Settings → API.
    static let supabaseAnonKey = ""

    static var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }

    static var baseURL: URL? { URL(string: supabaseURL) }
}
