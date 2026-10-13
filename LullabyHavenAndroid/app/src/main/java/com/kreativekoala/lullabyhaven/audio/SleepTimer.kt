package com.kreativekoala.lullabyhaven.audio

import android.os.SystemClock
import com.kreativekoala.lullabyhaven.player.PlayerManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/** Pure timer maths, unit tested. */
object SleepTimerMath {
    const val MAX_FADE_MS = 60_000L

    /** Fade window: up to 60 s, but never more than a third of the whole timer. */
    fun fadeWindowMs(totalMs: Long): Long = minOf(MAX_FADE_MS, totalMs / 3).coerceAtLeast(0L)

    /**
     * Master gain 0..1. Full volume until the fade window starts, then a squared ramp to silence
     * (squared tracks perceived loudness better than linear).
     */
    fun gain(remainingMs: Long, fadeMs: Long): Float {
        if (fadeMs <= 0L || remainingMs >= fadeMs) return if (remainingMs <= 0L) 0f else 1f
        if (remainingMs <= 0L) return 0f
        val x = remainingMs.toFloat() / fadeMs.toFloat()
        return x * x
    }
}

data class SleepTimerState(
    val active: Boolean = false,
    val totalMs: Long = 0L,
    val remainingMs: Long = 0L
) {
    val fraction: Float get() = if (totalMs > 0) remainingMs.toFloat() / totalMs else 0f
}

/**
 * One sleep timer shared by sounds and stories. It fades both players out, then stops them.
 * Uses the monotonic clock so the countdown stays correct while the screen is off.
 */
@Singleton
class SleepTimer @Inject constructor(
    private val mixer: SoundMixer,
    private val player: PlayerManager
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var job: Job? = null

    private val _state = MutableStateFlow(SleepTimerState())
    val state: StateFlow<SleepTimerState> = _state.asStateFlow()

    fun start(durationMs: Long) {
        cancel()
        val total = durationMs.coerceAtLeast(1_000L)
        val fade = SleepTimerMath.fadeWindowMs(total)
        val endAt = SystemClock.elapsedRealtime() + total
        _state.value = SleepTimerState(true, total, total)
        job = scope.launch {
            while (true) {
                val remaining = (endAt - SystemClock.elapsedRealtime()).coerceAtLeast(0L)
                _state.value = SleepTimerState(true, total, remaining)
                val g = SleepTimerMath.gain(remaining, fade)
                mixer.setMasterGain(g)
                player.setMasterGain(g)
                if (remaining <= 0L) break
                delay(250)
            }
            mixer.stop()
            player.pause()
            mixer.setMasterGain(1f)
            player.setMasterGain(1f)
            _state.value = SleepTimerState()
        }
    }

    fun cancel() {
        job?.cancel()
        job = null
        if (_state.value.active) {
            mixer.setMasterGain(1f)
            player.setMasterGain(1f)
        }
        _state.value = SleepTimerState()
    }
}
