package com.foodsense.android.services.ai

import androidx.compose.runtime.mutableStateOf
import com.foodsense.android.BuildConfig

class AIProviderManager {

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

    fun initialize() {
        instance = this
        val legacyKey = try { BuildConfig.GEMINI_API_KEY } catch (_: Exception) { "" }
        val proxyUrl = try { BuildConfig.PROXY_BASE_URL } catch (_: Exception) { "" }

        if (legacyKey.isNotBlank()) {
            activeProvider = GeminiCloudProvider(apiKey = legacyKey, proxyBaseUrl = null)
            state.value = ProviderState.CLOUD_READY
        } else if (proxyUrl.isNotBlank()) {
            activeProvider = GeminiCloudProvider(apiKey = null, proxyBaseUrl = proxyUrl)
            state.value = ProviderState.CLOUD_READY
        } else {
            state.value = ProviderState.NO_PROVIDER
        }
    }
}
