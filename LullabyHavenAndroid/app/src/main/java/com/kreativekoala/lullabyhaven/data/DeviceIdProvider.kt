package com.kreativekoala.lullabyhaven.data

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Generates and persists a stable per-install device ID, sent as the `X-Device-ID` header
 * on every request to the shared listenai-backend (same pattern the backend already uses for
 * this app family -- see ReadAloudAI/backend/src/routes/clonedVoices.ts and stories.ts, both
 * of which reject requests with 400 if this header is missing).
 *
 * There's no user auth system in this app yet, so this device ID is the only identity the
 * backend has for scoping cloned voices / stories / rate limits to "this install."
 */
@Singleton
class DeviceIdProvider @Inject constructor(
    @ApplicationContext context: Context
) {
    private val prefs = context.getSharedPreferences("lullaby_haven_device", Context.MODE_PRIVATE)

    val deviceId: String by lazy {
        prefs.getString(KEY_DEVICE_ID, null) ?: UUID.randomUUID().toString().also {
            prefs.edit().putString(KEY_DEVICE_ID, it).apply()
        }
    }

    companion object {
        private const val KEY_DEVICE_ID = "device_id"
    }
}
