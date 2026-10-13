package com.kreativekoala.lullabyhaven.ui.night

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

/** Formats a countdown as H:MM:SS or M:SS. */
fun formatCountdown(ms: Long): String {
    val total = (ms / 1000).coerceAtLeast(0)
    val h = total / 3600
    val m = (total % 3600) / 60
    val s = total % 60
    return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
}

/** A moon-ring dial: the amber arc shrinks as the sleep timer runs down. */
@Composable
fun TimerDial(active: Boolean, fraction: Float, remainingMs: Long, modifier: Modifier = Modifier) {
    val track = MaterialTheme.colorScheme.surfaceVariant
    val glow = MaterialTheme.colorScheme.primary
    val label = if (active) "Sleep timer, ${formatCountdown(remainingMs)} left" else "Sleep timer off"
    Box(
        modifier = modifier
            .size(220.dp)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.size(220.dp)) {
            val stroke = 14.dp.toPx()
            val inset = stroke / 2
            val sz = Size(size.width - stroke, size.height - stroke)
            drawArc(track, 0f, 360f, false, Offset(inset, inset), sz, style = Stroke(stroke))
            if (active) {
                drawArc(glow, -90f, 360f * fraction.coerceIn(0f, 1f), false, Offset(inset, inset), sz,
                    style = Stroke(stroke, cap = StrokeCap.Round))
            }
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                if (active) formatCountdown(remainingMs) else "Sleep timer",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            Text(
                if (active) "fades out gently" else "choose below",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
