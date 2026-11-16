@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.sounds

import androidx.compose.ui.res.stringResource
import com.kreativekoala.lullabyhaven.R
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
                Text(stringResource(R.string.tab_sounds), style = MaterialTheme.typography.headlineLarge)
                Text(
                    stringResource(R.string.sounds_subtitle),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (mix.activeKinds.isNotEmpty()) {
                FilledIconButton(onClick = viewModel::togglePlayback) {
                    Icon(
                        if (mix.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                        contentDescription = stringResource(if (mix.isPlaying) R.string.sounds_pause_cd else R.string.sounds_play_cd)
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
    val kindLabel = stringResource(kind.labelRes)
    val stateLabel = stringResource(if (on) R.string.sound_on else R.string.sound_off)
    val stateCd = stringResource(R.string.sound_state_cd, kindLabel, stateLabel)
    val volumeCd = stringResource(R.string.sound_volume_cd, kindLabel)
    Card(
        onClick = onToggle,
        modifier = Modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = false) {
                contentDescription = stateCd
            },
        colors = CardDefaults.cardColors(
            containerColor = if (on) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.surface
        )
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column(Modifier.weight(1f)) {
                    Text(kindLabel, style = MaterialTheme.typography.titleLarge)
                    Text(
                        stringResource(kind.blurbRes),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Text(
                    stateLabel,
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
                        .semantics { contentDescription = volumeCd }
                )
            }
        }
    }
}
