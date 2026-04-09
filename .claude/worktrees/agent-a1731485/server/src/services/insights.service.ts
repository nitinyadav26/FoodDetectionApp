import * as gemini from "../config/gemini";
import { getRecentFoodLogs } from "./food.service";

export async function getWeeklyInsights(userId: string) {
  const logs = await getRecentFoodLogs(userId, 7);
  if (logs.length === 0) {
    return {
      summary: "No food logs found for this week. Start logging your meals to get insights!",
      averageCalories: 0,
      topFoods: [],
      nutritionScore: 0,
      recommendations: ["Start logging your meals to receive personalized insights."],
      macroBreakdown: { protein: 0, carbs: 0, fats: 0 },
    };
  }

  const simplifiedLogs = logs.map((l) => ({
    dish: l.dishName,
    calories: l.calories,
    protein: l.proteinG,
    carbs: l.carbsG,
    fats: l.fatsG,
    mealType: l.mealType,
    date: l.loggedAt,
  }));

  return gemini.generateWeeklyInsights(simplifiedLogs);
}
