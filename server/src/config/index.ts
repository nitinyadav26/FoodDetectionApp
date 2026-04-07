import dotenv from "dotenv";
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || "3000", 10),
  nodeEnv: process.env.NODE_ENV || "development",
  databaseUrl: process.env.DATABASE_URL || "",
  redisUrl: process.env.REDIS_URL || "redis://localhost:6379",
  geminiApiKey: process.env.GEMINI_API_KEY || "",
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "",
  jwtSecret: process.env.JWT_SECRET || "dev-secret",
  isDev: process.env.NODE_ENV !== "production",
};
