package com.kreativekoala.lullabyhaven.player

import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

/** Keeps story/sound playback alive in the background (screen off / app backgrounded). */
@AndroidEntryPoint
class PlaybackService : MediaSessionService() {

    @Inject
    lateinit var playerManager: PlayerManager

    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        mediaSession = MediaSession.Builder(this, playerManager.player).build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = mediaSession

    override fun onDestroy() {
        mediaSession?.run {
            player.release()
            release()
            mediaSession = null
        }
        super.onDestroy()
    }
}
