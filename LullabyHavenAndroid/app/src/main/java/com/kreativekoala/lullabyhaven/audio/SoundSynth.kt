package com.kreativekoala.lullabyhaven.audio

import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.random.Random

enum class SoundKind(val label: String, val blurb: String, val loopSeconds: Int) {
    WHITE("White noise", "Even, steady hush", 8),
    PINK("Pink noise", "Softer, like distant wind", 8),
    BROWN("Brown noise", "Deep, warm rumble", 8),
    RAIN("Rain", "Gentle rainfall", 10),
    OCEAN("Ocean", "Slow rolling waves", 12),
    FAN("Fan", "Low room hum", 8),
    HEARTBEAT("Heartbeat", "Calm 70 bpm pulse", 12),
    MUSIC_BOX("Music box", "Slow lullaby chimes", 24);
}

/**
 * On-device sound synthesis. Everything is rendered as seamless loops (mono, 16-bit PCM), so the
 * app ships no audio assets and works fully offline. Output is deterministic for a given seed.
 */
object SoundSynth {
    const val SAMPLE_RATE = 22050

    fun render(kind: SoundKind, seed: Long = kind.ordinal.toLong() + 1): ShortArray {
        val n = kind.loopSeconds * SAMPLE_RATE
        val rnd = Random(seed)
        val f = when (kind) {
            SoundKind.WHITE -> loopable(n) { len -> white(len, rnd).also { scale(it, 0.35f) } }
            SoundKind.PINK -> loopable(n) { len -> pink(len, rnd).also { scale(it, 0.9f) } }
            SoundKind.BROWN -> loopable(n) { len -> brown(len, rnd) }
            SoundKind.RAIN -> loopable(n) { len -> rain(len, rnd) }
            SoundKind.OCEAN -> ocean(n, rnd)
            SoundKind.FAN -> fan(n, rnd)
            SoundKind.HEARTBEAT -> heartbeat(n)
            SoundKind.MUSIC_BOX -> musicBox(n)
        }
        return toPcm(f)
    }

    // ---- building blocks -------------------------------------------------------------------

    internal fun white(n: Int, rnd: Random) = FloatArray(n) { rnd.nextFloat() * 2f - 1f }

    /** Paul Kellet's economical pink-noise filter. */
    internal fun pink(n: Int, rnd: Random): FloatArray {
        var b0 = 0f; var b1 = 0f; var b2 = 0f; var b3 = 0f; var b4 = 0f; var b5 = 0f; var b6 = 0f
        val out = FloatArray(n)
        for (i in 0 until n) {
            val w = rnd.nextFloat() * 2f - 1f
            b0 = 0.99886f * b0 + w * 0.0555179f
            b1 = 0.99332f * b1 + w * 0.0750759f
            b2 = 0.96900f * b2 + w * 0.1538520f
            b3 = 0.86650f * b3 + w * 0.3104856f
            b4 = 0.55000f * b4 + w * 0.5329522f
            b5 = -0.7616f * b5 - w * 0.0168980f
            out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362f) * 0.11f
            b6 = w * 0.115926f
        }
        return out
    }

    internal fun brown(n: Int, rnd: Random): FloatArray {
        var last = 0f
        val out = FloatArray(n)
        for (i in 0 until n) {
            last = (last + 0.02f * (rnd.nextFloat() * 2f - 1f)) / 1.02f
            out[i] = last * 3.5f
        }
        return out
    }

    private fun lowpass(x: FloatArray, cutoffHz: Float): FloatArray {
        val a = (1f - exp(-2.0 * PI * cutoffHz / SAMPLE_RATE)).toFloat()
        var y = 0f
        return FloatArray(x.size) { i -> y += a * (x[i] - y); y }
    }

    private fun scale(x: FloatArray, g: Float) { for (i in x.indices) x[i] *= g }

    private fun rain(n: Int, rnd: Random): FloatArray {
        val hiss = lowpass(white(n, rnd), 6000f)
        val body = lowpass(pink(n, rnd), 900f)
        for (i in 0 until n) hiss[i] = hiss[i] * 0.22f + body[i] * 0.5f
        // random droplets: short decaying high sine pings
        val drops = (n / SAMPLE_RATE) * 28
        repeat(drops) {
            val start = rnd.nextInt(n)
            val freq = 1800f + rnd.nextFloat() * 3200f
            val amp = 0.05f + rnd.nextFloat() * 0.08f
            val len = (0.018f * SAMPLE_RATE).toInt()
            for (k in 0 until len) {
                val env = exp(-k / (0.005f * SAMPLE_RATE))
                hiss[(start + k) % n] += amp * env * sin(2.0 * PI * freq * k / SAMPLE_RATE).toFloat()
            }
        }
        return hiss
    }

    private fun ocean(n: Int, rnd: Random): FloatArray {
        val base = lowpass(loopable(n) { len -> pink(len, rnd) }, 1200f)
        val waves = 3 // integer waves per loop keeps the swell seamless
        for (i in 0 until n) {
            val phase = 2.0 * PI * waves * i / n
            val swell = (0.5 + 0.5 * sin(phase - PI / 2)).pow(2.0).toFloat()
            base[i] *= (0.25f + 0.75f * swell) * 1.6f
        }
        return base
    }

    private fun fan(n: Int, rnd: Random): FloatArray {
        val b = lowpass(loopable(n) { len -> brown(len, rnd) }, 400f)
        val hz = 120.0 // whole cycles per loop (120 Hz * 8 s), so the hum loops cleanly
        for (i in 0 until n) {
            b[i] = b[i] * 0.9f + 0.05f * sin(2.0 * PI * hz * i / SAMPLE_RATE).toFloat()
        }
        return b
    }

    private fun heartbeat(n: Int): FloatArray {
        val beats = 14
        val period = n / beats
        val out = FloatArray(n)
        fun thump(at: Int, amp: Float, freq: Float) {
            val len = (0.22f * SAMPLE_RATE).toInt()
            for (k in 0 until len) {
                val env = exp(-k / (0.045f * SAMPLE_RATE))
                out[(at + k) % n] += amp * env * sin(2.0 * PI * freq * k / SAMPLE_RATE).toFloat()
            }
        }
        for (b in 0 until beats) {
            val t = b * period
            thump(t, 0.9f, 52f)                                  // "lub"
            thump(t + (0.28f * SAMPLE_RATE).toInt(), 0.6f, 62f)  // "dub"
        }
        return out
    }

    private val noteHz = mapOf(
        "C4" to 261.63, "D4" to 293.66, "E4" to 329.63, "F4" to 349.23, "G4" to 392.0,
        "A4" to 440.0, "B4" to 493.88, "C5" to 523.25, "G3" to 196.0, "C3" to 130.81
    )

    private fun musicBox(n: Int): FloatArray {
        val out = FloatArray(n)
        val beat = 0.8f // seconds per beat (75 bpm)
        // Simple original 4-bar lullaby phrase in 3/4, then a gentle answer, looping.
        val melody = listOf(
            "E4" to 1f, "E4" to 1f, "G4" to 1f, "E4" to 1f, "E4" to 1f, "G4" to 1f,
            "E4" to 1f, "G4" to 1f, "C5" to 1f, "B4" to 1f, "A4" to 1f, "A4" to 1f,
            "G4" to 2f, "G4" to 1f, "F4" to 1f, "D4" to 1f, "E4" to 1f,
            "F4" to 1f, "D4" to 1f, "C4" to 3f
        )
        var t = 0f
        for ((name, beats) in melody) {
            bell(out, noteHz.getValue(name), t, 0.28f)
            t += beats * beat
        }
        // soft bass on beat 1 of each 3-beat bar
        var bar = 0f
        while (bar < t) { bell(out, noteHz.getValue(if ((bar / (3 * beat)).toInt() % 2 == 0) "C3" else "G3"), bar, 0.18f); bar += 3 * beat }
        return out
    }

    /** A music-box-like bell: decaying fundamental plus a bright, faster-decaying partial. */
    private fun bell(out: FloatArray, hz: Double, startSec: Float, amp: Float) {
        val n = out.size
        val start = (startSec * SAMPLE_RATE).toInt()
        val len = (2.6f * SAMPLE_RATE).toInt()
        for (k in 0 until len) {
            val ts = k.toDouble() / SAMPLE_RATE
            val env = exp(-ts * 2.2).toFloat()
            val v = sin(2 * PI * hz * ts) + 0.35 * exp(-ts * 6.0) * sin(2 * PI * hz * 4.0 * ts)
            out[(start + k) % n] += amp * env * v.toFloat() // wraps so the tail rings into the loop start
        }
    }

    // ---- looping / PCM ---------------------------------------------------------------------

    /**
     * Renders [n] + crossfade samples and blends the extra tail into the head so the end of the
     * loop flows directly into its start with no click.
     */
    internal fun loopable(n: Int, gen: (Int) -> FloatArray): FloatArray {
        val xf = min(n / 4, SAMPLE_RATE / 2)
        val x = gen(n + xf)
        val out = x.copyOf(n)
        for (i in 0 until xf) {
            val w = i.toFloat() / xf
            out[i] = x[i] * w + x[n + i] * (1f - w)
        }
        return out
    }

    internal fun toPcm(f: FloatArray): ShortArray {
        var peak = 0f
        for (v in f) peak = max(peak, kotlin.math.abs(v))
        val g = if (peak > 0.9f) 0.9f / peak else 1f
        return ShortArray(f.size) { i -> (f[i] * g * 32767f).toInt().coerceIn(-32767, 32767).toShort() }
    }
}
