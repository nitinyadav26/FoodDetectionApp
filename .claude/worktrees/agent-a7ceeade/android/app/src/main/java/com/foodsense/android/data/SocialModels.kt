package com.foodsense.android.data

import kotlinx.serialization.Serializable

@Serializable
data class Friend(
    val id: String = "",
    val displayName: String = "",
    val avatarUrl: String = "",
    val streak: Int = 0,
    val todayCalories: Int = 0,
    val isOnline: Boolean = false,
)

@Serializable
data class FriendRequest(
    val id: String = "",
    val fromUserId: String = "",
    val fromDisplayName: String = "",
    val fromAvatarUrl: String = "",
    val timestamp: Long = 0L,
    val status: String = "pending", // pending, accepted, rejected
)

@Serializable
data class FeedPost(
    val id: String = "",
    val userId: String = "",
    val displayName: String = "",
    val avatarUrl: String = "",
    val type: String = "meal", // meal, milestone, challenge_complete, streak
    val title: String = "",
    val description: String = "",
    val imageUrl: String = "",
    val calories: Int = 0,
    val timestamp: Long = 0L,
    val reactions: Map<String, Int> = emptyMap(), // emoji -> count
    val myReaction: String? = null,
)

@Serializable
data class Challenge(
    val id: String = "",
    val title: String = "",
    val description: String = "",
    val type: String = "calories", // calories, protein, streak, steps
    val targetValue: Int = 0,
    val currentValue: Int = 0,
    val startDate: Long = 0L,
    val endDate: Long = 0L,
    val creatorId: String = "",
    val creatorName: String = "",
    val participantCount: Int = 0,
    val status: String = "available", // available, active, completed
    val isJoined: Boolean = false,
)

@Serializable
data class LeaderboardEntry(
    val rank: Int = 0,
    val userId: String = "",
    val displayName: String = "",
    val avatarUrl: String = "",
    val score: Int = 0,
    val streak: Int = 0,
    val isCurrentUser: Boolean = false,
)
