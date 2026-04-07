import Foundation

// MARK: - Badge Category

enum BadgeCategory: String, CaseIterable, Identifiable {
    case streak     = "Streak"
    case logging    = "Logging"
    case nutrition  = "Nutrition"
    case social     = "Social"
    case challenges = "Challenges"
    case special    = "Special"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .streak:     return NSLocalizedString("badge_cat_streak", comment: "")
        case .logging:    return NSLocalizedString("badge_cat_logging", comment: "")
        case .nutrition:  return NSLocalizedString("badge_cat_nutrition", comment: "")
        case .social:     return NSLocalizedString("badge_cat_social", comment: "")
        case .challenges: return NSLocalizedString("badge_cat_challenges", comment: "")
        case .special:    return NSLocalizedString("badge_cat_special", comment: "")
        }
    }
}

// MARK: - Badge Definition

struct BadgeDefinition: Identifiable {
    let id: String           // unique key, e.g. "streak_7"
    let name: String         // display name (localization key)
    let description: String  // description (localization key)
    let icon: String         // SF Symbol name
    let category: BadgeCategory
}

// MARK: - All 50 Badges

extension BadgeDefinition {
    static let allBadges: [BadgeDefinition] = [
        // ── Streak (10) ──────────────────────────────────────────
        BadgeDefinition(id: "streak_3",   name: "badge_streak_3",   description: "badge_streak_3_desc",   icon: "flame",            category: .streak),
        BadgeDefinition(id: "streak_7",   name: "badge_streak_7",   description: "badge_streak_7_desc",   icon: "flame.fill",        category: .streak),
        BadgeDefinition(id: "streak_14",  name: "badge_streak_14",  description: "badge_streak_14_desc",  icon: "flame.circle",      category: .streak),
        BadgeDefinition(id: "streak_21",  name: "badge_streak_21",  description: "badge_streak_21_desc",  icon: "flame.circle.fill", category: .streak),
        BadgeDefinition(id: "streak_30",  name: "badge_streak_30",  description: "badge_streak_30_desc",  icon: "star.fill",         category: .streak),
        BadgeDefinition(id: "streak_60",  name: "badge_streak_60",  description: "badge_streak_60_desc",  icon: "star.circle.fill",  category: .streak),
        BadgeDefinition(id: "streak_90",  name: "badge_streak_90",  description: "badge_streak_90_desc",  icon: "trophy",            category: .streak),
        BadgeDefinition(id: "streak_120", name: "badge_streak_120", description: "badge_streak_120_desc", icon: "trophy.fill",        category: .streak),
        BadgeDefinition(id: "streak_180", name: "badge_streak_180", description: "badge_streak_180_desc", icon: "crown",             category: .streak),
        BadgeDefinition(id: "streak_365", name: "badge_streak_365", description: "badge_streak_365_desc", icon: "crown.fill",        category: .streak),

        // ── Logging (10) ─────────────────────────────────────────
        BadgeDefinition(id: "log_1",    name: "badge_log_1",    description: "badge_log_1_desc",    icon: "square.and.pencil",     category: .logging),
        BadgeDefinition(id: "log_10",   name: "badge_log_10",   description: "badge_log_10_desc",   icon: "doc.text",              category: .logging),
        BadgeDefinition(id: "log_25",   name: "badge_log_25",   description: "badge_log_25_desc",   icon: "doc.text.fill",         category: .logging),
        BadgeDefinition(id: "log_50",   name: "badge_log_50",   description: "badge_log_50_desc",   icon: "tray.full",             category: .logging),
        BadgeDefinition(id: "log_100",  name: "badge_log_100",  description: "badge_log_100_desc",  icon: "tray.full.fill",        category: .logging),
        BadgeDefinition(id: "log_250",  name: "badge_log_250",  description: "badge_log_250_desc",  icon: "archivebox",            category: .logging),
        BadgeDefinition(id: "log_500",  name: "badge_log_500",  description: "badge_log_500_desc",  icon: "archivebox.fill",       category: .logging),
        BadgeDefinition(id: "log_750",  name: "badge_log_750",  description: "badge_log_750_desc",  icon: "books.vertical",        category: .logging),
        BadgeDefinition(id: "log_1000", name: "badge_log_1000", description: "badge_log_1000_desc", icon: "books.vertical.fill",   category: .logging),
        BadgeDefinition(id: "log_2000", name: "badge_log_2000", description: "badge_log_2000_desc", icon: "graduationcap.fill",    category: .logging),

        // ── Nutrition (10) ───────────────────────────────────────
        BadgeDefinition(id: "nut_cal_target",     name: "badge_nut_cal_target",     description: "badge_nut_cal_target_desc",     icon: "target",                 category: .nutrition),
        BadgeDefinition(id: "nut_cal_target_7",   name: "badge_nut_cal_target_7",   description: "badge_nut_cal_target_7_desc",   icon: "scope",                  category: .nutrition),
        BadgeDefinition(id: "nut_protein_100",    name: "badge_nut_protein_100",    description: "badge_nut_protein_100_desc",    icon: "bolt.fill",              category: .nutrition),
        BadgeDefinition(id: "nut_protein_7",      name: "badge_nut_protein_7",      description: "badge_nut_protein_7_desc",      icon: "bolt.circle.fill",       category: .nutrition),
        BadgeDefinition(id: "nut_under_budget",   name: "badge_nut_under_budget",   description: "badge_nut_under_budget_desc",   icon: "arrow.down.circle",      category: .nutrition),
        BadgeDefinition(id: "nut_balanced_meal",  name: "badge_nut_balanced_meal",  description: "badge_nut_balanced_meal_desc",  icon: "chart.pie",              category: .nutrition),
        BadgeDefinition(id: "nut_water_8",        name: "badge_nut_water_8",        description: "badge_nut_water_8_desc",        icon: "drop.fill",              category: .nutrition),
        BadgeDefinition(id: "nut_water_30",       name: "badge_nut_water_30",       description: "badge_nut_water_30_desc",       icon: "drop.circle.fill",       category: .nutrition),
        BadgeDefinition(id: "nut_variety_10",     name: "badge_nut_variety_10",     description: "badge_nut_variety_10_desc",     icon: "leaf.fill",              category: .nutrition),
        BadgeDefinition(id: "nut_variety_25",     name: "badge_nut_variety_25",     description: "badge_nut_variety_25_desc",     icon: "leaf.circle.fill",       category: .nutrition),

        // ── Social (8) ──────────────────────────────────────────
        BadgeDefinition(id: "soc_share_1",     name: "badge_soc_share_1",     description: "badge_soc_share_1_desc",     icon: "square.and.arrow.up",      category: .social),
        BadgeDefinition(id: "soc_share_10",    name: "badge_soc_share_10",    description: "badge_soc_share_10_desc",    icon: "square.and.arrow.up.fill", category: .social),
        BadgeDefinition(id: "soc_invite_1",    name: "badge_soc_invite_1",    description: "badge_soc_invite_1_desc",    icon: "person.badge.plus",        category: .social),
        BadgeDefinition(id: "soc_invite_5",    name: "badge_soc_invite_5",    description: "badge_soc_invite_5_desc",    icon: "person.2.fill",            category: .social),
        BadgeDefinition(id: "soc_review",      name: "badge_soc_review",      description: "badge_soc_review_desc",      icon: "hand.thumbsup.fill",       category: .social),
        BadgeDefinition(id: "soc_community",   name: "badge_soc_community",   description: "badge_soc_community_desc",   icon: "bubble.left.and.bubble.right.fill", category: .social),
        BadgeDefinition(id: "soc_mentor",      name: "badge_soc_mentor",      description: "badge_soc_mentor_desc",      icon: "person.fill.checkmark",    category: .social),
        BadgeDefinition(id: "soc_influencer",  name: "badge_soc_influencer",  description: "badge_soc_influencer_desc",  icon: "megaphone.fill",           category: .social),

        // ── Challenges (7) ──────────────────────────────────────
        BadgeDefinition(id: "ch_first",       name: "badge_ch_first",       description: "badge_ch_first_desc",       icon: "flag.fill",               category: .challenges),
        BadgeDefinition(id: "ch_weekend",     name: "badge_ch_weekend",     description: "badge_ch_weekend_desc",     icon: "calendar.badge.clock",    category: .challenges),
        BadgeDefinition(id: "ch_no_junk_7",   name: "badge_ch_no_junk_7",   description: "badge_ch_no_junk_7_desc",   icon: "xmark.circle.fill",       category: .challenges),
        BadgeDefinition(id: "ch_steps_10k",   name: "badge_ch_steps_10k",   description: "badge_ch_steps_10k_desc",   icon: "figure.walk.circle.fill", category: .challenges),
        BadgeDefinition(id: "ch_early_bird",  name: "badge_ch_early_bird",  description: "badge_ch_early_bird_desc",  icon: "sunrise.fill",            category: .challenges),
        BadgeDefinition(id: "ch_night_owl",   name: "badge_ch_night_owl",   description: "badge_ch_night_owl_desc",   icon: "moon.fill",               category: .challenges),
        BadgeDefinition(id: "ch_perfect_week",name: "badge_ch_perfect_week",description: "badge_ch_perfect_week_desc",icon: "checkmark.seal.fill",     category: .challenges),

        // ── Special (5) ─────────────────────────────────────────
        BadgeDefinition(id: "sp_first_scan",  name: "badge_sp_first_scan",  description: "badge_sp_first_scan_desc",  icon: "camera.fill",             category: .special),
        BadgeDefinition(id: "sp_barcode",     name: "badge_sp_barcode",     description: "badge_sp_barcode_desc",     icon: "barcode.viewfinder",      category: .special),
        BadgeDefinition(id: "sp_coach_chat",  name: "badge_sp_coach_chat",  description: "badge_sp_coach_chat_desc",  icon: "text.bubble.fill",        category: .special),
        BadgeDefinition(id: "sp_profile_done",name: "badge_sp_profile_done",description: "badge_sp_profile_done_desc",icon: "person.crop.circle.fill.badge.checkmark", category: .special),
        BadgeDefinition(id: "sp_level_50",    name: "badge_sp_level_50",    description: "badge_sp_level_50_desc",    icon: "sparkles",                category: .special),
    ]
}
