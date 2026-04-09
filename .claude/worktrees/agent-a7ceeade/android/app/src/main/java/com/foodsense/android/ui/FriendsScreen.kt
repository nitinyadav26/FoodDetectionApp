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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.foodsense.android.R
import com.foodsense.android.services.SocialManager
import kotlinx.coroutines.launch

@Composable
fun FriendsScreen(socialManager: SocialManager) {
    val scope = rememberCoroutineScope()
    val friends by socialManager.friends
    val requests by socialManager.friendRequests
    val isLoading by socialManager.isLoading
    var showAddDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        socialManager.loadFriends()
        socialManager.loadFriendRequests()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        if (isLoading && friends.isEmpty() && requests.isEmpty()) {
            CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                // Pending requests section
                if (requests.isNotEmpty()) {
                    item {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            text = stringResource(R.string.social_pending_requests),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                    items(requests, key = { it.id }) { request ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.secondaryContainer,
                            ),
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                AvatarPlaceholder(request.fromDisplayName)
                                Spacer(Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(request.fromDisplayName, fontWeight = FontWeight.Medium)
                                    Text(
                                        stringResource(R.string.social_wants_to_connect),
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    )
                                }
                                IconButton(onClick = {
                                    scope.launch { socialManager.acceptFriendRequest(request.id) }
                                }) {
                                    Icon(Icons.Default.Check, contentDescription = stringResource(R.string.social_accept),
                                        tint = MaterialTheme.colorScheme.primary)
                                }
                                IconButton(onClick = {
                                    scope.launch { socialManager.rejectFriendRequest(request.id) }
                                }) {
                                    Icon(Icons.Default.Close, contentDescription = stringResource(R.string.social_decline),
                                        tint = MaterialTheme.colorScheme.error)
                                }
                            }
                        }
                    }
                }

                // Friends list section
                item {
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = stringResource(R.string.social_friends_count, friends.size),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                    )
                }

                if (friends.isEmpty()) {
                    item {
                        Text(
                            text = stringResource(R.string.social_no_friends),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 24.dp),
                        )
                    }
                }

                items(friends, key = { it.id }) { friend ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            AvatarPlaceholder(friend.displayName)
                            Spacer(Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(friend.displayName, fontWeight = FontWeight.Medium)
                                Text(
                                    stringResource(R.string.social_streak_days, friend.streak),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    "${friend.todayCalories} kcal",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.primary,
                                )
                            }
                        }
                    }
                }

                item { Spacer(Modifier.height(80.dp)) }
            }
        }

        FloatingActionButton(
            onClick = { showAddDialog = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp),
        ) {
            Icon(Icons.Default.PersonAdd, contentDescription = stringResource(R.string.social_add_friend))
        }
    }

    if (showAddDialog) {
        AddFriendDialog(
            socialManager = socialManager,
            onDismiss = { showAddDialog = false },
        )
    }
}

@Composable
private fun AddFriendDialog(socialManager: SocialManager, onDismiss: () -> Unit) {
    val scope = rememberCoroutineScope()
    var query by remember { mutableStateOf("") }
    val results by socialManager.searchResults

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.social_add_friend)) },
        text = {
            Column {
                OutlinedTextField(
                    value = query,
                    onValueChange = {
                        query = it
                        if (it.length >= 2) {
                            scope.launch { socialManager.searchUsers(it) }
                        }
                    },
                    label = { Text(stringResource(R.string.social_search_users)) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                Spacer(Modifier.height(8.dp))
                results.forEach { user ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        AvatarPlaceholder(user.displayName)
                        Spacer(Modifier.width(8.dp))
                        Text(user.displayName, modifier = Modifier.weight(1f))
                        IconButton(onClick = {
                            scope.launch {
                                socialManager.sendFriendRequest(user.id)
                                onDismiss()
                            }
                        }) {
                            Icon(Icons.Default.PersonAdd, contentDescription = stringResource(R.string.social_add_friend),
                                tint = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) }
        },
    )
}

@Composable
fun AvatarPlaceholder(name: String) {
    val initial = name.firstOrNull()?.uppercase() ?: "?"
    Box(
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .then(
                Modifier.padding(0.dp)
            ),
        contentAlignment = Alignment.Center,
    ) {
        Card(
            modifier = Modifier.fillMaxSize(),
            shape = CircleShape,
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer,
            ),
        ) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    text = initial,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            }
        }
    }
}
