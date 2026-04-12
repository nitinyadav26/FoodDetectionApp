package com.foodsense.android.services.ai

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

// Manages secure storage and validation of user-provided Gemini API keys.
// Keys are stored in EncryptedSharedPreferences so they never appear in plain text on disk.
class APIKeyManager(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        PREFS_FILE,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    fun saveApiKey(key: String) {
        prefs.edit().putString(KEY_NAME, key).apply()
    }

    fun getApiKey(): String? {
        return prefs.getString(KEY_NAME, null)
    }

    fun deleteApiKey() {
        prefs.edit().remove(KEY_NAME).apply()
    }

    // Validates an API key by making a lightweight GET request to the Gemini models
    // endpoint. Returns true if the API responds with HTTP 200.
    suspend fun validateApiKey(key: String): Boolean = withContext(Dispatchers.IO) {
        if (!isKeyFormatValid(key)) return@withContext false

        try {
            val request = Request.Builder()
                .url("https://generativelanguage.googleapis.com/v1beta/models?key=$key")
                .get()
                .build()

            client.newCall(request).execute().use { response ->
                response.isSuccessful
            }
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        private const val PREFS_FILE = "foodsense_ai_prefs"
        private const val KEY_NAME = "gemini_api_key"

        // Key must start with "AI" and be at least 30 characters long
        fun isKeyFormatValid(key: String): Boolean {
            return key.startsWith("AI") && key.length >= 30
        }
    }
}
