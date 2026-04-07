package com.foodsense.android.data

enum class BadgeCategory(val label: String) {
    STREAK("Streaks"),
    LOGGING("Logging"),
    NUTRITION("Nutrition"),
    HEALTH("Health"),
    SOCIAL("Social"),
    MILESTONES("Milestones"),
}

data class BadgeDefinition(
    val key: String,
    val name: String,
    val description: String,
    val icon: String,
    val category: BadgeCategory,
)

object AllBadges {
    val list: List<BadgeDefinition> = listOf(
        // STREAK (10)
        BadgeDefinition("streak_3", "3-Day Spark", "Log food 3 days in a row", "flame", BadgeCategory.STREAK),
        BadgeDefinition("streak_7", "Week Warrior", "Log food 7 days in a row", "flame", BadgeCategory.STREAK),
        BadgeDefinition("streak_14", "Fortnight Fighter", "Log food 14 days in a row", "flame", BadgeCategory.STREAK),
        BadgeDefinition("streak_21", "3-Week Wonder", "Log food 21 days in a row", "flame", BadgeCategory.STREAK),
        BadgeDefinition("streak_30", "Monthly Master", "Log food 30 days in a row", "star", BadgeCategory.STREAK),
        BadgeDefinition("streak_60", "Two-Month Titan", "Log food 60 days in a row", "star", BadgeCategory.STREAK),
        BadgeDefinition("streak_90", "Quarter King", "Log food 90 days in a row", "star", BadgeCategory.STREAK),
        BadgeDefinition("streak_180", "Half-Year Hero", "Log food 180 days in a row", "trophy", BadgeCategory.STREAK),
        BadgeDefinition("streak_365", "Year Legend", "Log food 365 days in a row", "trophy", BadgeCategory.STREAK),
        BadgeDefinition("streak_comeback", "Comeback Kid", "Restart a streak after losing one", "flame", BadgeCategory.STREAK),

        // LOGGING (10)
        BadgeDefinition("log_1", "First Bite", "Log your first food", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_10", "Tenacious Ten", "Log 10 foods total", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_25", "Quarter Century", "Log 25 foods total", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_50", "Half Century", "Log 50 foods total", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_100", "Century Logger", "Log 100 foods total", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_250", "Prolific Tracker", "Log 250 foods total", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_500", "Food Historian", "Log 500 foods total", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_1000", "Thousand Club", "Log 1000 foods total", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_3meals", "Three Square", "Log 3 meals in one day", "utensils", BadgeCategory.LOGGING),
        BadgeDefinition("log_5meals", "Five-a-Day", "Log 5 meals in one day", "utensils", BadgeCategory.LOGGING),

        // NUTRITION (10)
        BadgeDefinition("cal_under_budget", "Budget Boss", "Stay under calorie budget for a day", "target", BadgeCategory.NUTRITION),
        BadgeDefinition("cal_under_7days", "Week Watcher", "Stay under calorie budget 7 days", "target", BadgeCategory.NUTRITION),
        BadgeDefinition("protein_100", "Protein Power", "Hit 100g protein in one day", "muscle", BadgeCategory.NUTRITION),
        BadgeDefinition("protein_150", "Protein Pro", "Hit 150g protein in one day", "muscle", BadgeCategory.NUTRITION),
        BadgeDefinition("balanced_meal", "Balanced Plate", "Log a meal with all macros > 0", "plate", BadgeCategory.NUTRITION),
        BadgeDefinition("low_fat_day", "Low Fat Day", "Keep fats under 40g for a day", "leaf", BadgeCategory.NUTRITION),
        BadgeDefinition("high_fiber", "Fiber Fan", "Log a food with fiber noted", "leaf", BadgeCategory.NUTRITION),
        BadgeDefinition("variety_5", "Variety Pack", "Log 5 different foods in one day", "rainbow", BadgeCategory.NUTRITION),
        BadgeDefinition("variety_10", "Food Explorer", "Log 10 different foods in one day", "rainbow", BadgeCategory.NUTRITION),
        BadgeDefinition("zero_junk", "Clean Eater", "Log only healthy foods for a day", "sparkle", BadgeCategory.NUTRITION),

        // HEALTH (10)
        BadgeDefinition("water_2l", "Hydration Hero", "Log 2L of water in a day", "droplet", BadgeCategory.HEALTH),
        BadgeDefinition("water_3l", "Water Champion", "Log 3L of water in a day", "droplet", BadgeCategory.HEALTH),
        BadgeDefinition("steps_5k", "Step Starter", "Walk 5,000 steps in a day", "shoe", BadgeCategory.HEALTH),
        BadgeDefinition("steps_10k", "10K Walker", "Walk 10,000 steps in a day", "shoe", BadgeCategory.HEALTH),
        BadgeDefinition("steps_15k", "Step Master", "Walk 15,000 steps in a day", "shoe", BadgeCategory.HEALTH),
        BadgeDefinition("sleep_7h", "Good Sleep", "Get 7+ hours of sleep", "moon", BadgeCategory.HEALTH),
        BadgeDefinition("sleep_8h", "Sleep Champion", "Get 8+ hours of sleep", "moon", BadgeCategory.HEALTH),
        BadgeDefinition("burn_300", "Calorie Burner", "Burn 300+ active calories", "fire", BadgeCategory.HEALTH),
        BadgeDefinition("burn_500", "Inferno", "Burn 500+ active calories", "fire", BadgeCategory.HEALTH),
        BadgeDefinition("all_health", "Wellness Warrior", "Hit water, steps & sleep goals in one day", "heart", BadgeCategory.HEALTH),

        // SOCIAL (5)
        BadgeDefinition("social_share", "Social Butterfly", "Share a meal on social media", "share", BadgeCategory.SOCIAL),
        BadgeDefinition("social_invite", "Ambassador", "Invite a friend to FoodSense", "users", BadgeCategory.SOCIAL),
        BadgeDefinition("social_review", "Reviewer", "Leave an app review", "pencil", BadgeCategory.SOCIAL),
        BadgeDefinition("social_feedback", "Feedback Giver", "Send feedback to the team", "mail", BadgeCategory.SOCIAL),
        BadgeDefinition("social_community", "Community Member", "Join the FoodSense community", "globe", BadgeCategory.SOCIAL),

        // MILESTONES (5)
        BadgeDefinition("level_10", "Rising Star", "Reach level 10", "star", BadgeCategory.MILESTONES),
        BadgeDefinition("level_25", "Quarter Master", "Reach level 25", "star", BadgeCategory.MILESTONES),
        BadgeDefinition("level_50", "Max Level", "Reach level 50", "crown", BadgeCategory.MILESTONES),
        BadgeDefinition("badges_10", "Collector", "Unlock 10 badges", "medal", BadgeCategory.MILESTONES),
        BadgeDefinition("badges_25", "Completionist", "Unlock 25 badges", "medal", BadgeCategory.MILESTONES),
    )

    val byKey: Map<String, BadgeDefinition> = list.associateBy { it.key }
    val byCategory: Map<BadgeCategory, List<BadgeDefinition>> = list.groupBy { it.category }
}
