import { z } from "zod";

export const analyzeFoodSchema = z.object({
  image_base64: z.string().min(1, "image_base64 is required"),
});

export const searchFoodSchema = z.object({
  query: z.string().min(1, "query is required"),
});

export const logFoodSchema = z.object({
  dishName: z.string().min(1),
  calories: z.number().optional(),
  carbsG: z.number().optional(),
  proteinG: z.number().optional(),
  fatsG: z.number().optional(),
  servingSize: z.string().optional(),
  mealType: z.enum(["breakfast", "lunch", "dinner", "snack"]).optional(),
  imageUrl: z.string().optional(),
  micronutrients: z.record(z.number()).optional(),
  healthierRecipe: z.string().optional(),
  source: z.string().optional(),
});

export const coachChatSchema = z.object({
  query: z.string().min(1, "query is required"),
  context: z.string().optional(),
  sessionId: z.string().optional(),
});

export const profileUpdateSchema = z.object({
  displayName: z.string().optional(),
  age: z.number().int().min(1).max(150).optional(),
  gender: z.string().optional(),
  heightCm: z.number().positive().optional(),
  weightKg: z.number().positive().optional(),
  activityLevel: z.enum(["sedentary", "light", "moderate", "active", "very_active"]).optional(),
  dietaryGoal: z.enum(["lose_weight", "maintain", "gain_muscle", "improve_health"]).optional(),
  allergies: z.array(z.string()).optional(),
  dailyCalorieTarget: z.number().int().positive().optional(),
});

export const friendRequestSchema = z.object({
  friendId: z.string().uuid(),
});

export const feedPostSchema = z.object({
  type: z.enum(["food_log", "achievement", "milestone", "text"]),
  content: z.string().optional(),
  imageUrl: z.string().optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const reactionSchema = z.object({
  type: z.enum(["like", "love", "fire", "clap"]),
});

export const createChallengeSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  type: z.enum(["calorie", "protein", "streak", "steps", "custom"]),
  goal: z.record(z.unknown()),
  startDate: z.string().datetime(),
  endDate: z.string().datetime(),
});

export const joinChallengeSchema = z.object({
  challengeId: z.string().uuid(),
});

export const addXpSchema = z.object({
  amount: z.number().int().positive(),
  reason: z.string().min(1),
});

export const saveRecipeSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  ingredients: z.array(z.string()),
  instructions: z.array(z.string()),
  calories: z.number().optional(),
  prepTimeMins: z.number().int().optional(),
  tags: z.array(z.string()).optional(),
  imageUrl: z.string().optional(),
  isPublic: z.boolean().optional(),
});

export const recipeSuggestSchema = z.object({
  ingredients: z.array(z.string()).min(1),
  dietary: z.string().optional(),
});

export const quizSubmitSchema = z.object({
  topic: z.string(),
  score: z.number().int().min(0),
  total: z.number().int().positive(),
});

export const verifyTokenSchema = z.object({
  token: z.string().min(1, "token is required"),
});

export const registerPushTokenSchema = z.object({
  token: z.string().min(1, "token is required"),
  platform: z.enum(["ios", "android", "web"]),
});
