package com.kreativekoala.lullabyhaven.ui.myvoice

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import java.io.File

/**
 * Thin wrapper around MediaRecorder for capturing a parent's voice sample
 * (mirrors iOS Services/AudioRecorderService.swift / OwnLullabyRecorder.swift).
 * Real, working recording -- writes an actual m4a file to app-private storage.
 */
class VoiceRecorder(private val context: Context) {

    private var recorder: MediaRecorder? = null
    var outputFile: File? = null
        private set

    fun start(fileNamePrefix: String = "voice_sample") {
        val file = File(context.cacheDir, "${fileNamePrefix}_${System.currentTimeMillis()}.m4a")
        outputFile = file

        val mr = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        mr.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioEncodingBitRate(128000)
            setAudioSamplingRate(44100)
            setOutputFile(file.absolutePath)
            prepare()
            start()
        }
        recorder = mr
    }

    /** Returns the recorded file, or null if nothing was recorded. */
    fun stop(): File? {
        return try {
            recorder?.apply {
                stop()
                release()
            }
            outputFile
        } catch (e: RuntimeException) {
            // stop() throws if called too soon after start() with no data recorded.
            null
        } finally {
            recorder = null
        }
    }

    fun cancel() {
        try {
            recorder?.apply {
                stop()
                release()
            }
        } catch (_: RuntimeException) {
            // no-op: best-effort cleanup
        } finally {
            recorder = null
            outputFile?.delete()
            outputFile = null
        }
    }
}
