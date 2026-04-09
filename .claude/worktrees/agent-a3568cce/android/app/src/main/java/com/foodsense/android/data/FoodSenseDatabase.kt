package com.foodsense.android.data

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [FoodLogEntity::class, UserStatsEntity::class, XPEntity::class, BadgeEntity::class],
    version = 2,
    exportSchema = false,
)
abstract class FoodSenseDatabase : RoomDatabase() {
    abstract fun foodLogDao(): FoodLogDao
    abstract fun userStatsDao(): UserStatsDao
    abstract fun xpDao(): XPDao
    abstract fun badgeDao(): BadgeDao

    companion object {
        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL(
                    """CREATE TABLE IF NOT EXISTS `user_xp` (
                        `id` INTEGER NOT NULL PRIMARY KEY,
                        `totalXP` INTEGER NOT NULL DEFAULT 0,
                        `level` INTEGER NOT NULL DEFAULT 1,
                        `title` TEXT NOT NULL DEFAULT 'Beginner',
                        `lastUpdated` INTEGER NOT NULL DEFAULT 0
                    )""",
                )
                database.execSQL(
                    """CREATE TABLE IF NOT EXISTS `user_badges` (
                        `badgeKey` TEXT NOT NULL PRIMARY KEY,
                        `unlockedAt` INTEGER NOT NULL DEFAULT 0,
                        `category` TEXT NOT NULL DEFAULT ''
                    )""",
                )
            }
        }
    }
}
