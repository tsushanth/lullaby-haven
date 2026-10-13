package com.kreativekoala.lullabyhaven.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColors = lightColorScheme(
    primary = LHAccent,
    onPrimary = Color.White,
    secondary = LHAccent2,
    background = LHBackgroundLight,
    surface = LHSurfaceLight,
    surfaceVariant = Color(0xFFF1E8D8),
    onBackground = LHPrimaryTextLight,
    onSurface = LHPrimaryTextLight,
    onSurfaceVariant = LHSecondaryTextLight
)

private val DarkColors = darkColorScheme(
    primary = LHAccent2,
    onPrimary = Color(0xFF2A1A05),
    secondary = LHAccent,
    background = LHBackgroundDark,
    surface = LHSurfaceDark,
    surfaceVariant = LHSurfaceHighDark,
    onBackground = LHPrimaryTextDark,
    onSurface = LHPrimaryTextDark,
    onSurfaceVariant = LHSecondaryTextDark
)

@Composable
fun LullabyHavenTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = LullabyHavenTypography,
        content = content
    )
}
