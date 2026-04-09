import { prisma } from "../config/prisma";

interface SyncFoodLog {
  clientId: string;
  dishName: string;
  calories?: number;
  proteinG?: number;
  carbsG?: number;
  fatsG?: number;
  micronutrients?: Record<string, string>;
  healthierRecipe?: string;
  loggedAt: string;
}

export async function upsertFoodLogs(userId: string, logs: SyncFoodLog[]) {
  const results = await Promise.all(
    logs.map((log) => {
      const data = {
        dishName: log.dishName,
        calories: log.calories ?? null,
        proteinG: log.proteinG ?? null,
        carbsG: log.carbsG ?? null,
        fatsG: log.fatsG ?? null,
        micronutrients: log.micronutrients ?? undefined,
        healthierRecipe: log.healthierRecipe ?? null,
        loggedAt: new Date(log.loggedAt),
      };
      return prisma.foodLog.upsert({
        where: { id: log.clientId },
        create: { id: log.clientId, userId, ...data },
        update: data,
      });
    })
  );
  return results;
}

export async function getLogsSince(userId: string, since?: string) {
  const where: { userId: string; loggedAt?: { gte: Date } } = { userId };
  if (since) {
    where.loggedAt = { gte: new Date(since) };
  }
  return prisma.foodLog.findMany({
    where,
    orderBy: { loggedAt: "desc" },
  });
}
