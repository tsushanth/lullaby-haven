package com.kreativekoala.lullabyhaven.data.api

import com.kreativekoala.lullabyhaven.domain.model.CreateVoiceRequest
import com.kreativekoala.lullabyhaven.domain.model.CreateVoiceResponse
import com.kreativekoala.lullabyhaven.domain.model.VoiceListResponse
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.POST
import retrofit2.http.Query

/**
 * Retrofit mirror of iOS Services/VoiceGenerationService.swift.
 *
 * Endpoints are defined to match the existing production API shape (same backend as iOS:
 * https://listenai-backend.fly.dev, shared with Audexa/ReadAloud voice-cloning + Kokoro TTS
 * on the Hetzner box). Do not point this at a new/different backend without explicit sign-off,
 * since it's shared production infra for other apps.
 *
 * `synthesizeStoryAudio` (POST /api/tts) is real and wired into StoryPlayerViewModel --
 * synchronous Kokoro synthesis, returns raw audio bytes directly (no job/poll cycle needed).
 * Cloned-voice narration would use `createClonedTtsJob` + polling `getTtsJobStatus` instead,
 * but that path is NOT wired into the UI yet (see LullabyGeneratorScreen).
 */
interface VoiceApi {

    @GET("api/cloned-voices")
    suspend fun listVoices(
        @Query("include_audio_urls") includeAudioUrls: Boolean = true
    ): VoiceListResponse

    @POST("api/cloned-voices")
    suspend fun createVoice(@Body request: CreateVoiceRequest): CreateVoiceResponse

    @POST("api/cloned-voices/{voiceId}/confirm")
    suspend fun confirmVoice(@Path("voiceId") voiceId: String): Response<Unit>

    @DELETE("api/cloned-voices/{id}")
    suspend fun deleteVoice(@Path("id") id: String): Response<Unit>

    @POST("api/tts/job-cloned")
    suspend fun createClonedTtsJob(@Body request: Map<String, @JvmSuppressWildcards Any>): Map<String, Any>

    @GET("api/tts/job/{jobId}")
    suspend fun getTtsJobStatus(@Path("jobId") jobId: String): Map<String, Any>

    @POST("api/stories/generate")
    suspend fun generateStory(@Body request: Map<String, @JvmSuppressWildcards Any>): Map<String, Any>

    /**
     * Synchronous standard-voice TTS. Returns raw audio bytes (audio/mpeg by default) for the
     * given text + Kokoro voice_id. No auth header required -- the backend falls back to a
     * default "pro" user when Authorization is absent (see listenai-backend's requireAuth
     * middleware), so this works out of the box for an app with no user accounts yet.
     */
    @POST("api/tts")
    suspend fun synthesizeStoryAudio(@Body request: Map<String, @JvmSuppressWildcards Any>): Response<ResponseBody>
}
