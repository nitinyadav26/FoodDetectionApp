package com.foodsense.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.foodsense.android.FoodSenseApplication
import com.foodsense.android.data.AllBadges
import com.foodsense.android.data.BadgeCategory
import com.foodsense.android.data.BadgeDefinition

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BadgesScreen(app: FoodSenseApplication, onBack: () -> Unit) {
    val badgeManager = app.badgeManager
    val xpManager = app.xpManager
    val unlockedKeys = badgeManager.unlockedKeys
    val categories = BadgeCategory.values()
    var selectedTab by rememberSaveable { mutableStateOf(0) }
    var selectedBadge by remember { mutableStateOf<BadgeDefinition?>(null) }

    // Trigger badge evaluation when screen opens
    remember {
        badgeManager.evaluate()
        true
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Back")
            }
            Text("Badges & XP", fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.weight(1f))
            Text(
                "${badgeManager.unlockedCount}/${AllBadges.list.size}",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                fontSize = 14.sp,
            )
        }

        // XP Bar
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        "Lv ${xpManager.level}",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = Color(0xFFFFD700),
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        xpManager.title,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        "${xpManager.totalXP} XP",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontSize = 13.sp,
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                LinearProgressIndicator(
                    progress = xpManager.progress,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = Color(0xFFFFD700),
                    trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    "${xpManager.currentLevelXP} / ${xpManager.xpToNextLevel} XP to next level",
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Category tabs
        ScrollableTabRow(
            selectedTabIndex = selectedTab,
            modifier = Modifier.fillMaxWidth(),
            edgePadding = 8.dp,
        ) {
            categories.forEachIndexed { index, category ->
                val count = AllBadges.byCategory[category]?.count { it.key in unlockedKeys } ?: 0
                val total = AllBadges.byCategory[category]?.size ?: 0
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = { Text("${category.label} ($count/$total)", fontSize = 12.sp) },
                )
            }
        }

        // Badge grid
        val currentCategory = categories[selectedTab]
        val badges = AllBadges.byCategory[currentCategory] ?: emptyList()

        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(12.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(badges, key = { it.key }) { badge ->
                val isUnlocked = badge.key in unlockedKeys
                BadgeCard(
                    badge = badge,
                    isUnlocked = isUnlocked,
                    onClick = { selectedBadge = badge },
                )
            }
        }
    }

    // Bottom sheet detail
    if (selectedBadge != null) {
        val badge = selectedBadge!!
        val isUnlocked = badge.key in unlockedKeys
        val sheetState = rememberModalBottomSheetState()

        ModalBottomSheet(
            onDismissRequest = { selectedBadge = null },
            sheetState = sheetState,
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    badgeIcon(badge.icon),
                    fontSize = 48.sp,
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    badge.name,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                    color = MaterialTheme.colorScheme.onSurface,
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    badge.category.label,
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    badge.description,
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurface,
                )
                Spacer(modifier = Modifier.height(16.dp))
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(
                            if (isUnlocked) Color(0xFF1DB954).copy(alpha = 0.15f)
                            else MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.3f),
                        )
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                ) {
                    Text(
                        if (isUnlocked) "Unlocked (+25 XP)" else "Locked",
                        fontWeight = FontWeight.SemiBold,
                        color = if (isUnlocked) Color(0xFF1DB954) else MaterialTheme.colorScheme.error,
                    )
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
fun BadgeCard(badge: BadgeDefinition, isUnlocked: Boolean, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .alpha(if (isUnlocked) 1f else 0.5f)
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = if (isUnlocked) MaterialTheme.colorScheme.secondaryContainer
            else MaterialTheme.colorScheme.surfaceVariant,
        ),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (isUnlocked) {
                Text(badgeIcon(badge.icon), fontSize = 28.sp)
            } else {
                Icon(
                    Icons.Default.Lock,
                    contentDescription = "Locked",
                    modifier = Modifier.size(28.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                badge.name,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.onSurface,
            )
        }
    }
}

/** Map icon name to emoji for display */
fun badgeIcon(icon: String): String = when (icon) {
    "flame" -> "\uD83D\uDD25"
    "star" -> "\u2B50"
    "trophy" -> "\uD83C\uDFC6"
    "utensils" -> "\uD83C\uDF7D"
    "target" -> "\uD83C\uDFAF"
    "muscle" -> "\uD83D\uDCAA"
    "plate" -> "\uD83C\uDF7D"
    "leaf" -> "\uD83C\uDF3F"
    "rainbow" -> "\uD83C\uDF08"
    "sparkle" -> "\u2728"
    "droplet" -> "\uD83D\uDCA7"
    "shoe" -> "\uD83D\uDC5F"
    "moon" -> "\uD83C\uDF19"
    "fire" -> "\uD83D\uDD25"
    "heart" -> "\u2764\uFE0F"
    "share" -> "\uD83D\uDD17"
    "users" -> "\uD83D\uDC65"
    "pencil" -> "\u270F\uFE0F"
    "mail" -> "\uD83D\uDCE7"
    "globe" -> "\uD83C\uDF0D"
    "crown" -> "\uD83D\uDC51"
    "medal" -> "\uD83C\uDFC5"
    else -> "\uD83C\uDFC5"
}
