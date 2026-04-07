package com.foodsense.android.services

import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.tasks.await

class AuthManager {
    private val auth: FirebaseAuth? = try {
        FirebaseAuth.getInstance()
    } catch (e: Exception) {
        Log.w("AuthManager", "Firebase Auth unavailable: ${e.message}")
        null
    }

    // If Firebase is unavailable, treat as signed in so user can use the app
    private val _isSignedIn = MutableStateFlow(auth?.currentUser != null || auth == null)
    val isSignedIn: StateFlow<Boolean> = _isSignedIn

    private val _currentUser = MutableStateFlow(auth?.currentUser)
    val currentUser: StateFlow<FirebaseUser?> = _currentUser

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    init {
        auth?.addAuthStateListener { firebaseAuth ->
            _currentUser.value = firebaseAuth.currentUser
            _isSignedIn.value = firebaseAuth.currentUser != null
        }
    }

    suspend fun signInAnonymously() {
        if (auth == null) {
            // Firebase not configured — skip auth and let user through
            _isSignedIn.value = true
            return
        }
        try {
            auth.signInAnonymously().await()
            _error.value = null
        } catch (e: Exception) {
            Log.w("AuthManager", "Anonymous sign-in failed: ${e.message}")
            _error.value = null
            // Let the user through anyway so the app is usable without Firebase
            _isSignedIn.value = true
        }
    }

    suspend fun signInWithEmail(email: String, password: String) {
        if (auth == null) {
            _error.value = "Authentication service unavailable. Set up Firebase to enable sign-in."
            return
        }
        try {
            auth.signInWithEmailAndPassword(email, password).await()
            _error.value = null
        } catch (e: Exception) {
            _error.value = e.localizedMessage ?: "Sign-in failed"
        }
    }

    suspend fun createAccount(email: String, password: String) {
        if (auth == null) {
            _error.value = "Authentication service unavailable. Set up Firebase to enable accounts."
            return
        }
        try {
            auth.createUserWithEmailAndPassword(email, password).await()
            _error.value = null
        } catch (e: Exception) {
            _error.value = e.localizedMessage ?: "Account creation failed"
        }
    }

    fun signOut() {
        auth?.signOut()
        if (auth == null) _isSignedIn.value = false
    }

    suspend fun deleteAccount() {
        try {
            auth?.currentUser?.delete()?.await()
        } catch (e: Exception) {
            Log.w("AuthManager", "Delete account failed: ${e.message}")
        }
    }
}
