package com.foodsense.android.services

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.foodsense.android.data.INDBFood
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

class FoodDatabase(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    var foods by mutableStateOf<List<INDBFood>>(emptyList())
        private set

    var isLoaded by mutableStateOf(false)
        private set

    suspend fun loadData() {
        runCatching {
            val raw = context.assets.open("indb_foods.json").bufferedReader().use { it.readText() }
            foods = json.decodeFromString(ListSerializer(INDBFood.serializer()), raw)
            isLoaded = true
        }
    }

    fun search(query: String): List<INDBFood> {
        if (query.isBlank()) return emptyList()
        return foods.filter { it.name.contains(query, ignoreCase = true) }
    }
}
