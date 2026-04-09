package com.foodsense.android.services

import android.graphics.Bitmap
import android.util.Base64
import com.foodsense.android.BuildConfig
import com.foodsense.android.data.FoodLog
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.UserStats
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit

class APIService {
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .build()

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    // In production, set PROXY_BASE_URL in gradle.properties to your Firebase Functions URL.
    // The proxy holds the Gemini key server-side so it never ships in the app.
    // For local development, set GEMINI_API_KEY in local.properties (git-ignored).
    private val proxyBaseUrl: String? = try { BuildConfig.PROXY_BASE_URL } catch (_: Exception) { null }
    private val directApiKey: String? = try { BuildConfig.GEMINI_API_KEY } catch (_: Exception) { null }
    private val modelName = "gemini-flash-latest"

    // Rate limiting
    private var lastRequestTime = 0L
    private var dailyRequestCount = 0
    private var dailyCountDate = ""

    private fun checkRateLimit() {
        val now = System.currentTimeMillis()
        val today = java.time.LocalDate.now().toString()

        if (today != dailyCountDate) {
            dailyRequestCount = 0
            dailyCountDate = today
        }

        if (now - lastRequestTime < 1000) {
            throw IllegalStateException("Please wait a moment between requests.")
        }

        if (dailyRequestCount >= 100) {
            throw IllegalStateException("Daily request limit reached. Try again tomorrow.")
        }

        dailyRequestCount++
        lastRequestTime = now
    }

    suspend fun analyzeFood(image: Bitmap): Pair<String, NutritionInfo> = withContext(Dispatchers.IO) {
        checkRateLimit()

        val baos = ByteArrayOutputStream()
        image.compress(Bitmap.CompressFormat.JPEG, 70, baos)
        val base64Image = Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)

        val raw = if (!proxyBaseUrl.isNullOrBlank()) {
            val body = buildJsonObject {
                put("image_base64", JsonPrimitive(base64Image))
            }
            postJSON("$proxyBaseUrl/api/v1/analyze-food", body)
        } else {
            val promptText = """
                Analyze this food image. Identify the dish.
                Return a JSON object with these exact keys:
                - "Dish": Name of the dish
                - "Calories per 100g": Estimated calories (number as string)
                - "Carbohydrate per 100g": Estimated carbs (number as string)
                - "Protein per 100 gm": Estimated protein (number as string)
                - "Fats per 100 gm": Estimated fats (number as string)
                - "Healthier Recipe": A short advice to make it healthier
                - "Source": "AI Analysis"
                - "micros": A dictionary of key micronutrients
                Return ONLY the JSON.
            """.trimIndent()

            val body = buildJsonObject {
                put("contents", buildJsonArray {
                    add(buildJsonObject {
                        put("parts", buildJsonArray {
                            add(buildJsonObject { put("text", JsonPrimitive(promptText)) })
                            add(buildJsonObject {
                                put("inline_data", buildJsonObject {
                                    put("mime_type", JsonPrimitive("image/jpeg"))
                                    put("data", JsonPrimitive(base64Image))
                                })
                            })
                        })
                    })
                })
                put("generationConfig", buildJsonObject {
                    put("responseMimeType", JsonPrimitive("application/json"))
                })
            }
            postGemini(body)
        }

        parseJsonNutritionResponse(raw)
    }

    suspend fun searchFood(query: String): Pair<String, NutritionInfo> = withContext(Dispatchers.IO) {
        checkRateLimit()

        val raw = if (!proxyBaseUrl.isNullOrBlank()) {
            val body = buildJsonObject {
                put("query", JsonPrimitive(query))
            }
            postJSON("$proxyBaseUrl/api/v1/search-food", body)
        } else {
            val promptText = """
                Analyze this food query: "$query".
                Return a JSON object with these exact keys:
                - "Dish": Name of the dish
                - "Calories per 100g": Estimated calories (number as string)
                - "Carbohydrate per 100g": Estimated carbs (number as string)
                - "Protein per 100 gm": Estimated protein (number as string)
                - "Fats per 100 gm": Estimated fats (number as string)
                - "Healthier Recipe": A short advice to make it healthier
                - "Source": "AI Analysis"
                - "micros": A dictionary of key micronutrients
                Return ONLY the JSON.
            """.trimIndent()

            val body = buildJsonObject {
                put("contents", buildJsonArray {
                    add(buildJsonObject {
                        put("parts", buildJsonArray {
                            add(buildJsonObject { put("text", JsonPrimitive(promptText)) })
                        })
                    })
                })
                put("generationConfig", buildJsonObject {
                    put("responseMimeType", JsonPrimitive("application/json"))
                })
            }
            postGemini(body)
        }

        parseJsonNutritionResponse(raw)
    }

    suspend fun getCoachAdvice(
        userStats: UserStats?,
        logs: List<FoodLog>,
        healthData: String,
        historyToon: String,
        userQuery: String,
    ): String = withContext(Dispatchers.IO) {
        checkRateLimit()

        val context = buildString {
            append("User Stats: ")
            if (userStats != null) {
                append("Age ${userStats.age}, ${userStats.gender}, ${userStats.weight}kg, Goal: ${userStats.goal}. ")
            } else {
                append("Goal: Stay healthy. ")
            }
            append("\nToday's Health: $healthData.")
            append("\nToday's Food: ")
            if (logs.isEmpty()) {
                append("Nothing logged yet.")
            } else {
                logs.take(10).forEach { append("${it.food} (${it.calories}kcal), ") }
            }
            append("\n\nPast 30 Days History (TOON Format):\n")
            append(historyToon)
        }

        val raw = if (!proxyBaseUrl.isNullOrBlank()) {
            val body = buildJsonObject {
                put("context", JsonPrimitive(context))
                put("query", JsonPrimitive(userQuery))
            }
            postJSON("$proxyBaseUrl/api/v1/coach-advice", body)
        } else {
            val systemPrompt = """
                You are a friendly and motivating professional health coach.
                You have access to the user's data for the last 30 days.
                Be concise (max 150 words).
            """.trimIndent()

            val fullPrompt = "System: $systemPrompt\n\nContext:\n$context\n\nUser Request: $userQuery"

            val body = buildJsonObject {
                put("contents", buildJsonArray {
                    add(buildJsonObject {
                        put("parts", buildJsonArray {
                            add(buildJsonObject { put("text", JsonPrimitive(fullPrompt)) })
                        })
                    })
                })
                put("generationConfig", buildJsonObject {
                    put("maxOutputTokens", JsonPrimitive(1000))
                    put("temperature", JsonPrimitive(0.7))
                })
            }
            postGemini(body)
        }

        parseTextResponse(raw)
    }

    // -- Response Parsers (unchanged — both proxy and direct return Gemini's JSON format) --

    private fun parseJsonNutritionResponse(raw: String): Pair<String, NutritionInfo> {
        val payloadText = extractCandidateText(raw)
        val cleanContent = payloadText
            .replace("```json", "")
            .replace("```", "")
            .trim()

        val parsedElement = json.parseToJsonElement(cleanContent)
        val dish = (parsedElement as? JsonObject)?.get("Dish")?.jsonPrimitive?.contentOrNull ?: "AI Detected Food"
        val info = json.decodeFromJsonElement<NutritionInfo>(parsedElement)
        return dish to info
    }

    private fun parseTextResponse(raw: String): String {
        val root = json.parseToJsonElement(raw).jsonObject
        val candidates = root["candidates"] as? JsonArray ?: return "Coach Error: No response candidates."
        val first = candidates.firstOrNull()?.jsonObject ?: return "Coach Error: Empty response."
        val text = first["content"]
            ?.jsonObject
            ?.get("parts")
            ?.jsonArray
            ?.firstOrNull()
            ?.jsonObject
            ?.get("text")
            ?.jsonPrimitive
            ?.contentOrNull

        val finishReason = first["finishReason"]?.jsonPrimitive?.contentOrNull

        if (finishReason == "SAFETY" || finishReason == "RECITATION") {
            return "Coach stopped due to safety filters."
        }
        if (finishReason == "MAX_TOKENS") {
            return "${text.orEmpty()} [Truncated]"
        }
        return text ?: "Coach Error: Response format unrecognized."
    }

    private fun extractCandidateText(raw: String): String {
        val root = json.parseToJsonElement(raw).jsonObject
        val candidates = root["candidates"] as? JsonArray
            ?: throw IllegalStateException("Response missing candidates")

        return candidates.firstOrNull()
            ?.jsonObject
            ?.get("content")
            ?.jsonObject
            ?.get("parts")
            ?.jsonArray
            ?.firstOrNull()
            ?.jsonObject
            ?.get("text")
            ?.jsonPrimitive
            ?.contentOrNull
            ?: throw IllegalStateException("Response missing text")
    }

    // -- HTTP Helpers --

    private fun postJSON(url: String, body: JsonObject): String {
        val requestBody = json.encodeToString(JsonObject.serializer(), body)
            .toRequestBody("application/json".toMediaType())

        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .build()

        return executeWithRetry(request)
    }

    private fun postGemini(body: JsonObject): String {
        val key = directApiKey
        if (key.isNullOrBlank()) {
            throw IllegalStateException("No API configuration. Set PROXY_BASE_URL or GEMINI_API_KEY.")
        }

        val requestBody = json.encodeToString(JsonObject.serializer(), body)
            .toRequestBody("application/json".toMediaType())

        val request = Request.Builder()
            .url("https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key")
            .post(requestBody)
            .build()

        return executeWithRetry(request)
    }

    private fun executeWithRetry(request: Request, maxRetries: Int = 3): String {
        var lastException: Exception? = null
        repeat(maxRetries) { attempt ->
            try {
                client.newCall(request).execute().use { response ->
                    val raw = response.body?.string().orEmpty()
                    if (response.isSuccessful) return raw
                    if (response.code >= 500 && attempt < maxRetries - 1) {
                        Thread.sleep((1000L * (1 shl attempt)))
                        return@use
                    }
                    throw IllegalStateException("API Error ${response.code}: ${raw.take(200)}")
                }
            } catch (e: Exception) {
                lastException = e
                if (attempt < maxRetries - 1) {
                    Thread.sleep((1000L * (1 shl attempt)))
                }
            }
        }
        throw lastException ?: IllegalStateException("Request failed after $maxRetries retries")
    }
}
