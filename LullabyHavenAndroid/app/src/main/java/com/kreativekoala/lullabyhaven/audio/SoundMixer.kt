package com.kreativekoala.lullabyhaven.audio

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import androidx.core.content.ContextCompat
import com.kreativekoala.lullabyhaven.player.SoundService
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/** Pure mixer model (unit tested). Levels are 0..1; absent or 0 means the layer is off. */
data class MixerState(
    val levels: Map<SoundKind, Float> = emptyMap(),
    val paused: Boolean = true,
    val masterGain: Float = 1f
) {
    val activeKinds: Set<SoundKind> get() = levels.filterValues { it > 0f }.keys
    val isPlaying: Boolean get() = !paused && activeKinds.isNotEmpty()

    fun withLevel(kind: SoundKind, level: Float): MixerState {
        val clamped = level.coerceIn(0f, 1f)
        val next = if (clamped <= 0f) levels - kind else levels + (kind to clamped)
        return copy(levels = next)
    }

    /** Effective per-layer volume after master gain and ducking. */
    fun effective(kind: SoundKind, duck: Float = 1f): Float =
        ((levels[kind] ?: 0f) * masterGain * duck).coerceIn(0f, 1f)
}

/**
 * Mixes several looping synthesized layers with independent volumes. Playback is kept alive by
 * [SoundService] (foreground, mediaPlayback). Takes audio focus, and stops when another app or
 * the story narrator takes it.
 */
@Singleton
class SoundMixer @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val tracks = mutableMapOf<SoundKind, AudioTrack>()
    private val buffers = mutableMapOf<SoundKind, ShortArray>()
    private var focusRequest: AudioFocusRequest? = null
    private var duck = 1f

    private val _state = MutableStateFlow(MixerState())
    val state: StateFlow<MixerState> = _state.asStateFlow()

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_LOSS -> stop()
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> pauseTracks()
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> { duck = 0.3f; applyVolumes() }
            AudioManager.AUDIOFOCUS_GAIN -> { duck = 1f; applyVolumes(); if (_state.value.isPlaying) playTracks() }
        }
    }

    @Synchronized
    fun setLevel(kind: SoundKind, level: Float) {
        _state.value = _state.value.withLevel(kind, level)
        if (level <= 0f) {
            tracks.remove(kind)?.let { runCatching { it.stop() }; it.release() }
            if (_state.value.activeKinds.isEmpty()) stop()
            return
        }
        if (_state.value.paused) start()
        scope.launch { ensureTrack(kind) }
        applyVolumes()
    }

    @Synchronized
    fun start() {
        if (_state.value.activeKinds.isEmpty()) return
        if (!requestFocus()) return
        _state.value = _state.value.copy(paused = false)
        ContextCompat.startForegroundService(context, Intent(context, SoundService::class.java))
        scope.launch { _state.value.activeKinds.forEach { ensureTrack(it) } }
        playTracks()
    }

    @Synchronized
    fun stop() {
        pauseTracks()
        _state.value = _state.value.copy(paused = true)
        abandonFocus()
    }

    fun toggle() { if (_state.value.isPlaying) stop() else start() }

    @Synchronized
    fun setMasterGain(gain: Float) {
        _state.value = _state.value.copy(masterGain = gain.coerceIn(0f, 1f))
        applyVolumes()
    }

    @Synchronized
    private fun ensureTrack(kind: SoundKind) {
        if (tracks.containsKey(kind)) return
        val pcm = buffers.getOrPut(kind) { SoundSynth.render(kind) }
        val bytes = pcm.size * 2
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SoundSynth.SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setBufferSizeInBytes(bytes)
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()
        track.write(pcm, 0, pcm.size)
        track.setLoopPoints(0, pcm.size, -1)
        track.setVolume(_state.value.effective(kind, duck))
        tracks[kind] = track
        if (_state.value.isPlaying) track.play()
    }

    @Synchronized
    private fun playTracks() { tracks.values.forEach { runCatching { it.play() } } }

    @Synchronized
    private fun pauseTracks() { tracks.values.forEach { runCatching { it.pause() } } }

    @Synchronized
    private fun applyVolumes() {
        val s = _state.value
        tracks.forEach { (kind, t) -> t.setVolume(s.effective(kind, duck)) }
    }

    private fun requestFocus(): Boolean {
        val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setOnAudioFocusChangeListener(focusListener)
            .build()
        focusRequest = req
        return audioManager.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun abandonFocus() {
        focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        focusRequest = null
    }
}
