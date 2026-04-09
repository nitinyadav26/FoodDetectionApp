package com.foodsense.android.services

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.foodsense.android.R
import java.util.Calendar

object NotificationHelper {

    private const val CHANNEL_ID = "meal_reminders"
    private const val CHANNEL_NAME = "Meal Reminders"

    private const val REQUEST_BREAKFAST = 1001
    private const val REQUEST_LUNCH = 1002
    private const val REQUEST_DINNER = 1003
    private const val REQUEST_SUMMARY = 1004
    private const val REQUEST_HYDRATION_BASE = 2000

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Reminders for meals, hydration, and daily summary"
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun scheduleAllNotifications(context: Context) {
        createNotificationChannel(context)
        cancelAll(context)

        // Breakfast reminder at 8:00 AM
        scheduleDaily(
            context = context,
            requestCode = REQUEST_BREAKFAST,
            hour = 8,
            minute = 0,
            title = "Time for Breakfast!",
            body = "Don't forget to log your morning meal"
        )

        // Lunch reminder at 1:00 PM
        scheduleDaily(
            context = context,
            requestCode = REQUEST_LUNCH,
            hour = 13,
            minute = 0,
            title = "Lunch Time!",
            body = "Log your lunch to stay on track"
        )

        // Dinner reminder at 7:00 PM
        scheduleDaily(
            context = context,
            requestCode = REQUEST_DINNER,
            hour = 19,
            minute = 0,
            title = "Dinner Time!",
            body = "Remember to log your dinner"
        )

        // Hydration reminders every 2 hours from 9 AM to 9 PM
        var hydrationIndex = 0
        for (hour in 9..21 step 2) {
            scheduleDaily(
                context = context,
                requestCode = REQUEST_HYDRATION_BASE + hydrationIndex,
                hour = hour,
                minute = 0,
                title = "Stay Hydrated!",
                body = "Time to drink some water"
            )
            hydrationIndex++
        }

        // Daily summary at 9:00 PM
        scheduleDaily(
            context = context,
            requestCode = REQUEST_SUMMARY,
            hour = 21,
            minute = 0,
            title = "Daily Summary",
            body = "Check your nutrition progress for today"
        )
    }

    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val allRequestCodes = mutableListOf(
            REQUEST_BREAKFAST,
            REQUEST_LUNCH,
            REQUEST_DINNER,
            REQUEST_SUMMARY
        )
        // Hydration request codes
        for (i in 0..6) {
            allRequestCodes.add(REQUEST_HYDRATION_BASE + i)
        }

        for (code in allRequestCodes) {
            val intent = Intent(context, NotificationReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                code,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntent?.let {
                alarmManager.cancel(it)
                it.cancel()
            }
        }
    }

    private fun scheduleDaily(
        context: Context,
        requestCode: Int,
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, NotificationReceiver::class.java).apply {
            putExtra("notification_id", requestCode)
            putExtra("notification_title", title)
            putExtra("notification_body", body)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            // If the time has already passed today, schedule for tomorrow
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pendingIntent
        )
    }
}

class NotificationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra("notification_id", 0)
        val title = intent.getStringExtra("notification_title") ?: return
        val body = intent.getStringExtra("notification_body") ?: return

        NotificationHelper.createNotificationChannel(context)

        val notification = NotificationCompat.Builder(context, "meal_reminders")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        // Check POST_NOTIFICATIONS permission on Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
        }

        NotificationManagerCompat.from(context).notify(notificationId, notification)
    }
}
