package com.foodsense.android.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [FoodLogEntity::class, UserStatsEntity::class], version = 1, exportSchema = false)
abstract class FoodSenseDatabase : RoomDatabase() {
    abstract fun foodLogDao(): FoodLogDao
    abstract fun userStatsDao(): UserStatsDao
}
