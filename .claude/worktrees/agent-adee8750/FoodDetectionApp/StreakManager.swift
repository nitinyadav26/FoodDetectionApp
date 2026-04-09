import Foundation
import Combine

class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0

    private let longestStreakKey = "longestStreak"

    init() {
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        updateStreak()
    }

    /// Recalculate the current streak from NutritionManager logs.
    func updateStreak() {
        let logs = NutritionManager.shared.logs
        currentStreak = Self.calculateStreak(from: logs)

        if currentStreak > longestStreak {
            longestStreak = currentStreak
            UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        }

        BadgeManager.shared.checkBadges()
    }

    // MARK: - Streak Calculation

    /// Walk backwards from today and count consecutive days that have at least one log.
    static func calculateStreak(from logs: [NutritionManager.FoodLog]) -> Int {
        let calendar = Calendar.current

        // Build a set of unique logged days (normalised to start-of-day).
        let loggedDays: Set<Date> = Set(logs.map { calendar.startOfDay(for: $0.time) })

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while loggedDays.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }

        return streak
    }

}
