package com.foodsense.android.data

import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query

@Entity(tableName = "meal_plans")
data class MealPlanEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val weekStart: String,
    val planJson: String,
    val createdAt: Long = System.currentTimeMillis(),
)

@Dao
interface MealPlanDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(plan: MealPlanEntity)

    @Query("SELECT * FROM meal_plans ORDER BY createdAt DESC LIMIT 1")
    fun getLatest(): MealPlanEntity?

    @Query("SELECT * FROM meal_plans ORDER BY createdAt DESC")
    fun getAll(): List<MealPlanEntity>

    @Query("DELETE FROM meal_plans")
    fun deleteAll()
}
