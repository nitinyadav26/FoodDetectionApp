package com.foodsense.android.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SuggestionChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.foodsense.android.R
import com.foodsense.android.data.FeedPost
import com.foodsense.android.services.SocialManager
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val REACTION_EMOJIS = listOf("\uD83D\uDC4D", "\u2764\uFE0F", "\uD83D\uDD25", "\uD83C\uDF89", "\uD83D\uDCAA")

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun FeedScreen(socialManager: SocialManager) {
    val scope = rememberCoroutineScope()
    val posts by socialManager.feedPosts
    val isLoading by socialManager.isLoading

    LaunchedEffect(Unit) {
        socialManager.loadFeed()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        if (isLoading && posts.isEmpty()) {
            CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
        } else if (posts.isEmpty()) {
            Text(
                text = stringResource(R.string.social_no_posts),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(32.dp),
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item { Spacer(Modifier.height(8.dp)) }

                items(posts, key = { it.id }) { post ->
                    FeedCard(post = post, onReact = { emoji ->
                        scope.launch { socialManager.reactToPost(post.id, emoji) }
                    })
                }

                item { Spacer(Modifier.height(16.dp)) }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FeedCard(post: FeedPost, onReact: (String) -> Unit) {
    val dateFormat = remember { SimpleDateFormat("MMM d, h:mm a", Locale.getDefault()) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header
            Row(verticalAlignment = Alignment.CenterVertically) {
                AvatarPlaceholder(post.displayName)
                Spacer(Modifier.width(10.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(post.displayName, fontWeight = FontWeight.SemiBold)
                    Text(
                        dateFormat.format(Date(post.timestamp)),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                PostTypeBadge(post.type)
            }

            Spacer(Modifier.height(10.dp))

            // Content
            Text(post.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Medium)
            if (post.description.isNotEmpty()) {
                Text(
                    post.description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp),
                )
            }

            if (post.calories > 0) {
                Text(
                    "${post.calories} kcal",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(top = 4.dp),
                )
            }

            Spacer(Modifier.height(10.dp))

            // Reactions
            FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                REACTION_EMOJIS.forEach { emoji ->
                    val count = post.reactions[emoji] ?: 0
                    val isSelected = post.myReaction == emoji
                    SuggestionChip(
                        onClick = { onReact(emoji) },
                        label = {
                            Text(
                                if (count > 0) "$emoji $count" else emoji,
                                style = MaterialTheme.typography.bodySmall,
                            )
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun PostTypeBadge(type: String) {
    val label = when (type) {
        "meal" -> "\uD83C\uDF7D"
        "milestone" -> "\uD83C\uDFC6"
        "challenge_complete" -> "\u2705"
        "streak" -> "\uD83D\uDD25"
        else -> "\uD83D\uDCDD"
    }
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.tertiaryContainer,
        ),
        shape = RoundedCornerShape(8.dp),
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
        )
    }
}
