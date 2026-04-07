package com.foodsense.android.services

import androidx.compose.runtime.mutableStateOf
import com.foodsense.android.data.Challenge
import com.foodsense.android.data.FeedPost
import com.foodsense.android.data.Friend
import com.foodsense.android.data.FriendRequest
import com.foodsense.android.data.LeaderboardEntry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject

class SocialManager(private val networkService: NetworkService) {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    // Observable state
    val friends = mutableStateOf<List<Friend>>(emptyList())
    val friendRequests = mutableStateOf<List<FriendRequest>>(emptyList())
    val feedPosts = mutableStateOf<List<FeedPost>>(emptyList())
    val challenges = mutableStateOf<List<Challenge>>(emptyList())
    val leaderboard = mutableStateOf<List<LeaderboardEntry>>(emptyList())
    val isLoading = mutableStateOf(false)
    val errorMessage = mutableStateOf<String?>(null)
    val searchResults = mutableStateOf<List<Friend>>(emptyList())

    // Friends
    suspend fun loadFriends() {
        safeCall {
            val raw = networkService.get("/api/v1/social/friends")
            friends.value = json.decodeFromString(raw)
        }
    }

    suspend fun loadFriendRequests() {
        safeCall {
            val raw = networkService.get("/api/v1/social/friend-requests")
            friendRequests.value = json.decodeFromString(raw)
        }
    }

    suspend fun searchUsers(query: String) {
        safeCall {
            val raw = networkService.get("/api/v1/social/search?q=$query")
            searchResults.value = json.decodeFromString(raw)
        }
    }

    suspend fun sendFriendRequest(userId: String) {
        safeCall {
            val body = buildJsonObject { put("userId", JsonPrimitive(userId)) }
            networkService.post("/api/v1/social/friend-requests", body)
            loadFriendRequests()
        }
    }

    suspend fun acceptFriendRequest(requestId: String) {
        safeCall {
            val body = buildJsonObject { put("action", JsonPrimitive("accept")) }
            networkService.post("/api/v1/social/friend-requests/$requestId", body)
            loadFriendRequests()
            loadFriends()
        }
    }

    suspend fun rejectFriendRequest(requestId: String) {
        safeCall {
            val body = buildJsonObject { put("action", JsonPrimitive("reject")) }
            networkService.post("/api/v1/social/friend-requests/$requestId", body)
            loadFriendRequests()
        }
    }

    suspend fun removeFriend(friendId: String) {
        safeCall {
            val body = buildJsonObject { put("friendId", JsonPrimitive(friendId)) }
            networkService.post("/api/v1/social/friends/remove", body)
            loadFriends()
        }
    }

    // Feed
    suspend fun loadFeed() {
        safeCall {
            val raw = networkService.get("/api/v1/social/feed")
            feedPosts.value = json.decodeFromString(raw)
        }
    }

    suspend fun reactToPost(postId: String, emoji: String) {
        safeCall {
            val body = buildJsonObject {
                put("postId", JsonPrimitive(postId))
                put("emoji", JsonPrimitive(emoji))
            }
            networkService.post("/api/v1/social/feed/react", body)
            loadFeed()
        }
    }

    // Challenges
    suspend fun loadChallenges() {
        safeCall {
            val raw = networkService.get("/api/v1/social/challenges")
            challenges.value = json.decodeFromString(raw)
        }
    }

    suspend fun joinChallenge(challengeId: String) {
        safeCall {
            val body = buildJsonObject { put("challengeId", JsonPrimitive(challengeId)) }
            networkService.post("/api/v1/social/challenges/join", body)
            loadChallenges()
        }
    }

    suspend fun createChallenge(title: String, description: String, type: String, targetValue: Int, durationDays: Int) {
        safeCall {
            val body = buildJsonObject {
                put("title", JsonPrimitive(title))
                put("description", JsonPrimitive(description))
                put("type", JsonPrimitive(type))
                put("targetValue", JsonPrimitive(targetValue))
                put("durationDays", JsonPrimitive(durationDays))
            }
            networkService.post("/api/v1/social/challenges", body)
            loadChallenges()
        }
    }

    // Leaderboard
    suspend fun loadLeaderboard(scope: String = "weekly") {
        safeCall {
            val raw = networkService.get("/api/v1/social/leaderboard?scope=$scope")
            leaderboard.value = json.decodeFromString(raw)
        }
    }

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
