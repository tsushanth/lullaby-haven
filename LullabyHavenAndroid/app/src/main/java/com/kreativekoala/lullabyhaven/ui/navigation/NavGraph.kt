package com.kreativekoala.lullabyhaven.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.kreativekoala.lullabyhaven.ui.night.TonightScreen
import com.kreativekoala.lullabyhaven.ui.sounds.SoundsScreen
import com.kreativekoala.lullabyhaven.ui.stories.BedtimeStoriesScreen
import com.kreativekoala.lullabyhaven.ui.stories.StoryPlayerScreen

private data class Tab(val route: String, val label: String, val icon: ImageVector)

private val TABS = listOf(
    Tab(Routes.HOME, "Tonight", Icons.Filled.NightsStay),
    Tab(Routes.SOUNDS, "Sounds", Icons.Filled.GraphicEq),
    Tab(Routes.STORIES, "Stories", Icons.Filled.AutoStories)
)

/**
 * My Voice / voice-cloning routes are intentionally NOT registered (backend wiring is a stub;
 * shipping a reachable flow that leads nowhere would be misleading). The paywall route is also
 * not registered -- billing is skipped for the initial launch.
 */
@Composable
fun LullabyHavenNavGraph(navController: NavHostController = rememberNavController()) {
    val backStack by navController.currentBackStackEntryAsState()
    val current = backStack?.destination?.route
    val showBar = current in TABS.map { it.route }

    fun goTab(route: String) = navController.navigate(route) {
        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }

    Scaffold(
        bottomBar = {
            if (showBar) {
                NavigationBar {
                    TABS.forEach { tab ->
                        NavigationBarItem(
                            selected = current == tab.route,
                            onClick = { goTab(tab.route) },
                            icon = { Icon(tab.icon, contentDescription = null) },
                            label = { Text(tab.label) }
                        )
                    }
                }
            }
        }
    ) { inner ->
        NavHost(
            navController = navController,
            startDestination = Routes.HOME,
            modifier = Modifier.padding(inner)
        ) {
            composable(Routes.HOME) {
                Box(Modifier.statusBarsPadding()) {
                    TonightScreen(
                        onOpenSounds = { goTab(Routes.SOUNDS) },
                        onOpenStories = { goTab(Routes.STORIES) }
                    )
                }
            }
            composable(Routes.SOUNDS) { Box(Modifier.statusBarsPadding()) { SoundsScreen() } }
            composable(Routes.STORIES) {
                Box(Modifier.statusBarsPadding()) {
                    BedtimeStoriesScreen(
                        onStoryClick = { storyId -> navController.navigate(Routes.storyPlayer(storyId)) }
                    )
                }
            }
            composable(
                route = Routes.STORY_PLAYER,
                arguments = listOf(navArgument("storyId") { type = NavType.StringType })
            ) { entry ->
                val storyId = entry.arguments?.getString("storyId").orEmpty()
                StoryPlayerScreen(storyId = storyId, onBack = { navController.popBackStack() })
            }
        }
    }
}
