package com.foodsense.android.services

import androidx.compose.runtime.mutableStateOf
import com.foodsense.android.data.Challenge
import com.foodsense.android.data.FeedPost
import com.foodsense.android.data.Friend
import com.foodsense.android.data.FriendRequest
import com.foodsense.android.data.LeaderboardEntry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.intOrNull
import java.time.Instant
import java.time.temporal.ChronoUnit

/**
 * Calls the canonical /api/... server routes (see server/src/routes/index.ts).
 * The legacy /api/v1/social/... aliases on the server exist as a fallback during
 * the migration but should NOT be targeted by new code. Everything here talks
 * to /api/friends, /api/feed, /api/challenges, /api/leaderboard/:type.
 */
class SocialManager(private val networkService: NetworkService) {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    // Observable state — view layer depends on these shapes being stable.
    val friends = mutableStateOf<List<Friend>>(emptyList())
    val friendRequests = mutableStateOf<List<FriendRequest>>(emptyList())
    val feedPosts = mutableStateOf<List<FeedPost>>(emptyList())
    val challenges = mutableStateOf<List<Challenge>>(emptyList())
    val leaderboard = mutableStateOf<List<LeaderboardEntry>>(emptyList())
    val isLoading = mutableStateOf(false)
    val errorMessage = mutableStateOf<String?>(null)
    val searchResults = mutableStateOf<List<Friend>>(emptyList())

    // ──────────────────────────────────────────────────────────────────────
    // Server DTOs — match `server/prisma/schema.prisma` + controllers.
    // These are internal to SocialManager and mapped to the public client
    // models above before being written to state.
    // ──────────────────────────────────────────────────────────────────────

    @Serializable
    private data class ApiEnvelopeList<T>(
        val success: Boolean = true,
        val data: List<T> = emptyList(),
    )

    @Serializable
    private data class ApiEnvelopeOne<T>(
        val success: Boolean = true,
        val data: T? = null,
    )

    @Serializable
    private data class ServerUserStub(
        val id: String = "",
        val displayName: String? = null,
        val photoUrl: String? = null,
    )

    @Serializable
    private data class ServerFriendRow(
        val id: String = "",
        val senderId: String = "",
        val receiverId: String = "",
        val status: String = "",
        val createdAt: String = "",
        val sender: ServerUserStub? = null,
        val receiver: ServerUserStub? = null,
    )

    @Serializable
    private data class ServerReaction(
        val id: String = "",
        val userId: String = "",
        val postId: String = "",
        val type: String = "like",
    )

    @Serializable
    private data class ServerFeedPost(
        val id: String = "",
        val userId: String = "",
        val type: String = "text",
        val content: String? = null,
        val imageUrl: String? = null,
        val createdAt: String = "",
        val user: ServerUserStub? = null,
        val reactions: List<ServerReaction> = emptyList(),
    )

    @Serializable
    private data class ServerChallenge(
        val id: String = "",
        val creatorId: String = "",
        val title: String = "",
        val description: String? = null,
        val type: String = "custom",
        val startDate: String = "",
        val endDate: String = "",
        // `goal` is free-form Prisma JSON. We keep it raw and parse manually.
        val goal: JsonObject? = null,
    )

    @Serializable
    private data class ServerLeaderboardRow(
        val userId: String = "",
        val score: Double = 0.0,
        val rank: Int? = null,
        val user: ServerUserStub? = null,
    )

    // Emoji ↔ reaction-enum mapping (same set as iOS).
    private val emojiToType: Map<String, String> = mapOf(
        "\uD83D\uDC4D" to "like",   // 👍
        "\u2764\uFE0F" to "love",   // ❤️
        "\uD83D\uDD25" to "fire",   // 🔥
        "\uD83D\uDC4F" to "clap",   // 👏
    )
    private val typeToEmoji: Map<String, String> = emojiToType.entries.associate { (k, v) -> v to k }

    private fun typeForEmoji(emoji: String): String = emojiToType[emoji] ?: "like"
    private fun emojiForType(type: String): String = typeToEmoji[type] ?: "\uD83D\uDC4D"

    // Feed type enum: server food_log/achievement/milestone/text → client meal/milestone/challenge_complete/streak
    private fun clientFeedType(serverType: String): String = when (serverType) {
        "food_log" -> "meal"
        "achievement" -> "milestone"
        "milestone" -> "milestone"
        "text" -> "milestone"
        else -> "milestone"
    }

    private fun parseEpochMs(iso: String): Long = try {
        Instant.parse(iso).toEpochMilli()
    } catch (_: Exception) {
        0L
    }

    // ──────────────────────────────────────────────────────────────────────
    // Friends
    // ──────────────────────────────────────────────────────────────────────

    suspend fun loadFriends() {
        safeCall {
            coroutineScope {
                val friendsDeferred = async {
                    val raw = networkService.get("/api/friends")
                    json.decodeFromString<ApiEnvelopeList<ServerFriendRow>>(raw).data
                }
                val pendingDeferred = async {
                    val raw = networkService.get("/api/friends/pending")
                    json.decodeFromString<ApiEnvelopeList<ServerFriendRow>>(raw).data
                }

                val rawFriends = friendsDeferred.await()
                val rawPending = pendingDeferred.await()

                friends.value = rawFriends.mapNotNull { row ->
                    val other = row.sender ?: row.receiver ?: return@mapNotNull null
                    Friend(
                        id = other.id,
                        displayName = other.displayName ?: "Unknown",
                        avatarUrl = other.photoUrl ?: "",
                        streak = 0,              // not returned by /api/friends
                        todayCalories = 0,       // not returned by /api/friends
                        isOnline = false,
                    )
                }

                friendRequests.value = rawPending.mapNotNull { row ->
                    val from = row.sender ?: return@mapNotNull null
                    FriendRequest(
                        id = row.id,
                        fromUserId = from.id,
                        fromDisplayName = from.displayName ?: "Unknown",
                        fromAvatarUrl = from.photoUrl ?: "",
                        timestamp = parseEpochMs(row.createdAt),
                        status = row.status,
                    )
                }
            }
        }
    }

    suspend fun loadFriendRequests() {
        // Kept for source compatibility with existing UI code. The new
        // `loadFriends()` already loads both accepted and pending rows in one
        // go, but some screens call this independently.
        safeCall {
            val raw = networkService.get("/api/friends/pending")
            val rows = json.decodeFromString<ApiEnvelopeList<ServerFriendRow>>(raw).data
            friendRequests.value = rows.mapNotNull { row ->
                val from = row.sender ?: return@mapNotNull null
                FriendRequest(
                    id = row.id,
                    fromUserId = from.id,
                    fromDisplayName = from.displayName ?: "Unknown",
                    fromAvatarUrl = from.photoUrl ?: "",
                    timestamp = parseEpochMs(row.createdAt),
                    status = row.status,
                )
            }
        }
    }

    /**
     * User search by text query.
     *
     * **Currently unsupported.** No server endpoint exists for looking up
     * users by username/email. Surfaces an error and clears the results.
     * The friend-search UI should be hidden until a search endpoint ships.
     */
    suspend fun searchUsers(query: String) {
        withContext(Dispatchers.Main) {
            searchResults.value = emptyList()
            errorMessage.value = "User search isn't available yet. Ask your friend to send you a request instead."
        }
    }

    /**
     * Send a friend request. `userId` must be the server's internal user UUID,
     * not a Firebase uid and not a username. If you only have a username/email,
     * the search endpoint must be wired up first (see `searchUsers`).
     */
    suspend fun sendFriendRequest(userId: String) {
        safeCall {
            val body = buildJsonObject { put("friendId", JsonPrimitive(userId)) }
            networkService.post("/api/friends/request", body)
            loadFriendRequests()
        }
    }

    suspend fun acceptFriendRequest(requestId: String) {
        safeCall {
            // Empty body — server reads user from auth context and friendship
            // id from the path.
            networkService.post("/api/friends/accept/$requestId", buildJsonObject {})
            loadFriendRequests()
            loadFriends()
        }
    }

    suspend fun rejectFriendRequest(requestId: String) {
        safeCall {
            // Server has no explicit reject endpoint. DELETE /api/friends/:id
            // unconditionally deletes the friendship row, which is functionally
            // equivalent for a pending request.
            networkService.delete("/api/friends/$requestId")
            loadFriendRequests()
        }
    }

    suspend fun removeFriend(friendId: String) {
        safeCall {
            networkService.delete("/api/friends/$friendId")
            loadFriends()
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Feed
    // ──────────────────────────────────────────────────────────────────────

    suspend fun loadFeed() {
        safeCall {
            val raw = networkService.get("/api/feed")
            val rows = json.decodeFromString<ApiEnvelopeList<ServerFeedPost>>(raw).data

            feedPosts.value = rows.map { post ->
                val counts = mutableMapOf<String, Int>()
                for (r in post.reactions) {
                    val emoji = emojiForType(r.type)
                    counts[emoji] = (counts[emoji] ?: 0) + 1
                }

                FeedPost(
                    id = post.id,
                    userId = post.userId,
                    displayName = post.user?.displayName ?: "Unknown",
                    avatarUrl = post.user?.photoUrl ?: "",
                    type = clientFeedType(post.type),
                    title = post.content ?: "",
                    description = "",
                    imageUrl = post.imageUrl ?: "",
                    calories = 0,           // not returned by server FeedPost
                    timestamp = parseEpochMs(post.createdAt),
                    reactions = counts,
                    myReaction = null,      // see known-limitations note at EOF
                )
            }
        }
    }

    suspend fun reactToPost(postId: String, emoji: String) {
        safeCall {
            val body = buildJsonObject {
                put("type", JsonPrimitive(typeForEmoji(emoji)))
            }
            networkService.post("/api/feed/$postId/reaction", body)
            loadFeed()
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Challenges
    // ──────────────────────────────────────────────────────────────────────

    suspend fun loadChallenges() {
        safeCall {
            coroutineScope {
                val allDeferred = async {
                    val raw = networkService.get("/api/challenges")
                    json.decodeFromString<ApiEnvelopeList<ServerChallenge>>(raw).data
                }
                val mineDeferred = async {
                    val raw = networkService.get("/api/challenges/mine")
                    json.decodeFromString<ApiEnvelopeList<ServerChallenge>>(raw).data
                }

                val all = allDeferred.await()
                val mineIds = mineDeferred.await().map { it.id }.toSet()

                challenges.value = all.map { c ->
                    val target = c.goal?.get("targetValue")?.jsonPrimitive?.intOrNull ?: 0
                    val current = c.goal?.get("currentValue")?.jsonPrimitive?.intOrNull ?: 0
                    val unit = c.goal?.get("unit")?.jsonPrimitive?.content ?: c.type
                    val joined = mineIds.contains(c.id)
                    val completed = target > 0 && current >= target

                    Challenge(
                        id = c.id,
                        title = c.title,
                        description = c.description ?: "",
                        type = c.type,
                        targetValue = target,
                        currentValue = current,
                        startDate = parseEpochMs(c.startDate),
                        endDate = parseEpochMs(c.endDate),
                        creatorId = c.creatorId,
                        creatorName = "",       // not returned by /api/challenges
                        participantCount = 0,   // not returned
                        status = when {
                            completed -> "completed"
                            joined -> "active"
                            else -> "available"
                        },
                        isJoined = joined,
                    )
                }
            }
        }
    }

    suspend fun joinChallenge(challengeId: String) {
        safeCall {
            val body = buildJsonObject { put("challengeId", JsonPrimitive(challengeId)) }
            networkService.post("/api/challenges/join", body)
            loadChallenges()
        }
    }

    /**
     * Create a challenge. The client collects `type, targetValue, durationDays`;
     * we convert these into the server's `{type, goal: object, startDate,
     * endDate}` shape. `type` is passed through if it matches the server's
     * enum, otherwise defaults to "custom".
     */
    suspend fun createChallenge(title: String, description: String, type: String, targetValue: Int, durationDays: Int) {
        safeCall {
            val serverType = when (type.lowercase()) {
                "calorie", "calories" -> "calorie"
                "protein" -> "protein"
                "streak" -> "streak"
                "steps" -> "steps"
                else -> "custom"
            }
            val now = Instant.now()
            val end = now.plus(maxOf(1L, durationDays.toLong()), ChronoUnit.DAYS)

            val body = buildJsonObject {
                put("title", JsonPrimitive(title))
                put("description", JsonPrimitive(description))
                put("type", JsonPrimitive(serverType))
                put("goal", buildJsonObject {
                    put("targetValue", JsonPrimitive(targetValue))
                    put("currentValue", JsonPrimitive(0))
                    put("unit", JsonPrimitive(type))
                })
                put("startDate", JsonPrimitive(now.toString()))
                put("endDate", JsonPrimitive(end.toString()))
            }
            networkService.post("/api/challenges", body)
            loadChallenges()
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Leaderboard
    // ──────────────────────────────────────────────────────────────────────

    suspend fun loadLeaderboard(scope: String = "weekly") {
        safeCall {
            // Server: GET /api/leaderboard/:type?period=&limit=
            // The client's "scope" parameter historically carried either a
            // category ("friends"/"global") or a period ("weekly"/"monthly").
            // We pass it through as :type; callers that want a period should
            // append `?period=...` themselves once that's threaded through.
            val raw = networkService.get("/api/leaderboard/$scope")
            val rows = json.decodeFromString<ApiEnvelopeList<ServerLeaderboardRow>>(raw).data

            leaderboard.value = rows.mapIndexed { idx, row ->
                LeaderboardEntry(
                    rank = row.rank ?: (idx + 1),
                    userId = row.userId,
                    displayName = row.user?.displayName ?: "Unknown",
                    avatarUrl = row.user?.photoUrl ?: "",
                    score = row.score.toInt(),
                    streak = 0,              // not returned by /api/leaderboard
                    isCurrentUser = false,   // see known-limitations note
                )
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────

    private suspend fun safeCall(block: suspend () -> Unit) {
        withContext(Dispatchers.Main) { isLoading.value = true; errorMessage.value = null }
        try {
            block()
        } catch (e: Exception) {
            withContext(Dispatchers.Main) {
                errorMessage.value = e.message ?: "Unknown error"
            }
        } finally {
            withContext(Dispatchers.Main) { isLoading.value = false }
        }
    }
}

// Known limitations (mirror of iOS SocialManager.swift):
//
// 1. userId vs Firebase uid mismatch — isCurrentUser / myReaction will always
//    be false/null against real server data until we have a uid→userId lookup
//    or an `isMine` flag in responses.
// 2. Friend-add by username/email is disabled — no user search endpoint.
// 3. Friend streak / today calories are stubbed — not returned by /api/friends.
// 4. Challenge participantCount and creatorName are stubbed — not in list
//    response.
// 5. Feed type enum is lossy — server's achievement/milestone/text all collapse
//    to client's "milestone".
