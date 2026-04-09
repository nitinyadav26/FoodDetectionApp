package com.foodsense.android.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface FoodLogDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(log: FoodLogEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(logs: List<FoodLogEntity>)

    @Delete
    fun delete(log: FoodLogEntity)

    @Query("DELETE FROM food_logs WHERE id IN (:ids)")
    fun deleteByIds(ids: List<String>)

    @Query("SELECT * FROM food_logs ORDER BY timeEpochMillis DESC")
    fun getAll(): List<FoodLogEntity>

    @Query("SELECT * FROM food_logs WHERE timeEpochMillis >= :startMillis ORDER BY timeEpochMillis DESC")
    fun getLogsAfter(startMillis: Long): List<FoodLogEntity>

    @Query("DELETE FROM food_logs")
    fun deleteAll()
}
