package com.kreativekoala.lullabyhaven.ui.night

import androidx.lifecycle.ViewModel
import com.kreativekoala.lullabyhaven.audio.SleepTimer
import com.kreativekoala.lullabyhaven.audio.SleepTimerState
import com.kreativekoala.lullabyhaven.audio.SoundKind
import com.kreativekoala.lullabyhaven.audio.SoundMixer
import com.kreativekoala.lullabyhaven.audio.MixerState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject

/** Thin view model over the singleton mixer and timer, shared by the Tonight and Sounds tabs. */
@HiltViewModel
class NightViewModel @Inject constructor(
    private val mixer: SoundMixer,
    private val timer: SleepTimer
) : ViewModel() {
    val mix: StateFlow<MixerState> = mixer.state
    val timerState: StateFlow<SleepTimerState> = timer.state

    fun toggleSound(kind: SoundKind) {
        val on = mixer.state.value.levels.containsKey(kind)
        mixer.setLevel(kind, if (on) 0f else DEFAULT_LEVEL)
    }

    fun setLevel(kind: SoundKind, level: Float) = mixer.setLevel(kind, level)
    fun togglePlayback() = mixer.toggle()
    fun startTimer(minutes: Int) = timer.start(minutes * 60_000L)
    fun cancelTimer() = timer.cancel()

    companion object { const val DEFAULT_LEVEL = 0.6f }
}
