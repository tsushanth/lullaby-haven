package com.kreativekoala.lullabyhaven.player

import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.MoreExecutors
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
 * ExoPlayer-backed playback controller for narrated stories. It owns the single player
 * instance; [PlaybackService] only wraps it in a MediaSession and must never release it.
 *
 * Audio focus and "becoming noisy" (headphones unplugged) are handled by ExoPlayer itself.
 * Calling [play] also connects a MediaController to [PlaybackService], which binds the service
 * so Media3 can promote it to the foreground with a lock-screen / notification player.
 */
@Singleton
class PlayerManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    val player: ExoPlayer = ExoPlayer.Builder(context)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(C.USAGE_MEDIA)
                .setContentType(C.AUDIO_CONTENT_TYPE_SPEECH)
                .build(),
            /* handleAudioFocus = */ true
        )
        .setHandleAudioBecomingNoisy(true)
        .setWakeMode(C.WAKE_MODE_LOCAL)
        .build()

    private val _state = MutableStateFlow(PlaybackState())
    val state: StateFlow<PlaybackState> = _state.asStateFlow()

    private var controller: MediaController? = null
    private var masterGain = 1f

    private val handler = Handler(Looper.getMainLooper())
    private val ticker = object : Runnable {
        override fun run() {
            _state.value = _state.value.copy(
                positionMs = player.currentPosition.coerceAtLeast(0L),
                durationMs = player.duration.coerceAtLeast(0L)
            )
            if (player.isPlaying) handler.postDelayed(this, 500)
        }
    }

    init {
        player.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                _state.value = _state.value.copy(isPlaying = isPlaying)
                handler.removeCallbacks(ticker)
                if (isPlaying) handler.post(ticker)
            }

            override fun onEvents(p: Player, events: Player.Events) {
                _state.value = _state.value.copy(
                    positionMs = p.currentPosition.coerceAtLeast(0L),
                    durationMs = p.duration.coerceAtLeast(0L)
                )
            }
        })
    }

    private fun connectToService() {
        if (controller != null) return
        val token = SessionToken(context, ComponentName(context, PlaybackService::class.java))
        val future = MediaController.Builder(context, token).buildAsync()
        future.addListener({
            controller = runCatching { future.get() }.getOrNull()
        }, MoreExecutors.directExecutor())
    }

    fun play(storyId: String, uri: String, title: String? = null) {
        connectToService()
        if (_state.value.currentStoryId != storyId) {
            val item = MediaItem.Builder()
                .setUri(uri)
                .setMediaMetadata(
                    MediaMetadata.Builder().setTitle(title).setArtist("Lullaby Haven").build()
                )
                .build()
            player.setMediaItem(item)
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

    /** Master gain 0..1 used by the sleep timer fade-out. */
    fun setMasterGain(gain: Float) {
        masterGain = gain.coerceIn(0f, 1f)
        player.volume = masterGain
    }

    fun stop() {
        player.stop()
        player.clearMediaItems()
        player.volume = 1f
        _state.value = PlaybackState()
    }
}
