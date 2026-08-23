package com.kreativekoala.lullabyhaven.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.navigation.NavType
import com.kreativekoala.lullabyhaven.ui.home.HomeScreen
import com.kreativekoala.lullabyhaven.ui.myvoice.LullabyGeneratorScreen
import com.kreativekoala.lullabyhaven.ui.myvoice.MyVoiceScreen
import com.kreativekoala.lullabyhaven.ui.myvoice.VoiceRecordingScreen
import com.kreativekoala.lullabyhaven.ui.stories.BedtimeStoriesScreen
import com.kreativekoala.lullabyhaven.ui.stories.StoryPlayerScreen

@Composable
fun LullabyHavenNavGraph(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = Routes.HOME) {
        composable(Routes.HOME) {
            HomeScreen(
                onOpenStories = { navController.navigate(Routes.STORIES) },
                onOpenMyVoice = { navController.navigate(Routes.MY_VOICE) }
            )
        }
        composable(Routes.STORIES) {
            BedtimeStoriesScreen(
                onStoryClick = { storyId -> navController.navigate(Routes.storyPlayer(storyId)) }
            )
        }
        composable(
            route = Routes.STORY_PLAYER,
            arguments = listOf(navArgument("storyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val storyId = backStackEntry.arguments?.getString("storyId").orEmpty()
            StoryPlayerScreen(storyId = storyId, onBack = { navController.popBackStack() })
        }
        composable(Routes.MY_VOICE) {
            MyVoiceScreen(
                onRecordVoice = { navController.navigate(Routes.VOICE_RECORDING) },
                onVoiceClick = { voice -> navController.navigate(Routes.lullabyGenerator(voice.id)) }
            )
        }
        composable(Routes.VOICE_RECORDING) {
            VoiceRecordingScreen(
                onBack = { navController.popBackStack() },
                onRecorded = { _ ->
                    // TODO: upload recorded sample via VoiceRepository.createVoice() flow.
                    navController.popBackStack()
                }
            )
        }
        composable(
            route = Routes.LULLABY_GENERATOR,
            arguments = listOf(navArgument("voiceId") { type = NavType.StringType })
        ) { backStackEntry ->
            val voiceId = backStackEntry.arguments?.getString("voiceId").orEmpty()
            LullabyGeneratorScreen(voiceId = voiceId, onBack = { navController.popBackStack() })
        }
        // Paywall route intentionally not registered -- billing is skipped for initial
        // launch. PaywallScreen.kt is kept for when billing is reintroduced.
    }
}
