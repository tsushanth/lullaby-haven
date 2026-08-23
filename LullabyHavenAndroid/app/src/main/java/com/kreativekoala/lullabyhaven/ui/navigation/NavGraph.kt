package com.kreativekoala.lullabyhaven.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.navigation.NavType
import com.kreativekoala.lullabyhaven.ui.home.HomeScreen
import com.kreativekoala.lullabyhaven.ui.stories.BedtimeStoriesScreen
import com.kreativekoala.lullabyhaven.ui.stories.StoryPlayerScreen

/**
 * My Voice / voice-cloning routes (MyVoiceScreen, VoiceRecordingScreen,
 * LullabyGeneratorScreen) are intentionally NOT registered here — the
 * backend wiring is a stub (LullabyGeneratorScreen has a TODO, no real
 * generation call), so shipping a reachable "Clone My Voice" flow that
 * leads nowhere would be misleading and a Play Store review risk.
 * Screens are left in place, unused, for when that feature is real.
 */
@Composable
fun LullabyHavenNavGraph(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = Routes.HOME) {
        composable(Routes.HOME) {
            HomeScreen(
                onOpenStories = { navController.navigate(Routes.STORIES) }
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
        // Paywall route intentionally not registered -- billing is skipped for initial
        // launch. PaywallScreen.kt is kept for when billing is reintroduced.
    }
}
