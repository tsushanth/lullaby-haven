package com.kreativekoala.lullabyhaven.data.repository

import com.kreativekoala.lullabyhaven.data.api.VoiceApi
import com.kreativekoala.lullabyhaven.domain.model.SavedVoice
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Mirrors iOS VoiceGenerationService's cloned-voice CRUD flow (record -> upload -> confirm).
 *
 * TODO(backend wiring): calls are implemented against the real API shape but are not yet
 * exercised end-to-end (no live account/credentials wired for Android). Upload step (PUT to
 * a presigned URL) needs a multipart/raw-body OkHttp call added once we validate the presigned
 * URL flow against this shared backend from Android.
 */
@Singleton
class VoiceRepository @Inject constructor(
    private val api: VoiceApi
) {
    suspend fun listVoices(): Result<List<SavedVoice>> = runCatching {
        api.listVoices().voices
    }

    suspend fun deleteVoice(id: String): Result<Unit> = runCatching {
        api.deleteVoice(id)
        Unit
    }

    // TODO: createVoice() + upload-to-presigned-url + confirmVoice() -- wire once
    // VoiceRecordingScreen captures a real sample and we validate the upload contract.
}
