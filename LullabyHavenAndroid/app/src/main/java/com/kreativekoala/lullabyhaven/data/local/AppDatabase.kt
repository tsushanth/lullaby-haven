package com.kreativekoala.lullabyhaven.data.local

import androidx.room.Database
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.RoomDatabase

/** A lullaby the parent recorded themselves singing (Views/MyVoice/OwnLullabyRecordingView.swift on iOS). */
@Entity(tableName = "own_recordings")
data class OwnRecordingEntity(
    @PrimaryKey val id: String,
    val title: String,
    val filePath: String,
    val durationMs: Long,
    val createdAtEpochMs: Long
)

/** Favorited bedtime story ids, mirrors FavoritesView on iOS. */
@Entity(tableName = "favorite_stories")
data class FavoriteStoryEntity(
    @PrimaryKey val storyId: String,
    val savedAtEpochMs: Long
)

@Database(
    entities = [OwnRecordingEntity::class, FavoriteStoryEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun ownRecordingDao(): OwnRecordingDao
    abstract fun favoriteStoryDao(): FavoriteStoryDao
}
