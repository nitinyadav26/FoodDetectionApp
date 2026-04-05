package com.foodsense.android.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate
import kotlin.math.max

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChipSelector(options: List<String>, selected: String, onSelect: (String) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        items(options) { option ->
            FilterChip(
                selected = selected == option,
                onClick = { onSelect(option) },
                label = { Text(option) },
            )
        }
    }
}

@Composable
fun StatRing(label: String, value: Int, target: Int, color: Color) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.semantics { contentDescription = "$label: $value of $target" },
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.size(54.dp)) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                drawCircle(color = color.copy(alpha = 0.25f), style = Stroke(width = 8f))
                val sweep = max(0.02f, (value.toFloat() / max(1, target)).coerceAtMost(1f)) * 360f
                drawArc(
                    color = color,
                    startAngle = -90f,
                    sweepAngle = sweep,
                    useCenter = false,
                    style = Stroke(width = 8f),
                )
            }
            Text(value.toString(), fontSize = 11.sp, fontWeight = FontWeight.Bold)
        }
        Text(label, color = Color.Gray, fontSize = 11.sp)
    }
}

@Composable
fun MacroRing(label: String, value: String, color: Color) {
    val parsed = value.filter { it.isDigit() || it == '.' }.ifBlank { "0" }
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.semantics { contentDescription = "$label: $parsed" },
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.size(56.dp)) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                drawCircle(color.copy(alpha = 0.24f), style = Stroke(6f))
                drawArc(color, -90f, 250f, false, style = Stroke(6f))
            }
            Text(parsed, fontSize = 11.sp, fontWeight = FontWeight.Bold)
        }
        Text(label, color = Color.Gray, fontSize = 11.sp)
    }
}

@Composable
fun HealthCard(title: String, value: String, color: Color, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier.semantics { contentDescription = "$title: $value" },
        colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1E1E)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(title, color = color, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
            Text(value, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        }
    }
}

@Composable
fun DateSlider(selectedDate: LocalDate, onSelectDate: (LocalDate) -> Unit) {
    val dates = remember {
        (0..29).map { LocalDate.now().minusDays(it.toLong()) }
    }

    LazyRow(
        modifier = Modifier.padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(dates) { date ->
            val isSelected = date == selectedDate
            val isToday = date == LocalDate.now()
            val bg = when {
                isSelected -> Color(0xFF4FC3F7)
                isToday -> Color(0x334FC3F7)
                else -> Color(0xFF1A1A1A)
            }
            val fg = when {
                isSelected -> Color.White
                isToday -> Color(0xFF4FC3F7)
                else -> Color.LightGray
            }

            Column(
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .background(bg)
                    .clickable { onSelectDate(date) }
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(date.dayOfWeek.name.take(3), color = fg, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                Text(date.dayOfMonth.toString(), color = fg, fontWeight = FontWeight.Bold)
            }
        }
    }
}
