package com.foodsense.android.data

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [FoodLogEntity::class, UserStatsEntity::class, ChatMessageEntity::class, MealPlanEntity::class],
    version = 2,
    exportSchema = false,
)
abstract class FoodSenseDatabase : RoomDatabase() {
    abstract fun foodLogDao(): FoodLogDao
    abstract fun userStatsDao(): UserStatsDao
    abstract fun chatMessageDao(): ChatMessageDao
    abstract fun mealPlanDao(): MealPlanDao

    companion object {
        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL(
                    """CREATE TABLE IF NOT EXISTS chat_messages (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        sessionId TEXT NOT NULL,
                        role TEXT NOT NULL,
                        content TEXT NOT NULL,
                        timestamp INTEGER NOT NULL
                    )"""
                )
                database.execSQL(
                    """CREATE TABLE IF NOT EXISTS meal_plans (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        weekStart TEXT NOT NULL,
                        planJson TEXT NOT NULL,
                        createdAt INTEGER NOT NULL
                    )"""
                )
            }
        }
    }
}
