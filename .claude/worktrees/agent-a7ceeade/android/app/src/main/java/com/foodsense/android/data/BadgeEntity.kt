package com.foodsense.android.data

import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query

@Entity(tableName = "user_badges")
data class BadgeEntity(
    @PrimaryKey
    val badgeKey: String,
    val unlockedAt: Long = System.currentTimeMillis(),
    val category: String,
)

@Dao
interface BadgeDao {
    @Query("SELECT * FROM user_badges")
    fun getAll(): List<BadgeEntity>

    @Query("SELECT * FROM user_badges WHERE badgeKey = :key")
    fun getByKey(key: String): BadgeEntity?

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    fun insert(badge: BadgeEntity)

    @Query("SELECT COUNT(*) FROM user_badges")
    fun count(): Int
}
