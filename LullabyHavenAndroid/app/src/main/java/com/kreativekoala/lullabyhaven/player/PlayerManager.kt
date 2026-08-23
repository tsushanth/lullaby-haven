package com.kreativekoala.lullabyhaven.player

import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

data class PlaybackState(
    val isPlaying: Boolean = false,
    val currentStoryId: String? = null,
    val positionMs: Long = 0L,
    val durationMs: Long = 0L
)

/**
 * Real ExoPlayer-backed playback controller, shared across the story player and mixer/sound
 * screens (Views/BedtimeStories/StoryPlayerView.swift + Views/SoundPlayerView.swift on iOS).
 *
 * The transport itself (play/pause/seek/duration/position) is fully functional. What's stubbed
 * is the *source*: narrated-story audio comes from the TTS job backend (POST /api/tts/job-cloned,
 * then poll GET /api/tts/job/{id} for the resulting audio_url) which isn't wired up yet -- see
 * StoryPlayerViewModel TODO. Call [play] with any playable URI (including a bundled raw resource)
 * to exercise the transport today.
 */
@Singleton
class PlayerManager @Inject constructor(
    @ApplicationContext context: Context
) {
    val player: ExoPlayer = ExoPlayer.Builder(context).build()

    private val _state = MutableStateFlow(PlaybackState())
    val state: StateFlow<PlaybackState> = _state.asStateFlow()

    init {
        player.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                _state.value = _state.value.copy(isPlaying = isPlaying)
            }

            override fun onEvents(p: Player, events: Player.Events) {
                _state.value = _state.value.copy(
                    positionMs = p.currentPosition.coerceAtLeast(0L),
                    durationMs = p.duration.coerceAtLeast(0L)
                )
            }
        })
    }

    fun play(storyId: String, uri: String) {
        if (_state.value.currentStoryId != storyId) {
            player.setMediaItem(MediaItem.fromUri(uri))
            player.prepare()
            _state.value = _state.value.copy(currentStoryId = storyId)
        }
        player.play()
    }

    fun pause() = player.pause()

    fun togglePlayPause() {
        if (player.isPlaying) player.pause() else player.play()
    }

    fun seekTo(positionMs: Long) = player.seekTo(positionMs)

    fun stop() {
        player.stop()
        _state.value = PlaybackState()
    }
}
