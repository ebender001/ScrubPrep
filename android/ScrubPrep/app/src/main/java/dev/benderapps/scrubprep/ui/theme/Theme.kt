package dev.benderapps.scrubprep.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** The app's accent — same orange as the iOS AccentColor. */
val ScrubOrange = Color(0xFFFD7601)

/** Tints for the Home action cards and quiz feedback, matching the iOS app. */
val QuizOrange = Color(0xFFFF9500)
val RapidYellow = Color(0xFFFFCC00)
val InfoBlue = Color(0xFF007AFF)
val SuccessGreen = Color(0xFF34C759)
val DangerRed = Color(0xFFFF3B30)

private val LightColors = lightColorScheme(
    primary = ScrubOrange,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFFE9D6),
    onPrimaryContainer = Color(0xFF4A2200),
    secondary = Color(0xFF6C6C70),
    background = Color.White,
    onBackground = Color(0xFF1C1C1E),
    surface = Color.White,
    onSurface = Color(0xFF1C1C1E),
    surfaceVariant = Color(0xFFF2F2F7),
    onSurfaceVariant = Color(0xFF6C6C70),
    surfaceContainerLowest = Color.White,
    surfaceContainerLow = Color(0xFFF7F7FA),
    surfaceContainer = Color(0xFFF2F2F7),
    surfaceContainerHigh = Color(0xFFEDEDF2),
    surfaceContainerHighest = Color(0xFFE5E5EA),
    outline = Color(0xFFC6C6C8),
    outlineVariant = Color(0xFFE0E0E4),
    error = Color(0xFFD62C20),
)

private val DarkColors = darkColorScheme(
    primary = ScrubOrange,
    onPrimary = Color.White,
    primaryContainer = Color(0xFF4A2A10),
    onPrimaryContainer = Color(0xFFFFDCC2),
    secondary = Color(0xFF98989D),
    background = Color(0xFF000000),
    onBackground = Color(0xFFF2F2F7),
    surface = Color(0xFF000000),
    onSurface = Color(0xFFF2F2F7),
    surfaceVariant = Color(0xFF1C1C1E),
    onSurfaceVariant = Color(0xFF98989D),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF111113),
    surfaceContainer = Color(0xFF1C1C1E),
    surfaceContainerHigh = Color(0xFF2C2C2E),
    surfaceContainerHighest = Color(0xFF3A3A3C),
    outline = Color(0xFF48484A),
    outlineVariant = Color(0xFF38383A),
    error = Color(0xFFFF6B60),
)

@Composable
fun ScrubPrepTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        content = content,
    )
}
