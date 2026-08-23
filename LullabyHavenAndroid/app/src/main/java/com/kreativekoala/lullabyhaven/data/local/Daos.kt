package com.kreativekoala.lullabyhaven.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface OwnRecordingDao {
    @Query("SELECT * FROM own_recordings ORDER BY createdAtEpochMs DESC")
    fun observeAll(): Flow<List<OwnRecordingEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: OwnRecordingEntity)

    @Delete
    suspend fun delete(entity: OwnRecordingEntity)
}

@Dao
interface FavoriteStoryDao {
    @Query("SELECT storyId FROM favorite_stories")
    fun observeFavoriteIds(): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: FavoriteStoryEntity)

    @Query("DELETE FROM favorite_stories WHERE storyId = :storyId")
    suspend fun deleteById(storyId: String)
}
