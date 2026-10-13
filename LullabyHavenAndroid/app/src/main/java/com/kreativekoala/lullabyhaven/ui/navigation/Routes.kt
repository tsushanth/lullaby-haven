package com.kreativekoala.lullabyhaven.ui.navigation

object Routes {
    const val HOME = "home"          // "Tonight" tab
    const val SOUNDS = "sounds"
    const val STORIES = "stories"
    const val STORY_PLAYER = "story_player/{storyId}"
    const val MY_VOICE = "my_voice"
    const val VOICE_RECORDING = "voice_recording"
    const val LULLABY_GENERATOR = "lullaby_generator/{voiceId}"
    const val PAYWALL = "paywall"

    fun storyPlayer(storyId: String) = "story_player/$storyId"
    fun lullabyGenerator(voiceId: String) = "lullaby_generator/$voiceId"
}
