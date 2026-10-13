@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.sounds

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.kreativekoala.lullabyhaven.audio.SoundKind
import com.kreativekoala.lullabyhaven.ui.night.NightViewModel

@Composable
fun SoundsScreen(viewModel: NightViewModel = hiltViewModel()) {
    val mix by viewModel.mix.collectAsState()

    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(start = 20.dp, end = 20.dp, top = 24.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(Modifier.weight(1f)) {
                Text("Sounds", style = MaterialTheme.typography.headlineLarge)
                Text(
                    "Layer as many as you like. Made on your device, no internet needed.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (mix.activeKinds.isNotEmpty()) {
                FilledIconButton(onClick = viewModel::togglePlayback) {
                    Icon(
                        if (mix.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                        contentDescription = if (mix.isPlaying) "Pause sounds" else "Play sounds"
                    )
                }
            }
        }
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier.fillMaxSize()
        ) {
            items(SoundKind.values().toList(), key = { it.name }) { kind ->
                val level = mix.levels[kind]
                SoundCard(
                    kind = kind,
                    level = level,
                    onToggle = { viewModel.toggleSound(kind) },
                    onLevel = { viewModel.setLevel(kind, it) }
                )
            }
        }
    }
}

@Composable
private fun SoundCard(kind: SoundKind, level: Float?, onToggle: () -> Unit, onLevel: (Float) -> Unit) {
    val on = level != null
    Card(
        onClick = onToggle,
        modifier = Modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = false) {
                contentDescription = "${kind.label}, ${if (on) "on" else "off"}"
            },
        colors = CardDefaults.cardColors(
            containerColor = if (on) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.surface
        )
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column(Modifier.weight(1f)) {
                    Text(kind.label, style = MaterialTheme.typography.titleLarge)
                    Text(
                        kind.blurb,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Text(
                    if (on) "On" else "Off",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (on) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (level != null) {
                Slider(
                    value = level,
                    onValueChange = onLevel,
                    valueRange = 0.05f..1f,
                    modifier = Modifier
                        .fillMaxWidth()
                        .semantics { contentDescription = "${kind.label} volume" }
                )
            }
        }
    }
}
