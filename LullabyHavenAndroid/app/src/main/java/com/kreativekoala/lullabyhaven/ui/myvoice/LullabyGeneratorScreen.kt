@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.myvoice

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * Mirrors iOS Views/MyVoice/LullabyGeneratorView.swift: pick a story/lullaby text and generate
 * narration in a chosen cloned voice.
 *
 * TODO(backend wiring): "Generate" should POST /api/tts/job-cloned with { voice_id, text },
 * poll GET /api/tts/job/{id}, then hand the resulting audio_url to PlayerManager. Not wired
 * yet -- this screen is a real, navigable placeholder for that flow.
 */
@Composable
fun LullabyGeneratorScreen(
    voiceId: String,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Generate Lullaby") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding).padding(24.dp)) {
            Text(
                "Generating lullabies in voice \"$voiceId\" isn't wired up to the backend yet.",
                style = MaterialTheme.typography.bodyLarge
            )
            Button(onClick = { /* TODO: call VoiceApi.createClonedTtsJob + poll */ }) {
                Text("Generate (not yet wired)")
            }
        }
    }
}
