import * as gemini from "../config/gemini";
import { getRecentFoodLogs } from "./food.service";
import { getUserProfile } from "./user.service";

export async function generateReport(userId: string) {
  const [logs, user] = await Promise.all([
    getRecentFoodLogs(userId, 30),
    getUserProfile(userId),
  ]);

  const profile = user?.profile || {};
  const simplifiedLogs = logs.map((l) => ({
    dish: l.dishName,
    calories: l.calories,
    protein: l.proteinG,
    carbs: l.carbsG,
    fats: l.fatsG,
    mealType: l.mealType,
    date: l.loggedAt,
  }));

  return gemini.generateHealthReport(simplifiedLogs, profile as Record<string, unknown>);
}
