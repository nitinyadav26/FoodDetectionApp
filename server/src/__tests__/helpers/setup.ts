import { Request, Response, NextFunction } from "express";

// Set test environment variables before any imports
process.env.NODE_ENV = "test";
process.env.DATABASE_URL = "postgresql://test:test@localhost:5432/foodsense_test";
process.env.REDIS_URL = "redis://localhost:6379";
process.env.GEMINI_API_KEY = "test-gemini-key";
process.env.JWT_SECRET = "test-jwt-secret";

// Mock Firebase Admin SDK
jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  credential: {
    cert: jest.fn(),
  },
  auth: jest.fn(() => ({
    verifyIdToken: jest.fn().mockResolvedValue({
      uid: "test-firebase-uid",
      email: "test@example.com",
      name: "Test User",
      picture: null,
    }),
  })),
  messaging: jest.fn(() => ({
    sendEachForMulticast: jest.fn().mockResolvedValue({ successCount: 1 }),
  })),
}));

// Mock Firebase config module
jest.mock("../../config/firebase", () => ({
  initFirebase: jest.fn(),
  verifyIdToken: jest.fn().mockResolvedValue({
    uid: "test-firebase-uid",
    email: "test@example.com",
    name: "Test User",
    picture: null,
  }),
  admin: {
    messaging: jest.fn(() => ({
      sendEachForMulticast: jest.fn().mockResolvedValue({ successCount: 1 }),
    })),
  },
}));

// Mock Redis
jest.mock("ioredis", () => {
  return jest.fn().mockImplementation(() => ({
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue("OK"),
    del: jest.fn().mockResolvedValue(1),
    on: jest.fn(),
    quit: jest.fn(),
  }));
});

jest.mock("../../config/redis", () => ({
  getRedis: jest.fn(() => ({
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue("OK"),
    del: jest.fn().mockResolvedValue(1),
    on: jest.fn(),
    quit: jest.fn(),
  })),
}));

// Mock Prisma client
const mockPrismaUser = {
  findUnique: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
};

const mockPrismaFoodLog = {
  create: jest.fn(),
  findMany: jest.fn(),
  count: jest.fn(),
};

const mockPrismaPushToken = {
  upsert: jest.fn(),
  findMany: jest.fn(),
};

const mockPrismaProfile = {
  findUnique: jest.fn(),
  update: jest.fn(),
};

export const prismaMock = {
  user: mockPrismaUser,
  foodLog: mockPrismaFoodLog,
  pushToken: mockPrismaPushToken,
  profile: mockPrismaProfile,
  $connect: jest.fn(),
  $disconnect: jest.fn(),
};

jest.mock("../../config/prisma", () => ({
  prisma: prismaMock,
}));

// Mock auth middleware to inject a test user
jest.mock("../../middleware/auth", () => ({
  authMiddleware: (req: Request, _res: Response, next: NextFunction) => {
    req.user = {
      uid: "test-firebase-uid",
      email: "test@example.com",
      userId: "test-user-id",
    };
    next();
  },
}));

// Re-export app after mocks are set up
import app from "../../app";
export { app };
