package com.foodsense.android.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.foodsense.android.R
import com.foodsense.android.data.Challenge
import com.foodsense.android.services.SocialManager
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun ChallengesScreen(socialManager: SocialManager) {
    val scope = rememberCoroutineScope()
    val challenges by socialManager.challenges
    val isLoading by socialManager.isLoading
    var selectedTab by rememberSaveable { mutableStateOf(0) }
    var showCreateSheet by remember { mutableStateOf(false) }

    val tabTitles = listOf(
        stringResource(R.string.social_active),
        stringResource(R.string.social_available),
        stringResource(R.string.social_completed),
    )

    LaunchedEffect(Unit) {
        socialManager.loadChallenges()
    }

    val filteredChallenges = when (selectedTab) {
        0 -> challenges.filter { it.status == "active" }
        1 -> challenges.filter { it.status == "available" }
        2 -> challenges.filter { it.status == "completed" }
        else -> challenges
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            TabRow(selectedTabIndex = selectedTab) {
                tabTitles.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = { Text(title, maxLines = 1) },
                    )
                }
            }

            if (isLoading && challenges.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else if (filteredChallenges.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        text = stringResource(R.string.social_no_challenges),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    item { Spacer(Modifier.height(8.dp)) }

                    items(filteredChallenges, key = { it.id }) { challenge ->
                        ChallengeCard(
                            challenge = challenge,
                            onJoin = {
                                scope.launch { socialManager.joinChallenge(challenge.id) }
                            },
                        )
                    }

                    item { Spacer(Modifier.height(80.dp)) }
                }
            }
        }

        FloatingActionButton(
            onClick = { showCreateSheet = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp),
        ) {
            Icon(Icons.Default.Add, contentDescription = stringResource(R.string.social_create_challenge))
        }
    }

    if (showCreateSheet) {
        CreateChallengeDialog(
            socialManager = socialManager,
            onDismiss = { showCreateSheet = false },
        )
    }
}

@Composable
private fun ChallengeCard(challenge: Challenge, onJoin: () -> Unit) {
    val dateFormat = remember { SimpleDateFormat("MMM d", Locale.getDefault()) }
    val progress = if (challenge.targetValue > 0) {
        (challenge.currentValue.toFloat() / challenge.targetValue).coerceIn(0f, 1f)
    } else 0f

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                val typeIcon = when (challenge.type) {
                    "calories" -> "\uD83D\uDD25"
                    "protein" -> "\uD83E\uDD69"
                    "streak" -> "\u26A1"
                    "steps" -> "\uD83D\uDEB6"
                    else -> "\uD83C\uDFC6"
                }
                Text(typeIcon, style = MaterialTheme.typography.headlineSmall)
                Spacer(Modifier.width(10.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(challenge.title, fontWeight = FontWeight.SemiBold)
                    Text(
                        challenge.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            Spacer(Modifier.height(12.dp))

            // Progress bar
            if (challenge.status == "active") {
                LinearProgressIndicator(
                    progress = progress,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp),
                    trackColor = MaterialTheme.colorScheme.surfaceVariant,
                )
                Text(
                    "${challenge.currentValue} / ${challenge.targetValue}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp),
                )
            }

            Spacer(Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    stringResource(R.string.social_participants, challenge.participantCount),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Text(
                    "${dateFormat.format(Date(challenge.startDate))} - ${dateFormat.format(Date(challenge.endDate))}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            if (challenge.status == "available" && !challenge.isJoined) {
                Spacer(Modifier.height(8.dp))
                Button(
                    onClick = onJoin,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(stringResource(R.string.social_join_challenge))
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CreateChallengeDialog(socialManager: SocialManager, onDismiss: () -> Unit) {
    val scope = rememberCoroutineScope()
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf("calories") }
    var targetValue by remember { mutableStateOf("") }
    var durationDays by remember { mutableStateOf("7") }
    var typeExpanded by remember { mutableStateOf(false) }

    val challengeTypes = listOf("calories", "protein", "streak", "steps")

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.social_create_challenge)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text(stringResource(R.string.social_challenge_title)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text(stringResource(R.string.social_challenge_description)) },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3,
                )
                ExposedDropdownMenuBox(
                    expanded = typeExpanded,
                    onExpandedChange = { typeExpanded = !typeExpanded },
                ) {
                    OutlinedTextField(
                        value = selectedType,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text(stringResource(R.string.social_challenge_type)) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(),
                    )
                    ExposedDropdownMenu(expanded = typeExpanded, onDismissRequest = { typeExpanded = false }) {
                        challengeTypes.forEach { type ->
                            DropdownMenuItem(
                                text = { Text(type) },
                                onClick = { selectedType = type; typeExpanded = false },
                            )
                        }
                    }
                }
                OutlinedTextField(
                    value = targetValue,
                    onValueChange = { targetValue = it },
                    label = { Text(stringResource(R.string.social_target_value)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = durationDays,
                    onValueChange = { durationDays = it },
                    label = { Text(stringResource(R.string.social_duration_days)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    scope.launch {
                        socialManager.createChallenge(
                            title = title,
                            description = description,
                            type = selectedType,
                            targetValue = targetValue.toIntOrNull() ?: 0,
                            durationDays = durationDays.toIntOrNull() ?: 7,
                        )
                        onDismiss()
                    }
                },
                enabled = title.isNotBlank() && targetValue.isNotBlank(),
            ) {
                Text(stringResource(R.string.social_create))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) }
        },
    )
}
