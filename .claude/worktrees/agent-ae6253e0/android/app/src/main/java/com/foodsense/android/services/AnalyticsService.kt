package com.foodsense.android.services

import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.ktx.Firebase

object AnalyticsService {
    private val analytics: FirebaseAnalytics by lazy { Firebase.analytics }

    fun logFoodScanned(dish: String, source: String) {
        analytics.logEvent("food_scanned", Bundle().apply {
            putString("dish", dish)
            putString("source", source)
        })
    }

    fun logFoodLogged(dish: String, calories: Int) {
        analytics.logEvent("food_logged", Bundle().apply {
            putString("dish", dish)
            putInt("calories", calories)
        })
    }

    fun logManualSearch(query: String) {
        analytics.logEvent("manual_search", Bundle().apply {
            putString("query", query)
        })
    }

    fun logCoachQuery(query: String) {
        analytics.logEvent("coach_query", Bundle().apply {
            putString("query", query)
        })
    }

    fun logScaleConnected() {
        analytics.logEvent("scale_connected", null)
    }

    fun logOnboardingComplete() {
        analytics.logEvent("onboarding_complete", null)
    }

    fun logWaterLogged(ml: Int) {
        analytics.logEvent("water_logged", Bundle().apply {
            putInt("ml", ml)
        })
    }
}
