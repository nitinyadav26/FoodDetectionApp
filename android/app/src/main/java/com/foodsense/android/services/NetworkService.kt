package com.foodsense.android.services

import com.foodsense.android.BuildConfig
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

class NetworkService {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    private val baseUrl: String = try {
        BuildConfig.SOCIAL_API_BASE_URL
    } catch (_: Exception) {
        ""
    }

    private suspend fun getAuthToken(): String? {
        return try {
            FirebaseAuth.getInstance().currentUser?.getIdToken(false)?.await()?.token
        } catch (_: Exception) {
            null
        }
    }

    suspend fun get(path: String): String = withContext(Dispatchers.IO) {
        val token = getAuthToken()
        val requestBuilder = Request.Builder()
            .url("$baseUrl$path")
            .get()

        if (token != null) {
            requestBuilder.addHeader("Authorization", "Bearer $token")
        }

        val response = client.newCall(requestBuilder.build()).execute()
        val body = response.body?.string().orEmpty()
        if (!response.isSuccessful) {
            throw IllegalStateException("GET $path failed (${response.code}): ${body.take(200)}")
        }
        body
    }

    suspend fun post(path: String, body: JsonObject): String = withContext(Dispatchers.IO) {
        val token = getAuthToken()
        val requestBody = json.encodeToString(JsonObject.serializer(), body)
            .toRequestBody("application/json".toMediaType())

        val requestBuilder = Request.Builder()
            .url("$baseUrl$path")
            .post(requestBody)

        if (token != null) {
            requestBuilder.addHeader("Authorization", "Bearer $token")
        }

        val response = client.newCall(requestBuilder.build()).execute()
        val responseBody = response.body?.string().orEmpty()
        if (!response.isSuccessful) {
            throw IllegalStateException("POST $path failed (${response.code}): ${responseBody.take(200)}")
        }
        responseBody
    }
}
