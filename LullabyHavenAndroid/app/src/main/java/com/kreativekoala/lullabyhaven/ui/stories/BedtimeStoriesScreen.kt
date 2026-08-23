@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
package com.kreativekoala.lullabyhaven.ui.stories

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.kreativekoala.lullabyhaven.domain.model.BedtimeStory

@Composable
fun BedtimeStoriesScreen(
    onStoryClick: (String) -> Unit,
    viewModel: StoriesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Bedtime Stories") }) }
    ) { padding ->
        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .padding(padding)
        ) {
            items(uiState.stories, key = { it.id }) { story ->
                StoryCard(
                    story = story,
                    isFavorite = uiState.favoriteIds.contains(story.id),
                    onClick = { onStoryClick(story.id) },
                    onToggleFavorite = { viewModel.toggleFavorite(story.id, !uiState.favoriteIds.contains(story.id)) }
                )
            }
        }
    }
}

@Composable
private fun StoryCard(
    story: BedtimeStory,
    isFavorite: Boolean,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.padding(end = 8.dp)) {
                Text(story.title, style = androidx.compose.material3.MaterialTheme.typography.titleLarge)
                Text(story.summary, style = androidx.compose.material3.MaterialTheme.typography.bodyMedium)
                Text(
                    "${story.ageRangeDescription} · ${story.estimatedMinutes} min",
                    style = androidx.compose.material3.MaterialTheme.typography.labelSmall
                )
            }
            IconButton(onClick = onToggleFavorite) {
                Icon(
                    imageVector = if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                    contentDescription = if (isFavorite) "Remove favorite" else "Add favorite"
                )
            }
        }
    }
}
