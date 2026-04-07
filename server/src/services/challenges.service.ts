import { prisma } from "../config/prisma";
import { ApiError } from "../utils/apiError";

export async function createChallenge(creatorId: string, data: {
  title: string;
  description?: string;
  type: string;
  goal: Record<string, unknown>;
  startDate: string;
  endDate: string;
}) {
  return prisma.challenge.create({
    data: {
      creatorId,
      title: data.title,
      description: data.description,
      type: data.type,
      goal: data.goal as object,
      startDate: new Date(data.startDate),
      endDate: new Date(data.endDate),
      participants: { create: { userId: creatorId, progress: {} } },
    },
    include: { participants: true },
  });
}

export async function joinChallenge(userId: string, challengeId: string) {
  const challenge = await prisma.challenge.findUnique({ where: { id: challengeId } });
  if (!challenge) throw ApiError.notFound("Challenge not found");
  if (new Date() > challenge.endDate) throw ApiError.badRequest("Challenge has ended");

  return prisma.challengeParticipant.create({
    data: { challengeId, userId, progress: {} },
  });
}

export async function getChallenges(page: number, limit: number) {
  const [data, total] = await Promise.all([
    prisma.challenge.findMany({
      include: { participants: { include: { user: { select: { id: true, displayName: true } } } }, creator: { select: { id: true, displayName: true } } },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.challenge.count(),
  ]);
  return { data, total };
}

export async function getUserChallenges(userId: string) {
  return prisma.challengeParticipant.findMany({
    where: { userId },
    include: { challenge: { include: { creator: { select: { id: true, displayName: true } } } } },
    orderBy: { joinedAt: "desc" },
  });
}
