package com.foodsense.android.services.ai

import com.foodsense.android.data.NutritionInfo
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

object AIResponseParser {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    // -- Cloud (Gemini envelope) parsers --

    // Unwraps candidates[0].content.parts[0].text, strips markdown fences, decodes
    // NutritionInfo. Returns the dish name and parsed nutrition data.
    fun parseNutritionFromGeminiEnvelope(raw: String): Pair<String, NutritionInfo> {
        val payloadText = extractCandidateText(raw)
        val cleanContent = cleanJsonText(payloadText)
        val parsedElement = json.parseToJsonElement(cleanContent)
        val dish = (parsedElement as? JsonObject)
            ?.get("Dish")
            ?.jsonPrimitive
            ?.contentOrNull
            ?: "AI Detected Food"
        val info = json.decodeFromJsonElement<NutritionInfo>(parsedElement)
        return dish to info
    }

    // Unwraps candidates text for text-only responses. Handles finishReason
    // (SAFETY, RECITATION, MAX_TOKENS).
    fun parseTextFromGeminiEnvelope(raw: String): String {
        val root = json.parseToJsonElement(raw).jsonObject
        val candidates = root["candidates"] as? JsonArray
            ?: return "Coach Error: No response candidates."
        val first = candidates.firstOrNull()?.jsonObject
            ?: return "Coach Error: Empty response."
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

    // -- Local (raw text) parsers --

    // Extracts JSON between first '{' and last '}', strips markdown, decodes
    // NutritionInfo. Used for on-device model output that is not wrapped in a
    // Gemini envelope.
    fun parseNutritionFromRawText(text: String): Pair<String, NutritionInfo> {
        val cleaned = cleanJsonText(text)
        val jsonStr = extractJsonBlock(cleaned, '{', '}')
        val parsedElement = json.parseToJsonElement(jsonStr)
        val dish = (parsedElement as? JsonObject)
            ?.get("Dish")
            ?.jsonPrimitive
            ?.contentOrNull
            ?: "AI Detected Food"
        val info = json.decodeFromJsonElement<NutritionInfo>(parsedElement)
        return dish to info
    }

    // For local text-only responses, simply trims whitespace.
    fun parseTextFromRawText(text: String): String {
        return text.trim()
    }

    // -- Shared helpers --

    // Unwraps the Gemini REST envelope: candidates[0].content.parts[0].text
    fun extractCandidateText(raw: String): String {
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

    // Strips markdown code fences and trims whitespace.
    fun cleanJsonText(text: String): String {
        return text
            .replace("```json", "")
            .replace("```", "")
            .trim()
    }

    // Locates the outermost JSON block delimited by the given open/close chars
    // (e.g. '{' / '}' or '[' / ']') and returns only that substring.
    private fun extractJsonBlock(text: String, open: Char, close: Char): String {
        val start = text.indexOf(open)
        val end = text.lastIndexOf(close)
        if (start == -1 || end == -1 || end <= start) {
            throw IllegalStateException("No JSON block found in response")
        }
        return text.substring(start, end + 1)
    }
}
