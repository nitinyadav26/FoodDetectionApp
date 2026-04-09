export interface PaginationParams {
  page: number;
  limit: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface GeminiNutritionResult {
  Dish: string;
  "Calories per 100g": number;
  "Carbohydrate per 100g": number;
  "Protein per 100 gm": number;
  "Fats per 100 gm": number;
  "Healthier Recipe": string;
  Source: string;
  micros?: Record<string, number>;
}

export interface CoachMessage {
  role: "user" | "assistant";
  content: string;
}

export interface MealPlanDay {
  date: string;
  meals: {
    breakfast: MealSuggestion;
    lunch: MealSuggestion;
    dinner: MealSuggestion;
    snacks: MealSuggestion[];
  };
  totalCalories: number;
}

export interface MealSuggestion {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
  recipe?: string;
}

export interface QuizQuestion {
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
}
