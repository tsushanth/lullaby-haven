@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.myvoice

import android.Manifest
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState

/**
 * Mirrors iOS Views/MyVoice/VoiceRecordingView.swift: capture a short voice sample that gets
 * uploaded to the cloned-voice backend. Recording itself is real (MediaRecorder -> real .m4a
 * file). Upload to the backend (VoiceRepository.createVoice + PUT presigned URL + confirm) is
 * still a TODO -- see VoiceRepository.
 */
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun VoiceRecordingScreen(
    onBack: () -> Unit,
    onRecorded: (java.io.File) -> Unit
) {
    val context = LocalContext.current
    val micPermission = rememberPermissionState(Manifest.permission.RECORD_AUDIO)

    var isRecording by remember { mutableStateOf(false) }
    val recorder = remember { VoiceRecorder(context) }

    DisposableEffect(Unit) {
        onDispose { if (isRecording) recorder.cancel() }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Clone My Voice") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (micPermission.status.isGranted) {
                Text(
                    if (isRecording) "Recording… read a sentence or two aloud." else "Tap the mic to start recording a short sample.",
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.padding(bottom = 24.dp)
                )
                IconButton(onClick = {
                    if (isRecording) {
                        val file = recorder.stop()
                        isRecording = false
                        if (file != null) onRecorded(file)
                    } else {
                        recorder.start()
                        isRecording = true
                    }
                }) {
                    Icon(
                        imageVector = if (isRecording) Icons.Filled.Stop else Icons.Filled.Mic,
                        contentDescription = if (isRecording) "Stop recording" else "Start recording",
                        modifier = Modifier.padding(16.dp)
                    )
                }
            } else {
                Text(
                    "Lullaby Haven needs microphone access to record your voice sample.",
                    style = MaterialTheme.typography.bodyLarge
                )
                IconButton(onClick = { micPermission.launchPermissionRequest() }) {
                    Icon(Icons.Filled.Mic, contentDescription = "Grant microphone access")
                }
            }
        }
    }
}
