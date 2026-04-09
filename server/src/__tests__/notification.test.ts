import request from "supertest";
import { app, prismaMock } from "./helpers/setup";

describe("Notification API", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("POST /api/notifications/register-token", () => {
    it("registers a push token and returns 200", async () => {
      const mockToken = {
        id: "token-1",
        userId: "test-user-id",
        token: "fcm-token-abc123",
        platform: "ios",
        createdAt: new Date().toISOString(),
      };

      prismaMock.pushToken.upsert.mockResolvedValue(mockToken);

      const res = await request(app)
        .post("/api/notifications/register-token")
        .set("Authorization", "Bearer test-token")
        .send({
          token: "fcm-token-abc123",
          platform: "ios",
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty("success", true);
      expect(res.body).toHaveProperty("data");
      expect(res.body.data.token).toBe("fcm-token-abc123");
      expect(res.body.data.platform).toBe("ios");
    });

    it("registers an Android push token", async () => {
      const mockToken = {
        id: "token-2",
        userId: "test-user-id",
        token: "fcm-token-android-xyz",
        platform: "android",
        createdAt: new Date().toISOString(),
      };

      prismaMock.pushToken.upsert.mockResolvedValue(mockToken);

      const res = await request(app)
        .post("/api/notifications/register-token")
        .set("Authorization", "Bearer test-token")
        .send({
          token: "fcm-token-android-xyz",
          platform: "android",
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty("success", true);
      expect(res.body.data.platform).toBe("android");
    });

    it("returns error when token is missing", async () => {
      const res = await request(app)
        .post("/api/notifications/register-token")
        .set("Authorization", "Bearer test-token")
        .send({
          platform: "ios",
        });

      // Zod validation will reject missing token
      expect(res.status).toBe(500);
    });

    it("returns error when platform is missing", async () => {
      const res = await request(app)
        .post("/api/notifications/register-token")
        .set("Authorization", "Bearer test-token")
        .send({
          token: "fcm-token-abc123",
        });

      // Zod validation will reject missing platform
      expect(res.status).toBe(500);
    });

    it("returns error for invalid platform", async () => {
      const res = await request(app)
        .post("/api/notifications/register-token")
        .set("Authorization", "Bearer test-token")
        .send({
          token: "fcm-token-abc123",
          platform: "windows",
        });

      // Zod validation will reject invalid platform enum
      expect(res.status).toBe(500);
    });
  });
});
