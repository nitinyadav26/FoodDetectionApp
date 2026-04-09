import { prisma } from "../config/prisma";

export async function saveRecipe(userId: string, data: {
  title: string;
  description?: string;
  ingredients: string[];
  instructions: string[];
  calories?: number;
  prepTimeMins?: number;
  tags?: string[];
  imageUrl?: string;
  isPublic?: boolean;
}) {
  return prisma.recipe.create({
    data: {
      userId,
      title: data.title,
      description: data.description,
      ingredients: data.ingredients,
      instructions: data.instructions,
      calories: data.calories,
      prepTimeMins: data.prepTimeMins,
      tags: data.tags || [],
      imageUrl: data.imageUrl,
      isPublic: data.isPublic ?? true,
    },
  });
}

export async function getRecipes(page: number, limit: number, userId?: string) {
  const where = userId ? { userId } : { isPublic: true };
  const [data, total] = await Promise.all([
    prisma.recipe.findMany({
      where,
      include: { user: { select: { id: true, displayName: true } } },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.recipe.count({ where }),
  ]);
  return { data, total };
}
