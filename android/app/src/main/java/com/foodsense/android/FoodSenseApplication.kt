package com.foodsense.android

import android.app.Application
import androidx.room.Room
import com.foodsense.android.data.FoodSenseDatabase
import com.foodsense.android.services.APIService
import com.foodsense.android.services.AuthManager
import com.foodsense.android.services.BluetoothScaleManager
import com.foodsense.android.services.FoodDatabase
import com.foodsense.android.services.HealthDataManager
import com.foodsense.android.services.LocalModelDetector
import com.foodsense.android.services.NetworkMonitor
import com.foodsense.android.services.NutritionManager
import com.foodsense.android.services.StreakManager

class FoodSenseApplication : Application() {
    val database: FoodSenseDatabase by lazy {
        Room.databaseBuilder(this, FoodSenseDatabase::class.java, "foodsense-db").build()
    }

    val authManager: AuthManager by lazy { AuthManager() }
    val nutritionManager: NutritionManager by lazy { NutritionManager(this) }
    val foodDatabase: FoodDatabase by lazy { FoodDatabase(this) }
    val apiService: APIService by lazy { APIService() }
    val bluetoothScaleManager: BluetoothScaleManager by lazy { BluetoothScaleManager(this) }
    val healthDataManager: HealthDataManager by lazy { HealthDataManager(this) }
    val localModelDetector: LocalModelDetector by lazy { LocalModelDetector(this) }
    val networkMonitor: NetworkMonitor by lazy { NetworkMonitor(this) }
    val streakManager: StreakManager by lazy { StreakManager(this, nutritionManager) }

    override fun onCreate() {
        super.onCreate()
        nutritionManager
        foodDatabase
        apiService
        healthDataManager
        networkMonitor
    }
}
