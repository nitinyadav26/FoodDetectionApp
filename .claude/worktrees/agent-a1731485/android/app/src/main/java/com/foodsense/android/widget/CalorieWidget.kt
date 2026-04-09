package com.foodsense.android.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.foodsense.android.MainActivity

class CalorieWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences("foodsense", Context.MODE_PRIVATE)
        val todayCals = prefs.getInt("widget_today_cals", 0)
        val budget = prefs.getInt("widget_calorie_budget", 2000)

        provideContent {
            CalorieWidgetContent(todayCals, budget)
        }
    }
}

@Composable
fun CalorieWidgetContent(calories: Int, budget: Int) {
    val remaining = (budget - calories).coerceAtLeast(0)

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(12.dp)
            .background(android.R.color.black)
            .clickable(actionStartActivity<MainActivity>()),
        verticalAlignment = Alignment.CenterVertically,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            "FoodSense",
            style = TextStyle(color = ColorProvider(android.R.color.holo_green_dark), fontSize = 12.sp),
        )
        Spacer(GlanceModifier.height(4.dp))
        Text(
            "$calories / $budget kcal",
            style = TextStyle(color = ColorProvider(android.R.color.white), fontSize = 18.sp, fontWeight = FontWeight.Bold),
        )
        Spacer(GlanceModifier.height(4.dp))
        Text(
            "$remaining kcal remaining",
            style = TextStyle(color = ColorProvider(android.R.color.darker_gray), fontSize = 11.sp),
        )
    }
}

class CalorieWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = CalorieWidget()
}
