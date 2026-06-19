import Foundation

/// High-level sync operations built on `BoraAPI`. Pushes my busy blocks,
/// pulls friends + their availability, and manages invites. Produces the same
/// `Friend` model the UI already uses — so the overlap engine is untouched.
@MainActor
final class SyncService {
    private let api = BoraAPI.shared

    // MARK: Push my availability

    /// Replace my busy blocks for the given window with a fresh set.
    func pushMyBusy(_ intervals: [DateInterval], window: DateInterval) async throws {
        guard let me = api.currentUserId else { throw BoraError.notSignedIn }

        try await api.delete("busy_blocks", query: [
            URLQueryItem(name: "user_id", value: "eq.\(me)"),
            URLQueryItem(name: "starts_at", value: "gte.\(ISO.string(from: window.start))"),
            URLQueryItem(name: "starts_at", value: "lt.\(ISO.string(from: window.end))")
        ])

        let rows = intervals.map {
            BusyBlockInsert(user_id: me,
                            starts_at: ISO.string(from: $0.start),
                            ends_at: ISO.string(from: $0.end))
        }
        guard !rows.isEmpty else { return }
        try await api.insert("busy_blocks", rows: rows)
    }

    // MARK: Pull friends + availability

    /// Build the live friend list with their busy blocks for `window`.
    func loadFriends(window: DateInterval) async throws -> [Friend] {
        guard let me = api.currentUserId else { throw BoraError.notSignedIn }

        let friendships = try await api.select("friendships", query: [
            URLQueryItem(name: "status", value: "eq.accepted"),
            URLQueryItem(name: "or", value: "(user_a.eq.\(me),user_b.eq.\(me))")
        ], as: FriendshipDTO.self)

        let friendIDs = friendships.map { $0.userA == me ? $0.userB : $0.userA }
        guard !friendIDs.isEmpty else { return [] }

        let inList = "in.(" + friendIDs.joined(separator: ",") + ")"
        let profiles = try await api.select("profiles",
                                            query: [URLQueryItem(name: "id", value: inList)],
                                            as: ProfileDTO.self)

        let busyByUser = try await loadBusyByUser(window: window)

        return profiles.map { p in
            Friend(id: UUID(uuidString: p.id) ?? UUID(),
                   name: p.displayName,
                   colorIndex: p.colorIndex,
                   busy: Availability.normalize(busyByUser[p.id] ?? []))
        }
    }

    /// Fetch every busy block visible to me overlapping `window`, grouped by
    /// user. RLS guarantees this is only me + my accepted friends.
    private func loadBusyByUser(window: DateInterval) async throws -> [String: [DateInterval]] {
        let blocks = try await api.select("busy_blocks", query: [
            URLQueryItem(name: "starts_at", value: "lt.\(ISO.string(from: window.end))"),
            URLQueryItem(name: "ends_at", value: "gt.\(ISO.string(from: window.start))")
        ], as: BusyBlockDTO.self)

        var map: [String: [DateInterval]] = [:]
        for b in blocks {
            guard let s = ISO.date(from: b.startsAt),
                  let e = ISO.date(from: b.endsAt), e > s else { continue }
            map[b.userId, default: []].append(DateInterval(start: s, end: e))
        }
        return map
    }

    // MARK: Invites

    /// Create a share-link token for inviting a friend.
    func createInvite() async throws -> String {
        guard let me = api.currentUserId else { throw BoraError.notSignedIn }
        let data = try await api.insert("invites", rows: [InviteInsert(inviter_id: me)], returning: true)
        let invites = try JSONDecoder().decode([InviteDTO].self, from: data)
        guard let token = invites.first?.token else { throw BoraError.badResponse }
        return token
    }

    /// Redeem a friend's invite token (creates the friendship).
    func redeemInvite(token: String) async throws {
        _ = try await api.rpc("redeem_invite", body: ["invite_token": token])
    }

    // MARK: Plans

    /// Create a plan for a chosen subset of friends. We generate the id
    /// client-side so we don't need a representation read-back (which would hit
    /// the SELECT policy mid-insert).
    func createPlan(title: String, interval: DateInterval, guestIDs: [UUID]) async throws {
        guard let me = api.currentUserId else { throw BoraError.notSignedIn }
        let planID = UUID().uuidString.lowercased()
        try await api.insert("plans", rows: [
            PlanInsert(id: planID, creator_id: me, title: title,
                       starts_at: ISO.string(from: interval.start),
                       ends_at: ISO.string(from: interval.end))
        ])
        let rows = guestIDs.map {
            PlanParticipantInsert(plan_id: planID, user_id: $0.uuidString.lowercased())
        }
        if !rows.isEmpty {
            try await api.insert("plan_participants", rows: rows)
        }
    }

    /// Load plans I can see (created by me or that I'm invited to), with guests.
    func loadPlans() async throws -> [PlanRow] {
        try await api.select("plans", query: [
            URLQueryItem(name: "select", value: "id,creator_id,title,starts_at,ends_at,plan_participants(user_id,status)"),
            URLQueryItem(name: "order", value: "starts_at")
        ], as: PlanRow.self)
    }
}
