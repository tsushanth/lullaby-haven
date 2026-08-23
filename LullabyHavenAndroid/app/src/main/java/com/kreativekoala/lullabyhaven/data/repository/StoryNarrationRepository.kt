package com.kreativekoala.lullabyhaven.data.repository

import android.content.Context
import com.kreativekoala.lullabyhaven.data.api.VoiceApi
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Fetches narrated story audio from the shared listenai-backend's synchronous TTS endpoint
 * (POST /api/tts, Kokoro self-hosted synthesis) and caches it on disk so ExoPlayer can play a
 * plain file:// URI.
 *
 * This is the standard-preset-voice narration path (see [BedtimeStory]/[StoryPlayerViewModel]).
 * Cloned-voice narration (a parent's own recorded voice) is a separate, still-unwired flow --
 * see LullabyGeneratorScreen and VoiceApi.createClonedTtsJob.
 */
@Singleton
class StoryNarrationRepository @Inject constructor(
    private val api: VoiceApi,
    @ApplicationContext private val context: Context
) {
    /** Default Kokoro voice: "Bella" (af_bella) -- calm & soothing, a good bedtime-story fit. */
    private val defaultVoiceId = "af_bella"

    suspend fun narrationFor(storyId: String, text: String): Result<File> = withContext(Dispatchers.IO) {
        runCatching {
            val cacheFile = File(context.cacheDir, "narration_${storyId}_$defaultVoiceId.mp3")
            if (cacheFile.exists() && cacheFile.length() > 0) {
                return@runCatching cacheFile
            }

            val response = api.synthesizeStoryAudio(
                mapOf(
                    "text" to text,
                    "voice_id" to defaultVoiceId,
                    "provider" to "selfhosted"
                )
            )

            if (!response.isSuccessful) {
                val errorBody = response.errorBody()?.string().orEmpty()
                error("TTS request failed: HTTP ${response.code()} $errorBody")
            }

            val body = response.body() ?: error("TTS response had no audio body")

            body.byteStream().use { input ->
                cacheFile.outputStream().use { output -> input.copyTo(output) }
            }

            cacheFile
        }
    }
}
