import Foundation
import Combine

class XPManager: ObservableObject {
    static let shared = XPManager()

    @Published var totalXP: Int = 0
    @Published var level: Int = 1
    @Published var title: String = "Newbie"
    @Published var progressToNext: Double = 0.0

    private let totalXPKey = "xp_totalXP"

    static let maxLevel = 50

    /// XP required to reach a given level (cumulative).
    /// Level N requires N * 100 XP total to unlock.
    static func xpRequired(forLevel lvl: Int) -> Int {
        return lvl * 100
    }

    init() {
        totalXP = UserDefaults.standard.integer(forKey: totalXPKey)
        recalculate()
    }

    // MARK: - Public

    func awardXP(amount: Int, action: String = "") {
        totalXP += amount
        UserDefaults.standard.set(totalXP, forKey: totalXPKey)
        recalculate()
    }

    // MARK: - Internal

    private func recalculate() {
        level = Self.levelFor(xp: totalXP)
        title = Self.titleFor(level: level)

        let currentLevelXP = Self.xpRequired(forLevel: level)
        let nextLevelXP = Self.xpRequired(forLevel: min(level + 1, Self.maxLevel))
        if nextLevelXP == currentLevelXP {
            progressToNext = 1.0
        } else {
            progressToNext = Double(totalXP - currentLevelXP) / Double(nextLevelXP - currentLevelXP)
        }
        progressToNext = max(0, min(1, progressToNext))
    }

    static func levelFor(xp: Int) -> Int {
        // Level N requires N*100 XP. Find highest level where xp >= level*100
        var lvl = 1
        for l in 1...maxLevel {
            if xp >= xpRequired(forLevel: l) {
                lvl = l
            } else {
                break
            }
        }
        return lvl
    }

    static func titleFor(level: Int) -> String {
        switch level {
        case 1...5:   return NSLocalizedString("title_newbie", comment: "")
        case 6...10:  return NSLocalizedString("title_beginner", comment: "")
        case 11...20: return NSLocalizedString("title_intermediate", comment: "")
        case 21...30: return NSLocalizedString("title_advanced", comment: "")
        case 31...40: return NSLocalizedString("title_expert", comment: "")
        case 41...49: return NSLocalizedString("title_master", comment: "")
        case 50:      return NSLocalizedString("title_legend", comment: "")
        default:      return NSLocalizedString("title_newbie", comment: "")
        }
    }

    /// XP needed from current level to reach next level
    var xpToNextLevel: Int {
        let nextLevelXP = Self.xpRequired(forLevel: min(level + 1, Self.maxLevel))
        let currentLevelXP = Self.xpRequired(forLevel: level)
        return nextLevelXP - currentLevelXP
    }

    /// XP earned within current level
    var xpInCurrentLevel: Int {
        let currentLevelXP = Self.xpRequired(forLevel: level)
        return totalXP - currentLevelXP
    }
}
