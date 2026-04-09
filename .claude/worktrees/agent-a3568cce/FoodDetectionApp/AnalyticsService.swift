import Foundation
import FirebaseAnalytics

enum AnalyticsService {
    static func logFoodScanned(dish: String, source: String) {
        Analytics.logEvent("food_scanned", parameters: [
            "dish": dish,
            "source": source,
        ])
    }

    static func logFoodLogged(dish: String, calories: Int) {
        Analytics.logEvent("food_logged", parameters: [
            "dish": dish,
            "calories": calories,
        ])
    }

    static func logManualSearch(query: String) {
        Analytics.logEvent("manual_search", parameters: [
            "query": query,
        ])
    }

    static func logCoachQuery(query: String) {
        Analytics.logEvent("coach_query", parameters: [
            "query": query,
        ])
    }

    static func logScaleConnected() {
        Analytics.logEvent("scale_connected", parameters: nil)
    }

    static func logOnboardingComplete() {
        Analytics.logEvent("onboarding_complete", parameters: nil)
    }

    static func logWaterLogged(ml: Int) {
        Analytics.logEvent("water_logged", parameters: [
            "ml": ml,
        ])
    }
}
