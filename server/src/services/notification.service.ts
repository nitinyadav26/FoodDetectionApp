import { prisma } from "../config/prisma";
import { admin } from "../config/firebase";
import { logger } from "../utils/logger";

export async function registerPushToken(userId: string, token: string, platform: string) {
  return prisma.pushToken.upsert({
    where: { token },
    update: { userId, platform },
    create: { userId, token, platform },
  });
}

export async function sendPushNotification(userId: string, title: string, body: string, data?: Record<string, string>) {
  const tokens = await prisma.pushToken.findMany({ where: { userId } });
  if (tokens.length === 0) return;

  const message = {
    notification: { title, body },
    data: data || {},
    tokens: tokens.map((t) => t.token),
  };

  try {
    await admin.messaging().sendEachForMulticast(message);
  } catch (err) {
    logger.error("Push notification failed:", err);
  }
}
