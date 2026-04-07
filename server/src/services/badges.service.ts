import { prisma } from "../config/prisma";

export async function getAllBadges() {
  return prisma.badge.findMany({ orderBy: { category: "asc" } });
}

export async function getUserBadges(userId: string) {
  return prisma.userBadge.findMany({
    where: { userId },
    include: { badge: true },
    orderBy: { earnedAt: "desc" },
  });
}

export async function awardBadge(userId: string, badgeKey: string) {
  const badge = await prisma.badge.findUnique({ where: { key: badgeKey } });
  if (!badge) return null;

  const existing = await prisma.userBadge.findFirst({
    where: { userId, badgeId: badge.id },
  });
  if (existing) return existing;

  const awarded = await prisma.userBadge.create({
    data: { userId, badgeId: badge.id },
    include: { badge: true },
  });

  // Award XP
  if (badge.xpReward > 0) {
    await prisma.profile.update({
      where: { userId },
      data: { xp: { increment: badge.xpReward } },
    });
  }

  return awarded;
}

export async function checkAndAwardBadges(userId: string) {
  const scanCount = await prisma.foodLog.count({ where: { userId } });
  const awarded: string[] = [];

  const thresholds: Record<number, string> = { 1: "first_scan", 10: "scan_10", 50: "scan_50", 100: "scan_100", 500: "scan_500" };
  for (const [count, key] of Object.entries(thresholds)) {
    if (scanCount >= parseInt(count)) {
      const result = await awardBadge(userId, key);
      if (result) awarded.push(key);
    }
  }

  return awarded;
}
