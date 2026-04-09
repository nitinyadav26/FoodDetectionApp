package com.foodsense.android

import com.foodsense.android.data.NutritionInfo
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for parsing Gemini API responses.
 *
 * Mirrors the parsing logic in APIService without needing network or OkHttp.
 */
class APIResponseParsingTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    // ---------------------------------------------------------------------------
    // Helpers that replicate the private APIService parsing methods
    // ---------------------------------------------------------------------------

    /** Extract the text from a Gemini candidates response (same as APIService.extractCandidateText). */
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

    /** Parse a Gemini nutrition JSON response (same as APIService.parseJsonNutritionResponse). */
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

    /** Parse a Gemini coach text response (same as APIService.parseTextResponse). */
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

    /** Build a Gemini-style JSON response string wrapping text. */
    private fun geminiResponse(text: String, finishReason: String = "STOP"): String {
        // Escape the text for embedding in JSON
        val escaped = text
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")

        return """
        {
            "candidates": [{
                "content": {
                    "parts": [{"text": "$escaped"}]
                },
                "finishReason": "$finishReason"
            }]
        }
        """.trimIndent()
    }

    // ===== Nutrition Response Parsing =====

    /**
     * A well-formed Gemini nutrition response should parse dish name and all fields.
     */
    @Test
    fun testParseNutritionResponse() {
        val nutritionPayload = """
        {
            "Dish": "Grilled Chicken",
            "Calories per 100g": "165",
            "Carbohydrate per 100g": "0",
            "Protein per 100 gm": "31",
            "Fats per 100 gm": "3.6",
            "Healthier Recipe": "Use less oil",
            "Source": "AI Analysis",
            "micros": {"Iron": "1.3 mg", "Vitamin B6": "0.5 mg"}
        }
        """.trimIndent()

        val raw = geminiResponse(nutritionPayload)
        val (dish, info) = parseJsonNutritionResponse(raw)

        assertEquals("Grilled Chicken", dish)
        assertEquals("165", info.calories)
        assertEquals("0", info.carbs)
        assertEquals("31", info.protein)
        assertEquals("3.6", info.fats)
        assertEquals("Use less oil", info.recipe)
        assertEquals("AI Analysis", info.source)
        assertNotNull(info.micros)
        assertEquals("1.3 mg", info.micros?.get("Iron"))
        assertEquals("0.5 mg", info.micros?.get("Vitamin B6"))
    }

    /**
     * Coach text response should extract the advice text.
     */
    @Test
    fun testParseCoachResponse() {
        val adviceText = "Great job today! You hit your protein goal. Consider adding more vegetables."
        val raw = geminiResponse(adviceText)
        val result = parseTextResponse(raw)

        assertEquals(adviceText, result)
    }

    /**
     * When the nutrition JSON is missing the Dish key, fallback to "AI Detected Food".
     */
    @Test
    fun testParseNutritionResponseMissingDish() {
        val noDishPayload = """
        {
            "Calories per 100g": "300",
            "Carbohydrate per 100g": "40",
            "Protein per 100 gm": "10",
            "Fats per 100 gm": "12",
            "Healthier Recipe": "Bake instead of fry",
            "Source": "AI Analysis"
        }
        """.trimIndent()

        val raw = geminiResponse(noDishPayload)
        val (dish, info) = parseJsonNutritionResponse(raw)

        assertEquals("AI Detected Food", dish)
        assertEquals("300", info.calories)
        assertEquals("40", info.carbs)
    }

    /**
     * Missing fields in NutritionInfo should use defaults ("0" for numbers, "No recipe available." etc.).
     */
    @Test
    fun testParseNutritionResponseMissingFields() {
        val partialPayload = """
        {
            "Calories per 100g": "200",
            "Healthier Recipe": "Add more greens"
        }
        """.trimIndent()

        val raw = geminiResponse(partialPayload)
        val (_, info) = parseJsonNutritionResponse(raw)

        assertEquals("200", info.calories)
        assertEquals("Add more greens", info.recipe)
        // Missing fields should use the data class defaults
        assertEquals("0", info.carbs)
        assertEquals("0", info.protein)
        assertEquals("0", info.fats)
        assertEquals("Unknown", info.source)
        assertNull(info.micros)
    }

    /**
     * NutritionInfo should deserialize correctly from JSON with all string fields.
     */
    @Test
    fun testParseNutritionInfoDecoding() {
        val fullJSON = """
        {
            "Calories per 100g": "250",
            "Healthier Recipe": "Steam instead of fry",
            "Carbohydrate per 100g": "30.5",
            "Protein per 100 gm": "15",
            "Fats per 100 gm": "8.2",
            "Source": "Database",
            "micros": {"Calcium": "50 mg"}
        }
        """.trimIndent()

        val info = json.decodeFromString(NutritionInfo.serializer(), fullJSON)

        assertEquals("250", info.calories)
        assertEquals("Steam instead of fry", info.recipe)
        assertEquals("30.5", info.carbs)
        assertEquals("15", info.protein)
        assertEquals("8.2", info.fats)
        assertEquals("Database", info.source)
        assertNotNull(info.micros)
        assertEquals("50 mg", info.micros?.get("Calcium"))
    }

    // ===== Coach Response Edge Cases =====

    /**
     * MAX_TOKENS finishReason should append [Truncated].
     */
    @Test
    fun testParseCoachResponseTruncated() {
        val raw = geminiResponse("Partial advice...", finishReason = "MAX_TOKENS")
        val result = parseTextResponse(raw)

        assertTrue("Should contain Truncated marker", result.contains("[Truncated]"))
        assertTrue("Should contain original text", result.contains("Partial advice..."))
    }

    /**
     * SAFETY finishReason should return the safety message.
     */
    @Test
    fun testParseCoachResponseSafety() {
        val raw = """
        {
            "candidates": [{
                "finishReason": "SAFETY"
            }]
        }
        """.trimIndent()

        val result = parseTextResponse(raw)
        assertEquals("Coach stopped due to safety filters.", result)
    }

    /**
     * RECITATION finishReason should also return the safety message.
     */
    @Test
    fun testParseCoachResponseRecitation() {
        val raw = """
        {
            "candidates": [{
                "finishReason": "RECITATION"
            }]
        }
        """.trimIndent()

        val result = parseTextResponse(raw)
        assertEquals("Coach stopped due to safety filters.", result)
    }

    /**
     * Missing candidates array should return error message.
     */
    @Test
    fun testParseCoachResponseNoCandidates() {
        val raw = """{"error": "something went wrong"}"""
        val result = parseTextResponse(raw)
        assertEquals("Coach Error: No response candidates.", result)
    }

    /**
     * Empty candidates array should return error message.
     */
    @Test
    fun testParseCoachResponseEmptyCandidates() {
        val raw = """{"candidates": []}"""
        val result = parseTextResponse(raw)
        assertEquals("Coach Error: Empty response.", result)
    }

    /**
     * Response with ```json fences should be stripped before parsing.
     */
    @Test
    fun testParseNutritionResponseWithCodeFences() {
        val fencedPayload = "```json\n{\"Dish\":\"Pasta\",\"Calories per 100g\":\"131\",\"Carbohydrate per 100g\":\"25\",\"Protein per 100 gm\":\"5\",\"Fats per 100 gm\":\"1.1\",\"Healthier Recipe\":\"Use whole wheat\",\"Source\":\"AI\"}\n```"
        val raw = geminiResponse(fencedPayload)
        val (dish, info) = parseJsonNutritionResponse(raw)

        assertEquals("Pasta", dish)
        assertEquals("131", info.calories)
        assertEquals("25", info.carbs)
        assertEquals("5", info.protein)
    }
}
