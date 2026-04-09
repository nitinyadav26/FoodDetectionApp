import Foundation
import Combine

class BadgeManager: ObservableObject {
    static let shared = BadgeManager()

    @Published var unlockedBadgeKeys: Set<String> = []

    private let storageKey = "badge_unlockedKeys"

    var earnedCount: Int { unlockedBadgeKeys.count }
    var totalCount: Int { BadgeDefinition.allBadges.count }

    init() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            unlockedBadgeKeys = Set(saved)
        }
    }

    // MARK: - Persistence

    private func save() {
        UserDefaults.standard.set(Array(unlockedBadgeKeys), forKey: storageKey)
    }

    // MARK: - Unlock

    func unlock(_ badgeID: String) {
        guard !unlockedBadgeKeys.contains(badgeID) else { return }
        unlockedBadgeKeys.insert(badgeID)
        save()
        // Award XP for earning a badge
        XPManager.shared.awardXP(amount: 25, action: "badge_\(badgeID)")
    }

    func isUnlocked(_ badgeID: String) -> Bool {
        unlockedBadgeKeys.contains(badgeID)
    }

    // MARK: - Top earned badges (for dashboard display)

    func topEarnedBadges(count: Int = 3) -> [BadgeDefinition] {
        BadgeDefinition.allBadges.filter { unlockedBadgeKeys.contains($0.id) }.prefix(count).map { $0 }
    }

    // MARK: - Check All Badge Conditions

    func checkBadges() {
        let streak = StreakManager.shared.longestStreak
        let logCount = NutritionManager.shared.logs.count
        let nutritionManager = NutritionManager.shared
        let calorieBudget = nutritionManager.calorieBudget

        // ── Streak badges ──
        let streakThresholds = [3, 7, 14, 21, 30, 60, 90, 120, 180, 365]
        for t in streakThresholds {
            if streak >= t { unlock("streak_\(t)") }
        }

        // ── Logging badges ──
        let logThresholds = [1, 10, 25, 50, 100, 250, 500, 750, 1000, 2000]
        for t in logThresholds {
            if logCount >= t { unlock("log_\(t)") }
        }

        // ── Nutrition badges ──
        let todaySummary = nutritionManager.todaySummary
        // Hit calorie target (within 10%)
        if calorieBudget > 0 {
            let ratio = Double(todaySummary.cals) / Double(calorieBudget)
            if ratio >= 0.9 && ratio <= 1.1 && todaySummary.cals > 0 {
                unlock("nut_cal_target")
            }
            // Under budget
            if todaySummary.cals > 0 && todaySummary.cals < calorieBudget {
                unlock("nut_under_budget")
            }
        }

        // Protein over 100g today
        if todaySummary.protein >= 100 {
            unlock("nut_protein_100")
        }

        // Balanced meal (all macros > 0)
        if todaySummary.protein > 0 && todaySummary.carbs > 0 && todaySummary.fats > 0 {
            unlock("nut_balanced_meal")
        }

        // Variety: 10+ unique foods logged ever
        let uniqueFoods = Set(nutritionManager.logs.map { $0.food })
        if uniqueFoods.count >= 10 { unlock("nut_variety_10") }
        if uniqueFoods.count >= 25 { unlock("nut_variety_25") }

        // Profile completed
        if nutritionManager.userStats != nil {
            unlock("sp_profile_done")
        }

        // Level 50
        if XPManager.shared.level >= 50 {
            unlock("sp_level_50")
        }

        // ── Social badges ── (stub: always false for now)
        // These require social features to be implemented.

        // ── Challenge badges ── (basic checks)
        // First challenge badge is awarded on first log
        if logCount >= 1 {
            unlock("ch_first")
        }

        // Early bird: logged food before 8 AM
        let calendar = Calendar.current
        if nutritionManager.logs.contains(where: { calendar.component(.hour, from: $0.time) < 8 }) {
            unlock("ch_early_bird")
        }

        // Night owl: logged food after 10 PM
        if nutritionManager.logs.contains(where: { calendar.component(.hour, from: $0.time) >= 22 }) {
            unlock("ch_night_owl")
        }

        // Special: first scan (log_1 also covers this, but explicit)
        if logCount >= 1 {
            unlock("sp_first_scan")
        }
    }
}
