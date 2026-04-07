package com.foodsense.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.R
import com.foodsense.android.data.LeaderboardEntry
import com.foodsense.android.services.SocialManager
import kotlinx.coroutines.launch

@Composable
fun LeaderboardScreen(socialManager: SocialManager) {
    val scope = rememberCoroutineScope()
    val entries by socialManager.leaderboard
    val isLoading by socialManager.isLoading
    var selectedScope by rememberSaveable { mutableStateOf(0) }

    val scopeLabels = listOf(
        stringResource(R.string.social_weekly),
        stringResource(R.string.social_monthly),
        stringResource(R.string.social_all_time),
    )
    val scopeValues = listOf("weekly", "monthly", "all_time")

    LaunchedEffect(selectedScope) {
        socialManager.loadLeaderboard(scopeValues[selectedScope])
    }

    Column(modifier = Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = selectedScope) {
            scopeLabels.forEachIndexed { index, title ->
                Tab(
                    selected = selectedScope == index,
                    onClick = {
                        selectedScope = index
                        scope.launch { socialManager.loadLeaderboard(scopeValues[index]) }
                    },
                    text = { Text(title, maxLines = 1) },
                )
            }
        }

        if (isLoading && entries.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (entries.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    text = stringResource(R.string.social_no_leaderboard),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                item { Spacer(Modifier.height(8.dp)) }

                // Top 3 Podium
                val topThree = entries.take(3)
                if (topThree.isNotEmpty()) {
                    item {
                        PodiumSection(topThree)
                    }
                    item { Spacer(Modifier.height(8.dp)) }
                }

                // Remaining entries
                val rest = entries.drop(3)
                items(rest, key = { it.userId }) { entry ->
                    RankedRow(entry)
                }

                item { Spacer(Modifier.height(16.dp)) }
            }
        }
    }
}

@Composable
private fun PodiumSection(topThree: List<LeaderboardEntry>) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.Bottom,
    ) {
        // 2nd place (left)
        if (topThree.size >= 2) {
            PodiumItem(topThree[1], height = 100, medal = "\uD83E\uDD48")
        }
        // 1st place (center)
        if (topThree.isNotEmpty()) {
            PodiumItem(topThree[0], height = 130, medal = "\uD83E\uDD47")
        }
        // 3rd place (right)
        if (topThree.size >= 3) {
            PodiumItem(topThree[2], height = 80, medal = "\uD83E\uDD49")
        }
    }
}

@Composable
private fun PodiumItem(entry: LeaderboardEntry, height: Int, medal: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(90.dp),
    ) {
        Text(medal, fontSize = 28.sp)
        Spacer(Modifier.height(4.dp))
        AvatarPlaceholder(entry.displayName)
        Spacer(Modifier.height(4.dp))
        Text(
            entry.displayName,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center,
            maxLines = 1,
        )
        Text(
            "${entry.score} pts",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(4.dp))
        Box(
            modifier = Modifier
                .width(60.dp)
                .height(height.dp)
                .clip(RoundedCornerShape(topStart = 8.dp, topEnd = 8.dp))
                .background(
                    if (entry.isCurrentUser) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.primaryContainer
                ),
        )
    }
}

@Composable
private fun RankedRow(entry: LeaderboardEntry) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = if (entry.isCurrentUser) {
            CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
        } else {
            CardDefaults.cardColors()
        },
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "#${entry.rank}",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.width(40.dp),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            AvatarPlaceholder(entry.displayName)
            Spacer(Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(entry.displayName, fontWeight = FontWeight.Medium)
                Text(
                    stringResource(R.string.social_streak_days, entry.streak),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(
                "${entry.score} pts",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
            )
        }
    }
}
