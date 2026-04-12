package com.foodsense.android.services.ai

import android.content.Context
import androidx.compose.runtime.mutableStateOf
import com.foodsense.android.BuildConfig

// Selects the active AI provider using a 3-tier fallback:
//   1. User-provided Gemini API key (via EncryptedSharedPreferences)
//   2. On-device Gemma 4 E4B model (if downloaded)
//   3. Legacy BuildConfig key or proxy URL
//   4. NO_PROVIDER if nothing is available
class AIProviderManager(private val context: Context) {

    companion object {
        var instance: AIProviderManager? = null
            private set
    }

    enum class ProviderState {
        CLOUD_READY, LOCAL_READY, DOWNLOADING, NO_PROVIDER
    }

    val state = mutableStateOf(ProviderState.NO_PROVIDER)
    var activeProvider: AIProvider? = null
        private set

    val apiKeyManager by lazy { APIKeyManager(context) }
    val modelDownloadManager by lazy { ModelDownloadManager(context) }

    fun initialize() {
        instance = this

        // Tier 1: User-provided API key
        val userKey = apiKeyManager.getApiKey()
        if (!userKey.isNullOrBlank()) {
            activeProvider = GeminiCloudProvider(apiKey = userKey, proxyBaseUrl = null)
            state.value = ProviderState.CLOUD_READY
            return
        }

        // Tier 2: On-device Gemma model
        if (modelDownloadManager.isModelAvailable.value) {
            activeProvider = GemmaLocalProvider(modelPath = modelDownloadManager.modelPath)
            state.value = ProviderState.LOCAL_READY
            return
        }

        // Tier 3: Legacy BuildConfig key
        val legacyKey = try { BuildConfig.GEMINI_API_KEY } catch (_: Exception) { "" }
        if (legacyKey.isNotBlank()) {
            activeProvider = GeminiCloudProvider(apiKey = legacyKey, proxyBaseUrl = null)
            state.value = ProviderState.CLOUD_READY
            return
        }

        // Tier 4: Legacy proxy URL
        val proxyUrl = try { BuildConfig.PROXY_BASE_URL } catch (_: Exception) { "" }
        if (proxyUrl.isNotBlank()) {
            activeProvider = GeminiCloudProvider(apiKey = null, proxyBaseUrl = proxyUrl)
            state.value = ProviderState.CLOUD_READY
            return
        }

        // No provider available
        state.value = ProviderState.NO_PROVIDER
    }

    // Called after user validates and saves a new API key
    fun setApiKey(key: String) {
        apiKeyManager.saveApiKey(key)
        activeProvider = GeminiCloudProvider(apiKey = key, proxyBaseUrl = null)
        state.value = ProviderState.CLOUD_READY
    }

    // Removes the user key and re-initializes to pick up the next available tier
    fun clearApiKey() {
        apiKeyManager.deleteApiKey()
        initialize()
    }

    // Downloads the on-device model and switches to it when complete
    suspend fun startModelDownload() {
        state.value = ProviderState.DOWNLOADING
        modelDownloadManager.startDownload()
        if (modelDownloadManager.isModelAvailable.value) {
            activeProvider = GemmaLocalProvider(modelPath = modelDownloadManager.modelPath)
            state.value = ProviderState.LOCAL_READY
        } else {
            // Download failed -- fall back to whatever was available
            initialize()
        }
    }

    // Deletes the on-device model and re-initializes
    fun deleteLocalModel() {
        modelDownloadManager.deleteModel()
        initialize()
    }
}
