import { prisma } from "../config/prisma";

export async function getLeagues() {
  return prisma.league.findMany({
    include: { members: { include: { user: { select: { id: true, displayName: true, photoUrl: true } } } } },
    orderBy: { tier: "asc" },
  });
}

export async function getUserLeague(userId: string) {
  const member = await prisma.leagueMember.findFirst({
    where: { userId },
    include: { league: true },
    orderBy: { joinedAt: "desc" },
  });
  return member;
}

export async function assignLeague(userId: string, xp: number) {
  const league = await prisma.league.findFirst({
    where: { minXp: { lte: xp }, OR: [{ maxXp: { gte: xp } }, { maxXp: null }] },
    orderBy: { tier: "desc" },
  });

  if (!league) return null;

  return prisma.leagueMember.upsert({
    where: { leagueId_userId: { leagueId: league.id, userId } },
    update: { xp },
    create: { leagueId: league.id, userId, xp },
    include: { league: true },
  });
}
