@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * Mirrors iOS Views/HomeView.swift: hub linking to Bedtime Stories and My Voice.
 *
 * The paywall gate (iOS's "Go Premium" card / launch-cadence triggers) is deliberately NOT
 * wired into this flow for initial launch -- billing is skipped entirely so users get full
 * access to stories and voice features. PaywallScreen.kt still exists (unused) for when
 * billing is reintroduced; see Routes.kt / NavGraph.kt.
 */
@Composable
fun HomeScreen(
    onOpenStories: () -> Unit,
    onOpenMyVoice: () -> Unit
) {
    Scaffold(
        topBar = { TopAppBar(title = { Text("Lullaby Haven") }) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            HomeCard("Bedtime Stories", "Calm original stories, narrated in a preset or your own voice.", onOpenStories)
            HomeCard("My Voice", "Clone your voice and generate lullabies that sound like you.", onOpenMyVoice)
        }
    }
}

@Composable
private fun HomeCard(title: String, subtitle: String, onClick: () -> Unit) {
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, style = MaterialTheme.typography.titleLarge)
            Text(subtitle, style = MaterialTheme.typography.bodyMedium)
        }
    }
}
