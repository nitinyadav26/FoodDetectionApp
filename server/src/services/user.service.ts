import { prisma } from "../config/prisma";

export async function getUserProfile(userId: string) {
  return prisma.user.findUnique({
    where: { id: userId },
    include: { profile: true },
  });
}

export async function updateProfile(userId: string, data: Record<string, unknown>) {
  const { displayName, ...profileData } = data;

  const updates: Promise<unknown>[] = [];

  if (displayName !== undefined) {
    updates.push(prisma.user.update({ where: { id: userId }, data: { displayName: displayName as string } }));
  }

  if (Object.keys(profileData).length > 0) {
    updates.push(prisma.profile.update({ where: { userId }, data: profileData }));
  }

  await Promise.all(updates);

  return getUserProfile(userId);
}

export async function getUserByFirebaseUid(firebaseUid: string) {
  return prisma.user.findUnique({
    where: { firebaseUid },
    include: { profile: true },
  });
}
