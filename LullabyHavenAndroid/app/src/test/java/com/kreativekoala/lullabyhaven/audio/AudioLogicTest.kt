package com.kreativekoala.lullabyhaven.audio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class AudioLogicTest {

    @Test fun fadeWindowIsCappedAndNeverMoreThanAThirdOfTimer() {
        assertEquals(60_000L, SleepTimerMath.fadeWindowMs(60 * 60_000L))
        assertEquals(10_000L, SleepTimerMath.fadeWindowMs(30_000L))
        assertEquals(0L, SleepTimerMath.fadeWindowMs(0L))
    }

    @Test fun gainIsFullBeforeFadeAndZeroAtEnd() {
        assertEquals(1f, SleepTimerMath.gain(120_000L, 60_000L), 0f)
        assertEquals(1f, SleepTimerMath.gain(60_000L, 60_000L), 0f)
        assertEquals(0f, SleepTimerMath.gain(0L, 60_000L), 0f)
    }

    @Test fun gainIsMonotonicallyDecreasingInsideFade() {
        var prev = 1f
        for (r in 60_000L downTo 0L step 1_000L) {
            val g = SleepTimerMath.gain(r, 60_000L)
            assertTrue(g <= prev + 1e-6f)
            prev = g
        }
        assertEquals(0.25f, SleepTimerMath.gain(30_000L, 60_000L), 1e-6f)
    }

    @Test fun mixerLevelsClampAndZeroRemovesLayer() {
        var s = MixerState()
        s = s.withLevel(SoundKind.RAIN, 1.7f)
        assertEquals(1f, s.levels[SoundKind.RAIN]!!, 0f)
        s = s.withLevel(SoundKind.RAIN, 0f)
        assertFalse(s.levels.containsKey(SoundKind.RAIN))
    }

    @Test fun mixerIsPlayingOnlyWhenUnpausedWithLayers() {
        var s = MixerState(paused = false)
        assertFalse(s.isPlaying)
        s = s.withLevel(SoundKind.FAN, 0.5f)
        assertTrue(s.isPlaying)
        assertFalse(s.copy(paused = true).isPlaying)
    }

    @Test fun effectiveVolumeAppliesMasterAndDuck() {
        val s = MixerState(masterGain = 0.5f).withLevel(SoundKind.OCEAN, 0.8f)
        assertEquals(0.4f, s.effective(SoundKind.OCEAN), 1e-6f)
        assertEquals(0.12f, s.effective(SoundKind.OCEAN, duck = 0.3f), 1e-6f)
        assertEquals(0f, s.effective(SoundKind.WHITE), 0f)
    }

    @Test fun everySoundRendersExpectedLengthWithinRangeAndNotSilent() {
        for (kind in SoundKind.values()) {
            val pcm = SoundSynth.render(kind)
            assertEquals(kind.name, kind.loopSeconds * SoundSynth.SAMPLE_RATE, pcm.size)
            val peak = pcm.maxOf { abs(it.toInt()) }
            assertTrue("$kind silent", peak > 1000)
            assertTrue("$kind clipped", peak < 32767)
        }
    }

    @Test fun renderingIsDeterministic() {
        assertTrue(SoundSynth.render(SoundKind.RAIN).contentEquals(SoundSynth.render(SoundKind.RAIN)))
    }

    @Test fun noiseLoopSeamHasNoJump() {
        for (kind in listOf(SoundKind.PINK, SoundKind.BROWN, SoundKind.OCEAN)) {
            val pcm = SoundSynth.render(kind)
            val jump = abs(pcm.last().toInt() - pcm.first().toInt())
            val typicalStep = (1 until 4000).map { abs(pcm[it].toInt() - pcm[it - 1].toInt()) }.average()
            // The seam should look like any other neighbouring pair of samples (generous bound).
            assertTrue("$kind seam jump $jump vs step $typicalStep", jump < typicalStep * 12 + 2000)
        }
    }
}
