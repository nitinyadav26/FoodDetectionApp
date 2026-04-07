import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const badges = [
  { key: "first_scan", name: "First Scan", description: "Scanned your first food item", category: "scanning", xpReward: 10 },
  { key: "scan_10", name: "Scan Apprentice", description: "Scanned 10 food items", category: "scanning", xpReward: 25 },
  { key: "scan_50", name: "Scan Expert", description: "Scanned 50 food items", category: "scanning", xpReward: 50 },
  { key: "scan_100", name: "Scan Master", description: "Scanned 100 food items", category: "scanning", xpReward: 100 },
  { key: "scan_500", name: "Scan Legend", description: "Scanned 500 food items", category: "scanning", xpReward: 250 },
  { key: "streak_3", name: "3-Day Streak", description: "Logged food 3 days in a row", category: "streaks", xpReward: 15 },
  { key: "streak_7", name: "Week Warrior", description: "Logged food 7 days in a row", category: "streaks", xpReward: 35 },
  { key: "streak_14", name: "Two-Week Titan", description: "Logged food 14 days in a row", category: "streaks", xpReward: 70 },
  { key: "streak_30", name: "Monthly Champion", description: "Logged food 30 days in a row", category: "streaks", xpReward: 150 },
  { key: "streak_100", name: "Century Streak", description: "Logged food 100 days in a row", category: "streaks", xpReward: 500 },
  { key: "calorie_goal_1", name: "On Target", description: "Hit your calorie goal for the first time", category: "goals", xpReward: 20 },
  { key: "calorie_goal_7", name: "Week On Track", description: "Hit your calorie goal 7 days", category: "goals", xpReward: 50 },
  { key: "calorie_goal_30", name: "Monthly Precision", description: "Hit your calorie goal 30 days", category: "goals", xpReward: 200 },
  { key: "protein_king", name: "Protein King", description: "Hit protein target 10 days in a row", category: "nutrition", xpReward: 40 },
  { key: "balanced_meal", name: "Balance Master", description: "Logged a perfectly balanced meal", category: "nutrition", xpReward: 30 },
  { key: "veggie_lover", name: "Veggie Lover", description: "Logged vegetables 7 days in a row", category: "nutrition", xpReward: 35 },
  { key: "hydration_hero", name: "Hydration Hero", description: "Logged water intake 7 days in a row", category: "nutrition", xpReward: 25 },
  { key: "low_sugar", name: "Sugar Cutter", description: "Stayed under sugar limit for 5 days", category: "nutrition", xpReward: 30 },
  { key: "first_friend", name: "Social Butterfly", description: "Added your first friend", category: "social", xpReward: 10 },
  { key: "friends_5", name: "Growing Circle", description: "Added 5 friends", category: "social", xpReward: 25 },
  { key: "friends_20", name: "Popular", description: "Added 20 friends", category: "social", xpReward: 50 },
  { key: "first_post", name: "First Share", description: "Shared your first post", category: "social", xpReward: 10 },
  { key: "posts_10", name: "Content Creator", description: "Shared 10 posts", category: "social", xpReward: 30 },
  { key: "first_reaction", name: "Supporter", description: "Reacted to your first post", category: "social", xpReward: 5 },
  { key: "reactions_50", name: "Cheerleader", description: "Gave 50 reactions", category: "social", xpReward: 25 },
  { key: "first_challenge", name: "Challenger", description: "Joined your first challenge", category: "challenges", xpReward: 15 },
  { key: "challenge_win", name: "Champion", description: "Won your first challenge", category: "challenges", xpReward: 50 },
  { key: "challenges_5", name: "Competitive Spirit", description: "Completed 5 challenges", category: "challenges", xpReward: 75 },
  { key: "challenge_creator", name: "Challenge Creator", description: "Created your first challenge", category: "challenges", xpReward: 20 },
  { key: "first_recipe", name: "Chef Beginner", description: "Saved your first recipe", category: "recipes", xpReward: 10 },
  { key: "recipes_10", name: "Home Cook", description: "Saved 10 recipes", category: "recipes", xpReward: 30 },
  { key: "recipes_25", name: "Recipe Collector", description: "Saved 25 recipes", category: "recipes", xpReward: 60 },
  { key: "first_quiz", name: "Quiz Starter", description: "Completed your first quiz", category: "learning", xpReward: 10 },
  { key: "quiz_perfect", name: "Perfect Score", description: "Got 100% on a quiz", category: "learning", xpReward: 25 },
  { key: "quizzes_10", name: "Knowledge Seeker", description: "Completed 10 quizzes", category: "learning", xpReward: 50 },
  { key: "coach_chat_1", name: "Coach Connection", description: "Had your first coach chat", category: "coaching", xpReward: 10 },
  { key: "coach_chat_10", name: "Regular Client", description: "Had 10 coach chats", category: "coaching", xpReward: 30 },
  { key: "meal_plan_1", name: "Planner", description: "Generated your first meal plan", category: "planning", xpReward: 15 },
  { key: "meal_plan_7", name: "Week Planner", description: "Generated 7 meal plans", category: "planning", xpReward: 40 },
  { key: "health_report", name: "Health Analyst", description: "Generated your first health report", category: "insights", xpReward: 20 },
  { key: "weekly_insights", name: "Data Driven", description: "Viewed weekly insights 4 times", category: "insights", xpReward: 30 },
  { key: "league_bronze", name: "Bronze League", description: "Reached Bronze league", category: "leagues", xpReward: 25 },
  { key: "league_silver", name: "Silver League", description: "Reached Silver league", category: "leagues", xpReward: 50 },
  { key: "league_gold", name: "Gold League", description: "Reached Gold league", category: "leagues", xpReward: 100 },
  { key: "league_platinum", name: "Platinum League", description: "Reached Platinum league", category: "leagues", xpReward: 200 },
  { key: "league_diamond", name: "Diamond League", description: "Reached Diamond league", category: "leagues", xpReward: 500 },
  { key: "early_bird", name: "Early Bird", description: "Logged breakfast before 8am 5 times", category: "habits", xpReward: 20 },
  { key: "night_owl", name: "Night Owl", description: "No late-night snacking for 7 days", category: "habits", xpReward: 25 },
  { key: "explorer", name: "Food Explorer", description: "Logged 20 different food types", category: "discovery", xpReward: 40 },
  { key: "world_cuisine", name: "World Cuisine", description: "Logged foods from 10 different cuisines", category: "discovery", xpReward: 60 },
];

async function main() {
  console.log("Seeding badges...");
  for (const badge of badges) {
    await prisma.badge.upsert({
      where: { key: badge.key },
      update: badge,
      create: badge,
    });
  }
  console.log(`Seeded ${badges.length} badges`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
