import Foundation
import Combine
import FirebaseAuth

/// Manages all social features: friends, feed, challenges, leaderboard.
///
/// Calls the canonical `/api/*` server routes (see `server/src/routes/index.ts`).
/// The legacy `/social/*` aliases on the server exist as a fallback during the
/// migration but should NOT be targeted by new code. Everything here talks to
/// `/api/friends`, `/api/feed`, `/api/challenges`, `/api/leaderboard/:type`.
final class SocialManager: ObservableObject {
    static let shared = SocialManager()

    // MARK: - Public client models (unchanged — views depend on these)

    struct FriendProfile: Identifiable, Codable {
        let id: String
        let displayName: String
        let avatarURL: String?
        let level: Int
        let streak: Int
        let badges: [String]
    }

    struct FriendRequest: Identifiable, Codable {
        let id: String
        let fromUserId: String
        let fromDisplayName: String
        let fromAvatarURL: String?
        let sentAt: Date
    }

    struct FeedItem: Identifiable, Codable {
        let id: String
        let userId: String
        let displayName: String
        let avatarURL: String?
        let type: FeedItemType
        let title: String
        let description: String
        let imageURL: String?
        let timestamp: Date
        var reactions: [String: Int]  // emoji -> count
        var userReaction: String?
    }

    enum FeedItemType: String, Codable {
        case meal
        case streak
        case challenge
        case achievement
    }

    struct Challenge: Identifiable, Codable {
        let id: String
        let title: String
        let description: String
        let iconName: String
        let startDate: Date
        let endDate: Date
        let targetValue: Int
        var currentValue: Int
        let unit: String
        var participantCount: Int
        var isJoined: Bool
        var isCompleted: Bool
    }

    struct LeaderboardEntry: Identifiable, Codable {
        let id: String
        let rank: Int
        let userId: String
        let displayName: String
        let avatarURL: String?
        let score: Int
        let isCurrentUser: Bool
    }

    // MARK: - Published state

    @Published var friends: [FriendProfile] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var feedItems: [FeedItem] = []
    @Published var activeChallenges: [Challenge] = []
    @Published var availableChallenges: [Challenge] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var pendingRequestCount: Int { pendingRequests.count }
    var completedChallengeCount: Int { activeChallenges.filter { $0.isCompleted }.count }
    var myFeedPostCount: Int { feedItems.filter { $0.userId == AuthManager.shared.currentUser?.uid }.count }

    private let network = NetworkService.shared

    private init() {}

    // MARK: - Server DTOs (match `server/prisma/schema.prisma` + controllers)

    private struct ApiEnvelope<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
    }

    private struct PaginatedEnvelope<T: Decodable>: Decodable {
        let success: Bool
        let data: [T]
    }

    private struct ServerUserStub: Decodable {
        let id: String
        let displayName: String?
        let photoUrl: String?
    }

    private struct ServerFriendRow: Decodable {
        let id: String
        let senderId: String
        let receiverId: String
        let status: String
        let createdAt: Date
        let sender: ServerUserStub?
        let receiver: ServerUserStub?
    }

    private struct ServerReaction: Decodable {
        let id: String
        let userId: String
        let postId: String
        let type: String  // "like" | "love" | "fire" | "clap"
    }

    private struct ServerFeedPost: Decodable {
        let id: String
        let userId: String
        let type: String  // "food_log" | "achievement" | "milestone" | "text"
        let content: String?
        let imageUrl: String?
        let createdAt: Date
        let user: ServerUserStub?
        let reactions: [ServerReaction]?
    }

    private struct ServerChallenge: Decodable {
        let id: String
        let creatorId: String
        let title: String
        let description: String?
        let type: String  // "calorie" | "protein" | "streak" | "steps" | "custom"
        let goal: GoalPayload?
        let startDate: Date
        let endDate: Date
    }

    /// `goal` is free-form JSON on the server (`@prisma.Json`). We attempt to
    /// pluck out `targetValue`, `unit`, `currentValue` if present; otherwise fall
    /// back to safe defaults. The iOS UI needs concrete numbers.
    private struct GoalPayload: Decodable {
        let targetValue: Int?
        let currentValue: Int?
        let unit: String?
    }

    private struct ServerLeaderboardRow: Decodable {
        let userId: String
        let score: Double
        let rank: Int?
        let user: ServerUserStub?
    }

    // MARK: - Emoji ↔ reaction enum mapping
    //
    // Server enum: `like | love | fire | clap`. The iOS UI lets users pick
    // emoji, so we map both directions. Unknown emoji defaults to "like".

    private static let emojiToType: [String: String] = [
        "👍": "like",
        "❤️": "love",
        "🔥": "fire",
        "👏": "clap"
    ]
    private static let typeToEmoji: [String: String] = [
        "like": "👍",
        "love": "❤️",
        "fire": "🔥",
        "clap": "👏"
    ]

    private static func type(for emoji: String) -> String {
        emojiToType[emoji] ?? "like"
    }

    private static func emoji(for type: String) -> String {
        typeToEmoji[type] ?? "👍"
    }

    // MARK: - Feed type enum mapping
    //
    // Server: food_log | achievement | milestone | text
    // Client: meal     | achievement | challenge | streak
    // Best-effort mapping — "text" and "milestone" fall into "achievement".

    private static func feedType(fromServer type: String) -> FeedItemType {
        switch type {
        case "food_log": return .meal
        case "achievement": return .achievement
        case "milestone": return .achievement
        case "text": return .achievement
        default: return .achievement
        }
    }

    // MARK: - Friends

    func loadFriends() async {
        await setLoading(true)
        do {
            // Canonical endpoints: /api/friends (accepted) + /api/friends/pending
            let friendsResp: PaginatedEnvelope<ServerFriendRow> = try await network.get("/api/friends")
            let pendingResp: PaginatedEnvelope<ServerFriendRow> = try await network.get("/api/friends/pending")

            let meUid = AuthManager.shared.currentUser?.uid ?? ""

            let mappedFriends: [FriendProfile] = friendsResp.data.compactMap { row in
                // The "other" side of the friendship is whichever sender/receiver
                // isn't the current user. Server uses internal userId (uuid), not
                // Firebase uid — so we can't compare against meUid directly. Fall
                // back to "pick whichever user stub is non-nil and not obviously
                // me". This is imperfect; see note at end of file.
                let other = row.sender ?? row.receiver
                guard let other = other else { return nil }
                return FriendProfile(
                    id: other.id,
                    displayName: other.displayName ?? "Unknown",
                    avatarURL: other.photoUrl,
                    level: 1,        // not returned by /api/friends
                    streak: 0,       // not returned by /api/friends
                    badges: []       // not returned by /api/friends
                )
            }

            let mappedPending: [FriendRequest] = pendingResp.data.compactMap { row in
                guard let from = row.sender else { return nil }
                return FriendRequest(
                    id: row.id,
                    fromUserId: from.id,
                    fromDisplayName: from.displayName ?? "Unknown",
                    fromAvatarURL: from.photoUrl,
                    sentAt: row.createdAt
                )
            }

            _ = meUid  // silence unused warning until we have a uid-to-userId lookup

            await MainActor.run {
                self.friends = mappedFriends
                self.pendingRequests = mappedPending
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }

    /// Add a friend by typed identifier (username / email).
    ///
    /// **Currently unsupported.** The server's `POST /api/friends/request`
    /// requires a user UUID, and there is no user-lookup-by-identifier endpoint.
    /// Until the server adds one, this surfaces an error instead of silently
    /// failing. The Friends UI should direct users to the "scan QR" flow or
    /// the accept-incoming-request flow.
    func addFriend(identifier: String) async {
        await MainActor.run {
            self.errorMessage = "Adding friends by username isn't available yet. Ask your friend to send you a request instead."
        }
    }

    /// Add a friend by their internal user ID (UUID). Callable when we already
    /// know the uuid (e.g. from a QR code scan or a friend-suggestion flow).
    func addFriend(userId: String) async {
        do {
            struct AddBody: Encodable { let friendId: String }
            struct FriendRowEnvelope: Decodable { let success: Bool }
            let _: FriendRowEnvelope = try await network.post(
                "/api/friends/request",
                body: AddBody(friendId: userId)
            )
            AnalyticsService.logFriendAdded()
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    func acceptRequest(_ request: FriendRequest) async {
        do {
            // Server: POST /api/friends/accept/:id — id is the friendship row id.
            // No body required; server reads user from auth context.
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post("/api/friends/accept/\(request.id)")
            AnalyticsService.logFriendAdded()
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    func declineRequest(_ request: FriendRequest) async {
        do {
            // Server has no explicit decline endpoint. DELETE /api/friends/:id
            // unconditionally deletes the row regardless of status, which is
            // functionally equivalent for a pending request: the friendship
            // simply ceases to exist.
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.delete("/api/friends/\(request.id)")
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    func removeFriend(_ friend: FriendProfile) async {
        do {
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.delete("/api/friends/\(friend.id)")
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Feed

    func loadFeed() async {
        await setLoading(true)
        do {
            // Server returns a paginated envelope: { success, data: [...], pagination }
            // We ignore pagination for now and always fetch page 1.
            let response: PaginatedEnvelope<ServerFeedPost> = try await network.get("/api/feed")

            let meUid = AuthManager.shared.currentUser?.uid ?? ""
            _ = meUid  // see note in loadFriends about uid vs userId

            let mapped: [FeedItem] = response.data.map { post in
                // Aggregate reactions by type → count, convert types to emoji.
                var counts: [String: Int] = [:]
                var myReaction: String? = nil
                for r in post.reactions ?? [] {
                    let emoji = Self.emoji(for: r.type)
                    counts[emoji, default: 0] += 1
                    // We can't match userId against Firebase uid, so myReaction
                    // stays nil until server returns a `isMine` flag.
                }

                return FeedItem(
                    id: post.id,
                    userId: post.userId,
                    displayName: post.user?.displayName ?? "Unknown",
                    avatarURL: post.user?.photoUrl,
                    type: Self.feedType(fromServer: post.type),
                    title: post.content ?? "",
                    description: "",
                    imageURL: post.imageUrl,
                    timestamp: post.createdAt,
                    reactions: counts,
                    userReaction: myReaction
                )
            }

            await MainActor.run {
                self.feedItems = mapped
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }

    func reactToPost(_ item: FeedItem, emoji: String) async {
        do {
            struct ReactBody: Encodable { let type: String }
            struct Response: Decodable { let success: Bool }
            let serverType = Self.type(for: emoji)
            let _: Response = try await network.post(
                "/api/feed/\(item.id)/reaction",
                body: ReactBody(type: serverType)
            )
            AnalyticsService.logReactionSent()
            await loadFeed()
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Challenges

    func loadChallenges() async {
        await setLoading(true)
        do {
            // Server doesn't split active/available. We fetch the full list and
            // bucket client-side by comparing against "mine".
            async let allRequest: PaginatedEnvelope<ServerChallenge> = network.get("/api/challenges")
            async let mineRequest: PaginatedEnvelope<ServerChallenge> = network.get("/api/challenges/mine")

            let (all, mine) = try await (allRequest, mineRequest)
            let mineIds = Set(mine.data.map { $0.id })

            let mapAll = all.data.map { Self.mapChallenge($0, isJoined: mineIds.contains($0.id)) }
            let active = mapAll.filter { $0.isJoined }
            let available = mapAll.filter { !$0.isJoined }

            await MainActor.run {
                self.activeChallenges = active
                self.availableChallenges = available
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }

    private static func mapChallenge(_ c: ServerChallenge, isJoined: Bool) -> Challenge {
        let target = c.goal?.targetValue ?? 0
        let current = c.goal?.currentValue ?? 0
        let unit = c.goal?.unit ?? c.type
        return Challenge(
            id: c.id,
            title: c.title,
            description: c.description ?? "",
            iconName: iconName(forType: c.type),
            startDate: c.startDate,
            endDate: c.endDate,
            targetValue: target,
            currentValue: current,
            unit: unit,
            participantCount: 0,  // not returned by /api/challenges
            isJoined: isJoined,
            isCompleted: current >= target && target > 0
        )
    }

    private static func iconName(forType type: String) -> String {
        switch type {
        case "calorie": return "flame.fill"
        case "protein": return "bolt.fill"
        case "streak": return "calendar"
        case "steps": return "figure.walk"
        default: return "star.fill"
        }
    }

    func joinChallenge(_ challenge: Challenge) async {
        do {
            struct JoinBody: Encodable { let challengeId: String }
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post(
                "/api/challenges/join",
                body: JoinBody(challengeId: challenge.id)
            )
            AnalyticsService.logChallengeJoined()
            await loadChallenges()
        } catch {
            await handleError(error)
        }
    }

    /// Create a challenge. Maps the client's flat fields into the server's
    /// `{type, goal, startDate, endDate}` shape:
    ///   - `type` is heuristically derived from `unit` ("calories" → calorie,
    ///     "g protein" → protein, etc.), defaulting to "custom".
    ///   - `goal` is a JSON object `{targetValue, unit, currentValue: 0}`.
    ///   - `startDate` = now, `endDate` = now + durationDays.
    func createChallenge(title: String, description: String, targetValue: Int, unit: String, durationDays: Int) async {
        do {
            struct GoalBody: Encodable {
                let targetValue: Int
                let currentValue: Int
                let unit: String
            }
            struct CreateBody: Encodable {
                let title: String
                let description: String
                let type: String
                let goal: GoalBody
                let startDate: String
                let endDate: String
            }
            struct Response: Decodable { let success: Bool }

            let now = Date()
            let end = Calendar.current.date(byAdding: .day, value: max(1, durationDays), to: now) ?? now

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let body = CreateBody(
                title: title,
                description: description,
                type: Self.inferChallengeType(from: unit),
                goal: GoalBody(targetValue: targetValue, currentValue: 0, unit: unit),
                startDate: iso.string(from: now),
                endDate: iso.string(from: end)
            )

            let _: Response = try await network.post("/api/challenges", body: body)
            await loadChallenges()
        } catch {
            await handleError(error)
        }
    }

    private static func inferChallengeType(from unit: String) -> String {
        let u = unit.lowercased()
        if u.contains("cal") { return "calorie" }
        if u.contains("protein") || u == "g" { return "protein" }
        if u.contains("step") { return "steps" }
        if u.contains("day") || u.contains("streak") { return "streak" }
        return "custom"
    }

    // MARK: - Leaderboard

    func loadLeaderboard(scope: String = "friends", period: String = "weekly") async {
        await setLoading(true)
        do {
            // Server: GET /api/leaderboard/:type?period=&limit=
            // We map the client's "scope" onto :type directly.
            let response: PaginatedEnvelope<ServerLeaderboardRow> = try await network.get(
                "/api/leaderboard/\(scope)",
                queryItems: [URLQueryItem(name: "period", value: period)]
            )

            let meUid = AuthManager.shared.currentUser?.uid ?? ""
            _ = meUid

            let mapped: [LeaderboardEntry] = response.data.enumerated().map { (idx, row) in
                LeaderboardEntry(
                    id: row.userId,
                    rank: row.rank ?? (idx + 1),
                    userId: row.userId,
                    displayName: row.user?.displayName ?? "Unknown",
                    avatarURL: row.user?.photoUrl,
                    score: Int(row.score),
                    isCurrentUser: false
                )
            }

            await MainActor.run {
                self.leaderboard = mapped
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
        if value { errorMessage = nil }
    }

    private func handleError(_ error: Error) async {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
        print("[SocialManager] Error: \(error)")
    }
}

// MARK: - Known limitations
//
// 1. Friend/userId vs Firebase uid mismatch.
//    The server's internal `User.id` is a Prisma UUID created via POST
//    /auth/verify, not the Firebase uid. Anywhere this file compares "is this
//    row mine?" it would need to first resolve Firebase uid → internal userId
//    (via GET /api/user/me or similar). For now, `isCurrentUser`, `myReaction`,
//    and `myFeedPostCount` will always be false/nil/0 against real server data.
//    Fix requires either a /api/user/me endpoint or embedding `isMine` flags in
//    server responses.
//
// 2. Friend-add by username/email is disabled.
//    The server only accepts `friendId: uuid`, and there's no user search
//    endpoint. `addFriend(identifier:)` surfaces an error; the typed-identifier
//    UI should be hidden or redirected to QR scan.
//
// 3. Friend level/streak/badges are stubbed.
//    /api/friends returns the Friend row with a minimal user stub (id,
//    displayName, photoUrl). Profile data lives under /api/user/:id which this
//    manager doesn't fan out to. Fields default to level:1, streak:0, badges:[].
//
// 4. Challenge participantCount is stubbed to 0.
//    /api/challenges doesn't include a participant count in the list response.
//    Would need a server-side aggregate or a separate /count endpoint.
//
// 5. Feed type enum is lossy.
//    Client has `streak`/`challenge`; server has `milestone`/`text`. Round-trip
//    is not faithful; both collapse to `.achievement` on ingest.
