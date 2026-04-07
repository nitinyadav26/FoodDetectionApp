import { prisma } from "../config/prisma";

export async function getLeaderboard(type: string, period: string = "weekly", limit: number = 50) {
  const now = new Date();
  let periodKey: string;

  if (period === "weekly") {
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - now.getDay());
    periodKey = weekStart.toISOString().slice(0, 10);
  } else if (period === "monthly") {
    periodKey = now.toISOString().slice(0, 7);
  } else {
    periodKey = "all-time";
  }

  return prisma.leaderboard.findMany({
    where: { type, period, periodKey },
    include: { user: { select: { id: true, displayName: true, photoUrl: true } } },
    orderBy: { score: "desc" },
    take: limit,
  });
}

export async function updateLeaderboardScore(userId: string, type: string, score: number, period: string = "weekly") {
  const now = new Date();
  let periodKey: string;

  if (period === "weekly") {
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - now.getDay());
    periodKey = weekStart.toISOString().slice(0, 10);
  } else if (period === "monthly") {
    periodKey = now.toISOString().slice(0, 7);
  } else {
    periodKey = "all-time";
  }

  return prisma.leaderboard.upsert({
    where: { userId_type_period_periodKey: { userId, type, period, periodKey } },
    update: { score },
    create: { userId, type, score, period, periodKey },
  });
}
