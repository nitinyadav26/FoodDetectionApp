package com.foodsense.android.services.ai

import android.graphics.Bitmap
import android.util.Base64
import com.foodsense.android.data.FoodLog
import com.foodsense.android.data.MealPlanDay
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.QuizQuestion
import com.foodsense.android.data.UserStats
import com.foodsense.android.data.WeeklyInsight
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit

// Implements AIProvider by making HTTP calls to the Gemini REST API (or a proxy).
// Extracted from APIService to allow swapping between cloud and local providers.
class GeminiCloudProvider(
    private val apiKey: String?,
    private val proxyBaseUrl: String?
) : AIProvider {

    override val providerName = "Gemini Cloud"

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .build()

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    private val modelName = "gemini-flash-latest"

    // Rate limiting: 100 requests per day, minimum 1 second between requests
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

    // -- AIProvider methods --

    override suspend fun analyzeFood(image: Bitmap): Pair<String, NutritionInfo> =
        withContext(Dispatchers.IO) {
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
                val promptText = PromptTemplates.analyzeFoodPrompt(forLocal = false)
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

            AIResponseParser.parseNutritionFromGeminiEnvelope(raw)
        }

    override suspend fun searchFood(query: String): Pair<String, NutritionInfo> =
        withContext(Dispatchers.IO) {
            checkRateLimit()

            val raw = if (!proxyBaseUrl.isNullOrBlank()) {
                val body = buildJsonObject {
                    put("query", JsonPrimitive(query))
                }
                postJSON("$proxyBaseUrl/api/v1/search-food", body)
            } else {
                val promptText = PromptTemplates.searchFoodPrompt(query, forLocal = false)
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

            AIResponseParser.parseNutritionFromGeminiEnvelope(raw)
        }

    override suspend fun getCoachAdvice(
        userStats: UserStats?,
        logs: List<FoodLog>,
        healthData: String,
        historyToon: String,
        userQuery: String
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
            val fullPrompt = PromptTemplates.coachFullPrompt(context, userQuery)
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

        AIResponseParser.parseTextFromGeminiEnvelope(raw)
    }

    override suspend fun generateMealPlan(
        userStats: UserStats?,
        calorieBudget: Int
    ): List<MealPlanDay> = withContext(Dispatchers.IO) {
        checkRateLimit()
        requireApiKey()

        val context = buildString {
            append("Calorie budget: $calorieBudget kcal/day. ")
            if (userStats != null) {
                append("User: Age ${userStats.age}, ${userStats.gender}, ${userStats.weight}kg, Goal: ${userStats.goal}.")
            }
        }

        val promptText = PromptTemplates.mealPlanPrompt(context, forLocal = false)
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
                put("maxOutputTokens", JsonPrimitive(4000))
            })
        }
        val raw = postGemini(body)
        val text = AIResponseParser.cleanJsonText(
            AIResponseParser.extractCandidateText(raw)
        )
        json.decodeFromString<List<MealPlanDay>>(text)
    }

    override suspend fun getWeeklyInsights(
        userStats: UserStats?,
        history: String,
        healthData: String
    ): WeeklyInsight = withContext(Dispatchers.IO) {
        checkRateLimit()
        requireApiKey()

        val context = buildString {
            if (userStats != null) {
                append("User: Age ${userStats.age}, ${userStats.gender}, ${userStats.weight}kg, Goal: ${userStats.goal}. ")
            }
            append("Health: $healthData. ")
            append("Food history:\n$history")
        }

        val promptText = PromptTemplates.weeklyInsightsPrompt(context, forLocal = false)
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
        val raw = postGemini(body)
        val text = AIResponseParser.cleanJsonText(
            AIResponseParser.extractCandidateText(raw)
        )
        json.decodeFromString<WeeklyInsight>(text)
    }

    override suspend fun getQuizQuestion(): QuizQuestion = withContext(Dispatchers.IO) {
        checkRateLimit()
        requireApiKey()

        val promptText = PromptTemplates.quizQuestionPrompt(forLocal = false)
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
                put("temperature", JsonPrimitive(0.9))
            })
        }
        val raw = postGemini(body)
        val text = AIResponseParser.cleanJsonText(
            AIResponseParser.extractCandidateText(raw)
        )
        json.decodeFromString<QuizQuestion>(text)
    }

    override suspend fun predictWeight(
        userStats: UserStats?,
        history: String
    ): String = withContext(Dispatchers.IO) {
        checkRateLimit()
        requireApiKey()

        val context = buildString {
            if (userStats != null) {
                append("User: ${userStats.weight}kg, Goal: ${userStats.goal}. ")
            }
            append("Recent food history:\n$history")
        }

        val promptText = PromptTemplates.weightPredictionPrompt(context)
        val body = buildJsonObject {
            put("contents", buildJsonArray {
                add(buildJsonObject {
                    put("parts", buildJsonArray {
                        add(buildJsonObject { put("text", JsonPrimitive(promptText)) })
                    })
                })
            })
            put("generationConfig", buildJsonObject {
                put("maxOutputTokens", JsonPrimitive(500))
                put("temperature", JsonPrimitive(0.7))
            })
        }
        val raw = postGemini(body)
        AIResponseParser.parseTextFromGeminiEnvelope(raw)
    }

    // -- Helpers --

    private fun requireApiKey() {
        if (apiKey.isNullOrBlank()) {
            throw IllegalStateException(
                "This feature requires a direct Gemini API key. Set GEMINI_API_KEY in local.properties."
            )
        }
    }

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
        val key = apiKey
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
