import Foundation

// MARK: - Errors

enum BoraError: LocalizedError {
    case notConfigured
    case notSignedIn
    case badResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Backend is not configured yet."
        case .notSignedIn: return "You need to be signed in."
        case .badResponse: return "Unexpected response from the server."
        case .server(let msg): return msg
        }
    }
}

// MARK: - ISO8601 date helpers
//
// We keep timestamps as Strings in the DTOs and convert explicitly, so a single
// JSONDecoder can handle both ISO date strings and the integer expiry in auth
// responses without a global date strategy conflict.

enum ISO {
    private static let withFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func date(from string: String) -> Date? {
        withFraction.date(from: string) ?? plain.date(from: string)
    }

    static func string(from date: Date) -> String {
        plain.string(from: date)
    }
}

// MARK: - Database DTOs

struct ProfileDTO: Codable {
    let id: String
    var handle: String?
    var displayName: String
    var colorIndex: Int
    var timeZone: String

    enum CodingKeys: String, CodingKey {
        case id, handle
        case displayName = "display_name"
        case colorIndex = "color_index"
        case timeZone = "time_zone"
    }
}

struct FriendshipDTO: Codable {
    let userA: String
    let userB: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case userA = "user_a"
        case userB = "user_b"
        case status
    }
}

struct BusyBlockDTO: Codable {
    let userId: String
    let startsAt: String
    let endsAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }
}

struct InviteDTO: Codable {
    let token: String
    let inviterId: String

    enum CodingKeys: String, CodingKey {
        case token
        case inviterId = "inviter_id"
    }
}

// MARK: - Insert payloads (omit server-managed columns)

struct BusyBlockInsert: Encodable {
    let user_id: String
    let starts_at: String
    let ends_at: String
}

struct InviteInsert: Encodable {
    let inviter_id: String
}

// MARK: - Auth

struct AuthUser: Codable {
    let id: String
    let email: String?
}

/// Response from /auth/v1/verify and the refresh-token endpoint.
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int?
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}

/// Persisted session (stored locally between launches).
struct StoredSession: Codable {
    var accessToken: String
    var refreshToken: String
    var userId: String
    var email: String?
    var expiresAt: Date?
}
