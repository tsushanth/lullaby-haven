package com.kreativekoala.lullabyhaven.data.repository

import com.kreativekoala.lullabyhaven.data.local.FavoriteStoryDao
import com.kreativekoala.lullabyhaven.data.local.FavoriteStoryEntity
import com.kreativekoala.lullabyhaven.domain.model.BedtimeStory
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Story catalog + favorites. The story text catalog is local for now (same 6 originals as
 * iOS BedtimeStory.allStories) -- TODO: call POST /api/stories/generate once we wire a
 * "generate a new story" flow like Views/BedtimeStories/CreateStoryView.swift on iOS.
 */
@Singleton
class StoryRepository @Inject constructor(
    private val favoriteStoryDao: FavoriteStoryDao
) {
    fun allStories(): List<BedtimeStory> = BedtimeStory.allStories

    fun story(id: String): BedtimeStory? = BedtimeStory.allStories.find { it.id == id }

    fun observeFavoriteIds(): Flow<List<String>> = favoriteStoryDao.observeFavoriteIds()

    suspend fun toggleFavorite(storyId: String, isFavorite: Boolean) {
        if (isFavorite) {
            favoriteStoryDao.insert(FavoriteStoryEntity(storyId, System.currentTimeMillis()))
        } else {
            favoriteStoryDao.deleteById(storyId)
        }
    }
}
