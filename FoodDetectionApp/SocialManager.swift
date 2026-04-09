import Foundation
import Combine
import FirebaseAuth

/// Manages all social features: friends, feed, challenges, leaderboard.
final class SocialManager: ObservableObject {
    static let shared = SocialManager()

    // MARK: - Models

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

    // MARK: - Friends

    func loadFriends() async {
        await setLoading(true)
        do {
            struct FriendsResponse: Decodable {
                let friends: [FriendProfile]
                let pendingRequests: [FriendRequest]
            }
            let response: FriendsResponse = try await network.get("/social/friends")
            await MainActor.run {
                self.friends = response.friends
                self.pendingRequests = response.pendingRequests
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }

    func addFriend(identifier: String) async {
        do {
            struct AddBody: Encodable { let identifier: String }
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post("/social/friends/add", body: AddBody(identifier: identifier))
            AnalyticsService.logFriendAdded()
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    func acceptRequest(_ request: FriendRequest) async {
        do {
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post("/social/friends/accept/\(request.id)")
            AnalyticsService.logFriendAdded()
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    func declineRequest(_ request: FriendRequest) async {
        do {
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post("/social/friends/decline/\(request.id)")
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    func removeFriend(_ friend: FriendProfile) async {
        do {
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.delete("/social/friends/\(friend.id)")
            await loadFriends()
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Feed

    func loadFeed() async {
        await setLoading(true)
        do {
            struct FeedResponse: Decodable { let items: [FeedItem] }
            let response: FeedResponse = try await network.get("/social/feed")
            await MainActor.run {
                self.feedItems = response.items
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }

    func reactToPost(_ item: FeedItem, emoji: String) async {
        do {
            struct ReactBody: Encodable { let emoji: String }
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post("/social/feed/\(item.id)/react", body: ReactBody(emoji: emoji))
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
            struct ChallengesResponse: Decodable {
                let active: [Challenge]
                let available: [Challenge]
            }
            let response: ChallengesResponse = try await network.get("/social/challenges")
            await MainActor.run {
                self.activeChallenges = response.active
                self.availableChallenges = response.available
                self.isLoading = false
            }
        } catch {
            await handleError(error)
        }
    }

    func joinChallenge(_ challenge: Challenge) async {
        do {
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post("/social/challenges/\(challenge.id)/join")
            AnalyticsService.logChallengeJoined()
            await loadChallenges()
        } catch {
            await handleError(error)
        }
    }

    func createChallenge(title: String, description: String, targetValue: Int, unit: String, durationDays: Int) async {
        do {
            struct CreateBody: Encodable {
                let title: String
                let description: String
                let targetValue: Int
                let unit: String
                let durationDays: Int
            }
            struct Response: Decodable { let success: Bool }
            let _: Response = try await network.post(
                "/social/challenges",
                body: CreateBody(title: title, description: description, targetValue: targetValue, unit: unit, durationDays: durationDays)
            )
            await loadChallenges()
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Leaderboard

    func loadLeaderboard(scope: String = "friends", period: String = "weekly") async {
        await setLoading(true)
        do {
            struct LeaderboardResponse: Decodable { let entries: [LeaderboardEntry] }
            let response: LeaderboardResponse = try await network.get(
                "/social/leaderboard",
                queryItems: [
                    URLQueryItem(name: "scope", value: scope),
                    URLQueryItem(name: "period", value: period)
                ]
            )
            await MainActor.run {
                self.leaderboard = response.entries
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
