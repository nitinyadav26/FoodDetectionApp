import { prisma } from "../config/prisma";

export async function createPost(userId: string, data: {
  type: string;
  content?: string;
  imageUrl?: string;
  metadata?: Record<string, unknown>;
}) {
  return prisma.feedPost.create({
    data: { userId, type: data.type, content: data.content, imageUrl: data.imageUrl, metadata: data.metadata ? (data.metadata as object) : undefined },
    include: { user: { select: { id: true, displayName: true, photoUrl: true } } },
  });
}

export async function getFeed(userId: string, page: number, limit: number) {
  // Get user's friends
  const friends = await prisma.friend.findMany({
    where: {
      OR: [
        { senderId: userId, status: "accepted" },
        { receiverId: userId, status: "accepted" },
      ],
    },
  });

  const friendIds = friends.map((f) =>
    f.senderId === userId ? f.receiverId : f.senderId
  );
  friendIds.push(userId);

  const [data, total] = await Promise.all([
    prisma.feedPost.findMany({
      where: { userId: { in: friendIds } },
      include: {
        user: { select: { id: true, displayName: true, photoUrl: true } },
        reactions: true,
      },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.feedPost.count({ where: { userId: { in: friendIds } } }),
  ]);

  return { data, total };
}

export async function addReaction(userId: string, postId: string, type: string) {
  return prisma.reaction.upsert({
    where: { userId_postId: { userId, postId } },
    update: { type },
    create: { userId, postId, type },
  });
}
