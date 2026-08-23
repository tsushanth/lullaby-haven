package com.kreativekoala.lullabyhaven.domain.model

import com.google.gson.annotations.SerializedName

/** Mirrors iOS Services/VoiceGenerationService.swift StandardVoice (Kokoro preset voices). */
data class StandardVoice(
    val id: String,
    val name: String,
    val style: String
) {
    companion object {
        val all: List<StandardVoice> = listOf(
            StandardVoice("af_bella", "Bella", "Calm & Soothing"),
            StandardVoice("af_nicole", "Rachel", "Warm & Clear"),
            StandardVoice("bf_emma", "Charlotte", "Elegant & Articulate"),
            StandardVoice("am_adam", "Adam", "Professional Narrator"),
            StandardVoice("bm_george", "Brian", "Deep British"),
            StandardVoice("am_michael", "Josh", "Storyteller")
        )
    }
}

/** Mirrors iOS SavedVoice (cloned parent voice, stored server-side). */
data class SavedVoice(
    val id: String,
    val name: String,
    val description: String?,
    @SerializedName("duration_sec") val durationSec: Double?,
    val exaggeration: Double?,
    @SerializedName("is_default") val isDefault: Boolean?,
    @SerializedName("usage_count") val usageCount: Int?,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("audio_url") val audioUrl: String?
)

data class VoiceListResponse(
    val voices: List<SavedVoice>
)

data class CreateVoiceRequest(
    val name: String,
    val description: String? = null
)

data class CreateVoiceResponse(
    val id: String,
    val name: String,
    @SerializedName("upload_url") val uploadUrl: String
)

/** Which voice to narrate a story with: a cloned parent voice, or a standard preset. */
sealed class NarratorVoice {
    data class Cloned(val voice: SavedVoice) : NarratorVoice()
    data class Standard(val voice: StandardVoice) : NarratorVoice()
}
