import { prisma } from "../config/prisma";

const LEVEL_THRESHOLDS = [0, 100, 250, 500, 1000, 1750, 2750, 4000, 5500, 7500, 10000];

export function calculateLevel(xp: number): number {
  for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
    if (xp >= LEVEL_THRESHOLDS[i]) return i + 1;
  }
  return 1;
}

export async function addXp(userId: string, amount: number) {
  const profile = await prisma.profile.update({
    where: { userId },
    data: { xp: { increment: amount } },
  });

  const newLevel = calculateLevel(profile.xp);
  if (newLevel !== profile.level) {
    await prisma.profile.update({
      where: { userId },
      data: { level: newLevel },
    });
  }

  return { xp: profile.xp, level: newLevel, added: amount };
}

export async function getXpStatus(userId: string) {
  const profile = await prisma.profile.findUnique({ where: { userId } });
  if (!profile) return null;

  const level = calculateLevel(profile.xp);
  const currentThreshold = LEVEL_THRESHOLDS[level - 1] || 0;
  const nextThreshold = LEVEL_THRESHOLDS[level] || LEVEL_THRESHOLDS[LEVEL_THRESHOLDS.length - 1];

  return {
    xp: profile.xp,
    level,
    currentThreshold,
    nextThreshold,
    progress: nextThreshold > currentThreshold
      ? (profile.xp - currentThreshold) / (nextThreshold - currentThreshold)
      : 1,
    streak: profile.streak,
  };
}
