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
    static let supabaseURL = "https://nqyovyyernsaooybjkwm.supabase.co"

    /// The "anon" / "publishable" key from Settings → API.
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xeW92eXllcm5zYW9veWJqa3dtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4NTg4ODAsImV4cCI6MjA5NzQzNDg4MH0.N8L9EE2FTy_G7pXfjnQ69Xm-bFg3N80oWWKl9xE4i4E"

    static var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }

    static var baseURL: URL? { URL(string: supabaseURL) }
}
