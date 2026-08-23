package com.kreativekoala.lullabyhaven.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = LHAccent,
    secondary = LHAccent2,
    background = LHBackgroundLight,
    surface = LHSurfaceLight,
    onBackground = LHPrimaryTextLight,
    onSurface = LHPrimaryTextLight
)

private val DarkColors = darkColorScheme(
    primary = LHAccent2,
    secondary = LHAccent,
    background = LHBackgroundDark,
    surface = LHSurfaceDark,
    onBackground = LHPrimaryTextDark,
    onSurface = LHPrimaryTextDark
)

@Composable
fun LullabyHavenTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) DarkColors else LightColors
    MaterialTheme(
        colorScheme = colors,
        typography = LullabyHavenTypography,
        content = content
    )
}
