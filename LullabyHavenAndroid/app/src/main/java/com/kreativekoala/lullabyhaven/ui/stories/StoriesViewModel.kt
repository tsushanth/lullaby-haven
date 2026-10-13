package com.kreativekoala.lullabyhaven.ui.stories

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kreativekoala.lullabyhaven.audio.SleepTimer
import com.kreativekoala.lullabyhaven.audio.SleepTimerState
import com.kreativekoala.lullabyhaven.data.repository.StoryNarrationRepository
import com.kreativekoala.lullabyhaven.data.repository.StoryRepository
import com.kreativekoala.lullabyhaven.domain.model.BedtimeStory
import com.kreativekoala.lullabyhaven.player.PlaybackState
import com.kreativekoala.lullabyhaven.player.PlayerManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class StoriesUiState(
    val stories: List<BedtimeStory> = emptyList(),
    val favoriteIds: Set<String> = emptySet()
)

@HiltViewModel
class StoriesViewModel @Inject constructor(
    private val storyRepository: StoryRepository
) : ViewModel() {

    val uiState: StateFlow<StoriesUiState> = storyRepository.observeFavoriteIds()
        .combine(MutableStateFlow(storyRepository.allStories())) { favIds, stories ->
            StoriesUiState(stories = stories, favoriteIds = favIds.toSet())
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), StoriesUiState())

    fun toggleFavorite(storyId: String, isFavorite: Boolean) {
        viewModelScope.launch { storyRepository.toggleFavorite(storyId, isFavorite) }
    }
}

enum class NarrationStatus { LOADING, READY, FAILED }

data class NarrationUiState(
    val status: NarrationStatus = NarrationStatus.LOADING,
    val errorMessage: String? = null
)

@HiltViewModel
class StoryPlayerViewModel @Inject constructor(
    private val storyRepository: StoryRepository,
    private val narrationRepository: StoryNarrationRepository,
    private val playerManager: PlayerManager,
    private val sleepTimer: SleepTimer
) : ViewModel() {

    val timerState: StateFlow<SleepTimerState> = sleepTimer.state
    fun startTimer(minutes: Int) = sleepTimer.start(minutes * 60_000L)
    fun cancelTimer() = sleepTimer.cancel()

    fun story(storyId: String): BedtimeStory? = storyRepository.story(storyId)

    val playbackState: StateFlow<PlaybackState> = playerManager.state

    private val _narrationState = MutableStateFlow(NarrationUiState())
    val narrationState: StateFlow<NarrationUiState> = _narrationState.asStateFlow()

    /**
     * Fetches real narrated audio from listenai-backend's synchronous TTS endpoint
     * (POST /api/tts, Kokoro self-hosted voice) and hands the resulting local file to
     * [PlayerManager]. On failure (network, quota, backend down, etc.) this surfaces an
     * honest "narration unavailable" state rather than faking success -- it does NOT fall
     * back to a placeholder tone.
     */
    fun playStory(storyId: String) {
        val story = storyRepository.story(storyId) ?: run {
            _narrationState.value = NarrationUiState(NarrationStatus.FAILED, "Story not found")
            return
        }

        _narrationState.value = NarrationUiState(NarrationStatus.LOADING)

        viewModelScope.launch {
            narrationRepository.narrationFor(storyId, story.body)
                .onSuccess { file ->
                    _narrationState.value = NarrationUiState(NarrationStatus.READY)
                    playerManager.play(storyId, file.toURI().toString(), story.title)
                }
                .onFailure { e ->
                    _narrationState.value = NarrationUiState(
                        NarrationStatus.FAILED,
                        e.message ?: "Narration is unavailable right now"
                    )
                }
        }
    }

    fun togglePlayPause() = playerManager.togglePlayPause()

    fun seekTo(positionMs: Long) = playerManager.seekTo(positionMs)

    override fun onCleared() {
        super.onCleared()
        playerManager.stop()
    }
}
