package com.foodsense.android.services

import android.graphics.Bitmap
import com.foodsense.android.data.NutritionInfo
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume

class BarcodeScanner {

    private val options = BarcodeScannerOptions.Builder()
        .setBarcodeFormats(Barcode.FORMAT_EAN_13, Barcode.FORMAT_UPC_A)
        .build()

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    suspend fun scanBarcode(bitmap: Bitmap): String? {
        val image = InputImage.fromBitmap(bitmap, 0)
        val scanner = BarcodeScanning.getClient(options)

        return suspendCancellableCoroutine { continuation ->
            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    val barcode = barcodes.firstOrNull {
                        it.format == Barcode.FORMAT_EAN_13 || it.format == Barcode.FORMAT_UPC_A
                    }
                    continuation.resume(barcode?.rawValue)
                }
                .addOnFailureListener {
                    continuation.resume(null)
                }
                .addOnCompleteListener {
                    scanner.close()
                }

            continuation.invokeOnCancellation {
                scanner.close()
            }
        }
    }

    suspend fun lookupBarcode(code: String): Pair<String, NutritionInfo>? = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url("https://world.openfoodfacts.org/api/v0/product/$code.json")
            .get()
            .build()

        val response = runCatching {
            client.newCall(request).execute()
        }.getOrNull() ?: return@withContext null

        val body = response.body?.string() ?: return@withContext null
        if (!response.isSuccessful) return@withContext null

        val root = runCatching {
            json.parseToJsonElement(body).jsonObject
        }.getOrNull() ?: return@withContext null

        val status = root["status"]?.jsonPrimitive?.intOrNull
        if (status != 1) return@withContext null

        val product = root["product"]?.jsonObject ?: return@withContext null
        val productName = product["product_name"]?.jsonPrimitive?.contentOrNull ?: "Unknown Product"

        val nutriments = product["nutriments"]?.jsonObject ?: return@withContext null

        val calories = nutrimentValue(nutriments, "energy-kcal_100g")
        val carbs = nutrimentValue(nutriments, "carbohydrates_100g")
        val protein = nutrimentValue(nutriments, "proteins_100g")
        val fat = nutrimentValue(nutriments, "fat_100g")

        val info = NutritionInfo(
            calories = calories,
            recipe = "Scanned from barcode. Consider pairing with vegetables for a balanced meal.",
            carbs = carbs,
            protein = protein,
            fats = fat,
            source = "Open Food Facts",
            micros = null,
        )

        productName to info
    }

    private fun nutrimentValue(nutriments: JsonObject, key: String): String {
        val element = nutriments[key] ?: return "0"
        val primitive = element.jsonPrimitive
        primitive.doubleOrNull?.let { return String.format("%.1f", it) }
        primitive.intOrNull?.let { return it.toString() }
        primitive.contentOrNull?.let { return it }
        return "0"
    }
}
