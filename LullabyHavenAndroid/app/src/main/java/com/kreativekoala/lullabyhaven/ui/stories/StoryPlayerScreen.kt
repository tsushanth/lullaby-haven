@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.stories

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedButton
import com.kreativekoala.lullabyhaven.ui.night.formatCountdown
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

/**
 * Mirrors iOS Views/BedtimeStories/StoryPlayerView.swift.
 *
 * Playback transport is real (Media3/ExoPlayer via [StoryPlayerViewModel]). The audio *source*
 * is real narrated audio fetched from listenai-backend's synchronous TTS endpoint
 * (POST /api/tts, Kokoro self-hosted voice) -- see StoryPlayerViewModel.playStory() and
 * StoryNarrationRepository. If that fetch fails (network, quota, backend down), this screen
 * shows an honest "Narration unavailable" state rather than faking playback.
 */
@Composable
fun StoryPlayerScreen(
    storyId: String,
    onBack: () -> Unit,
    viewModel: StoryPlayerViewModel = hiltViewModel()
) {
    val story = viewModel.story(storyId)
    val playbackState by viewModel.playbackState.collectAsState()
    val narrationState by viewModel.narrationState.collectAsState()
    val timer by viewModel.timerState.collectAsState()

    LaunchedEffect(storyId) {
        viewModel.playStory(storyId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(story?.title ?: "Story") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            story?.let {
                Text(it.summary, style = MaterialTheme.typography.bodyMedium)
                Text(
                    it.body,
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.padding(top = 16.dp)
                )
            }

            when (narrationState.status) {
                NarrationStatus.LOADING -> {
                    CircularProgressIndicator(modifier = Modifier.padding(top = 24.dp))
                    Text(
                        "Preparing narration…",
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
                NarrationStatus.FAILED -> {
                    Text(
                        "Narration coming soon — we couldn't reach the narration service right now.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(top = 24.dp)
                    )
                }
                NarrationStatus.READY -> {
                    Slider(
                        value = if (playbackState.durationMs > 0) {
                            playbackState.positionMs.toFloat() / playbackState.durationMs.toFloat()
                        } else 0f,
                        onValueChange = { fraction ->
                            if (playbackState.durationMs > 0) {
                                viewModel.seekTo((fraction * playbackState.durationMs).toLong())
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 24.dp)
                    )

                    FilledIconButton(
                        onClick = { viewModel.togglePlayPause() },
                        modifier = Modifier
                            .padding(top = 8.dp)
                            .size(72.dp)
                    ) {
                        Icon(
                            imageVector = if (playbackState.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                            contentDescription = if (playbackState.isPlaying) "Pause" else "Play",
                            modifier = Modifier.size(40.dp)
                        )
                    }
                    Text(
                        if (timer.active) "Sleep timer: ${formatCountdown(timer.remainingMs)}" else "Sleep timer",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 16.dp)
                    )
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.padding(top = 8.dp)
                    ) {
                        listOf(15, 30, 45).forEach { m ->
                            FilterChip(
                                selected = timer.active && timer.totalMs == m * 60_000L,
                                onClick = { viewModel.startTimer(m) },
                                label = { Text("$m min") }
                            )
                        }
                        if (timer.active) {
                            OutlinedButton(onClick = viewModel::cancelTimer) { Text("Off") }
                        }
                    }
                }
            }
        }
    }
}
