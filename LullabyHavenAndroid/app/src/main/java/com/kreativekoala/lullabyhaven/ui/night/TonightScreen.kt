@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
package com.kreativekoala.lullabyhaven.ui.night

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

private val TIMER_CHOICES = listOf(15, 30, 45, 60, 90)

@Composable
fun TonightScreen(
    onOpenSounds: () -> Unit,
    onOpenStories: () -> Unit,
    viewModel: NightViewModel = hiltViewModel()
) {
    val mix by viewModel.mix.collectAsState()
    val timer by viewModel.timerState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            "Goodnight",
            style = MaterialTheme.typography.headlineLarge,
            modifier = Modifier.fillMaxWidth()
        )
        Text(
            "Set the timer, add a sound, or pick a story.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(24.dp))

        TimerDial(timer.active, timer.fraction, timer.remainingMs)
        Spacer(Modifier.height(16.dp))

        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            modifier = Modifier.fillMaxWidth()
        ) {
            TIMER_CHOICES.forEach { m ->
                FilterChip(
                    selected = timer.active && timer.totalMs == m * 60_000L,
                    onClick = { viewModel.startTimer(m) },
                    label = { Text("$m min") }
                )
            }
        }
        if (timer.active) {
            OutlinedButton(onClick = viewModel::cancelTimer, modifier = Modifier.padding(top = 8.dp)) {
                Text("Cancel timer")
            }
        }
        Spacer(Modifier.height(24.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Sounds", style = MaterialTheme.typography.titleLarge)
                val names = mix.activeKinds.joinToString(" + ") { it.label }
                Text(
                    if (names.isEmpty()) "Nothing mixed yet." else names,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (mix.activeKinds.isEmpty()) {
                    Button(onClick = onOpenSounds) { Text("Choose sounds") }
                } else {
                    Button(onClick = viewModel::togglePlayback) {
                        Icon(
                            if (mix.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                            contentDescription = null
                        )
                        Text(if (mix.isPlaying) "Pause" else "Play", modifier = Modifier.padding(start = 8.dp))
                    }
                    OutlinedButton(onClick = onOpenSounds) { Text("Adjust mix") }
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        Card(
            onClick = onOpenStories,
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(Modifier.padding(16.dp)) {
                Text("Bedtime stories", style = MaterialTheme.typography.titleLarge)
                Text(
                    "Calm original stories, narrated and ready to play.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
