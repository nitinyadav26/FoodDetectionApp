package com.foodsense.android.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface UserStatsDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertOrUpdate(stats: UserStatsEntity)

    @Query("SELECT * FROM user_stats WHERE id = 1")
    fun get(): UserStatsEntity?

    @Query("DELETE FROM user_stats")
    fun deleteAll()
}
