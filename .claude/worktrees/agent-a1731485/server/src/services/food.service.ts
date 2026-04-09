import { prisma } from "../config/prisma";

export async function createFoodLog(userId: string, data: {
  dishName: string;
  calories?: number;
  carbsG?: number;
  proteinG?: number;
  fatsG?: number;
  servingSize?: string;
  mealType?: string;
  imageUrl?: string;
  micronutrients?: Record<string, number>;
  healthierRecipe?: string;
  source?: string;
}) {
  return prisma.foodLog.create({
    data: {
      userId,
      dishName: data.dishName,
      calories: data.calories,
      carbsG: data.carbsG,
      proteinG: data.proteinG,
      fatsG: data.fatsG,
      servingSize: data.servingSize,
      mealType: data.mealType,
      imageUrl: data.imageUrl,
      micronutrients: data.micronutrients ?? undefined,
      healthierRecipe: data.healthierRecipe,
      source: data.source,
    },
  });
}

export async function getFoodLogs(userId: string, page: number, limit: number) {
  const [data, total] = await Promise.all([
    prisma.foodLog.findMany({
      where: { userId },
      orderBy: { loggedAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.foodLog.count({ where: { userId } }),
  ]);
  return { data, total };
}

export async function getRecentFoodLogs(userId: string, days: number = 7) {
  const since = new Date();
  since.setDate(since.getDate() - days);
  return prisma.foodLog.findMany({
    where: { userId, loggedAt: { gte: since } },
    orderBy: { loggedAt: "desc" },
  });
}

export async function getDailyCalories(userId: string, date: Date) {
  const start = new Date(date);
  start.setHours(0, 0, 0, 0);
  const end = new Date(date);
  end.setHours(23, 59, 59, 999);

  const logs = await prisma.foodLog.findMany({
    where: { userId, loggedAt: { gte: start, lte: end } },
  });

  return logs.reduce((sum, log) => sum + (log.calories || 0), 0);
}
