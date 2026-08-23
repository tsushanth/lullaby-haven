@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.myvoice

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.kreativekoala.lullabyhaven.domain.model.SavedVoice

/** Mirrors iOS Views/MyVoice/MyVoiceView.swift: hub for cloned parent voices. */
@Composable
fun MyVoiceScreen(
    onRecordVoice: () -> Unit,
    onVoiceClick: (SavedVoice) -> Unit,
    viewModel: MyVoiceViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadVoices() }

    Scaffold(
        topBar = { TopAppBar(title = { Text("My Voice") }) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            Text(
                "Record a short voice sample and we'll generate lullabies that sound just like you.",
                style = MaterialTheme.typography.bodyMedium
            )
            Button(
                onClick = onRecordVoice,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp)
            ) {
                Text("Clone My Voice")
            }

            when {
                uiState.isLoading -> CircularProgressIndicator(modifier = Modifier.padding(top = 24.dp))
                uiState.error != null -> Text(
                    uiState.error.orEmpty(),
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(top = 24.dp)
                )
                uiState.voices.isEmpty() -> Text(
                    "No voices yet.",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(top = 24.dp)
                )
                else -> LazyColumn(
                    contentPadding = PaddingValues(top = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.voices, key = { it.id }) { voice ->
                        Card(
                            onClick = { onVoiceClick(voice) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text(voice.name, style = MaterialTheme.typography.titleLarge)
                                voice.description?.let {
                                    Text(it, style = MaterialTheme.typography.bodyMedium)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
