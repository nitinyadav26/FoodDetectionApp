import { config } from "./index";
import { logger } from "../utils/logger";

const GEMINI_MODEL = "gemini-2.0-flash";

function geminiUrl(): string {
  return `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${config.geminiApiKey}`;
}

async function callGeminiWithRetry(body: Record<string, unknown>, retries = 3): Promise<unknown> {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const response = await fetch(geminiUrl(), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (response.status === 429 && attempt < retries) {
        const delay = Math.pow(2, attempt) * 1000;
        logger.warn(`Gemini rate limited, retrying in ${delay}ms (attempt ${attempt}/${retries})`);
        await new Promise((r) => setTimeout(r, delay));
        continue;
      }

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`Gemini API error ${response.status}: ${errText}`);
      }

      return await response.json();
    } catch (err) {
      if (attempt === retries) throw err;
      const delay = Math.pow(2, attempt) * 1000;
      logger.warn(`Gemini call failed, retrying in ${delay}ms`, err);
      await new Promise((r) => setTimeout(r, delay));
    }
  }
}

export async function analyzeFoodImage(imageBase64: string): Promise<unknown> {
  const promptText = `Analyze this food image. Identify the dish and estimate nutrition per 100g.
Return JSON with keys: Dish, "Calories per 100g", "Carbohydrate per 100g", "Protein per 100 gm", "Fats per 100 gm", "Healthier Recipe", "Source", micros (optional dict of micronutrients).`;

  return callGeminiWithRetry({
    contents: [
      {
        parts: [
          { text: promptText },
          { inline_data: { mime_type: "image/jpeg", data: imageBase64 } },
        ],
      },
    ],
    generationConfig: { responseMimeType: "application/json" },
  });
}

export async function searchFoodNutrition(query: string): Promise<unknown> {
  const promptText = `Provide nutrition information for: "${query}".
Return JSON with keys: Dish, "Calories per 100g", "Carbohydrate per 100g", "Protein per 100 gm", "Fats per 100 gm", "Healthier Recipe", "Source", micros (optional dict of micronutrients).`;

  return callGeminiWithRetry({
    contents: [{ parts: [{ text: promptText }] }],
    generationConfig: { responseMimeType: "application/json" },
  });
}

export async function getCoachAdvice(context: string, query: string, history: Array<{ role: string; content: string }> = []): Promise<unknown> {
  const systemPrompt =
    "You are a friendly and motivating professional health coach. " +
    "Use the provided health and nutrition data to give personalized advice.";

  const historyText = history
    .map((m) => `${m.role === "user" ? "User" : "Coach"}: ${m.content}`)
    .join("\n");

  const fullPrompt = `${systemPrompt}\n\n--- Conversation History ---\n${historyText}\n\n--- User Context ---\n${context || "No context provided."}\n\n--- User Question ---\n${query}`;

  return callGeminiWithRetry({
    contents: [{ parts: [{ text: fullPrompt }] }],
    generationConfig: { maxOutputTokens: 1000, temperature: 0.7 },
  });
}

export async function generateMealPlan(profile: Record<string, unknown>, days: number = 1): Promise<unknown> {
  const promptText = `Generate a ${days}-day meal plan for a person with these details:
Age: ${profile.age || "unknown"}, Gender: ${profile.gender || "unknown"},
Weight: ${profile.weightKg || "unknown"}kg, Height: ${profile.heightCm || "unknown"}cm,
Activity Level: ${profile.activityLevel || "moderate"},
Dietary Goal: ${profile.dietaryGoal || "maintain weight"},
Allergies: ${(profile.allergies as string[])?.join(", ") || "none"},
Daily Calorie Target: ${profile.dailyCalorieTarget || 2000} kcal.

Return JSON array of objects with keys: date, meals (object with breakfast, lunch, dinner, snacks array), totalCalories. Each meal has: name, calories, protein, carbs, fats, recipe.`;

  return callGeminiWithRetry({
    contents: [{ parts: [{ text: promptText }] }],
    generationConfig: { responseMimeType: "application/json" },
  });
}

export async function generateWeeklyInsights(foodLogs: unknown[]): Promise<unknown> {
  const promptText = `Analyze these food logs from the past week and provide nutrition insights:
${JSON.stringify(foodLogs)}

Return JSON with keys: summary (string), averageCalories (number), topFoods (array of strings), nutritionScore (1-100), recommendations (array of strings), macroBreakdown (object with protein, carbs, fats percentages).`;

  return callGeminiWithRetry({
    contents: [{ parts: [{ text: promptText }] }],
    generationConfig: { responseMimeType: "application/json" },
  });
}

export async function generateHealthReport(foodLogs: unknown[], profile: Record<string, unknown>): Promise<unknown> {
  const promptText = `Generate a comprehensive health report based on these food logs and user profile:
Profile: ${JSON.stringify(profile)}
Food Logs (recent): ${JSON.stringify(foodLogs)}

Return JSON with keys: overallScore (1-100), summary (string), strengths (array), improvements (array), nutritionAnalysis (object), recommendations (array of strings), riskFactors (array).`;

  return callGeminiWithRetry({
    contents: [{ parts: [{ text: promptText }] }],
    generationConfig: { responseMimeType: "application/json" },
  });
}

export async function generateQuiz(topic: string): Promise<unknown> {
  const promptText = `Generate a nutrition quiz about "${topic}".
Return JSON array of 5 objects, each with keys: question (string), options (array of 4 strings), correctIndex (number 0-3), explanation (string).`;

  return callGeminiWithRetry({
    contents: [{ parts: [{ text: promptText }] }],
    generationConfig: { responseMimeType: "application/json" },
  });
}

export async function generateRecipeSuggestions(ingredients: string[], dietary?: string): Promise<unknown> {
  const promptText = `Suggest 3 healthy recipes using these ingredients: ${ingredients.join(", ")}${dietary ? `. Dietary preference: ${dietary}` : ""}.
Return JSON array of objects with keys: title, description, ingredients (array), instructions (array of steps), calories, prepTimeMins, tags (array).`;

  return callGeminiWithRetry({
    contents: [{ parts: [{ text: promptText }] }],
    generationConfig: { responseMimeType: "application/json" },
  });
}
