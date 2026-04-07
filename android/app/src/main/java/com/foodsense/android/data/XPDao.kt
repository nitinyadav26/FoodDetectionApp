package com.foodsense.android.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface XPDao {
    @Query("SELECT * FROM user_xp WHERE id = 1")
    fun get(): XPEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertOrUpdate(xp: XPEntity)
}
