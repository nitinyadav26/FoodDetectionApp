package com.foodsense.android.services

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

// SyncManager placeholder for Firestore cloud sync.
// Requires: firebase-firestore-ktx dependency and a configured Firebase project.
// Once Firestore is added, this will sync food logs and user stats across devices.

class SyncManager {
    var isSyncing by mutableStateOf(false)
        private set
    var lastSyncTimeMillis by mutableStateOf(0L)
        private set

    // TODO: Implement when Firestore dependency is added
    // - Upload logs to users/{uid}/foodLogs collection
    // - Upload stats to users/{uid}/userStats document
    // - Listen for remote changes and merge with local data
    // - Handle conflict resolution (last-write-wins)

    fun syncIfNeeded() {
        // Will be implemented with Firestore integration
    }
}
