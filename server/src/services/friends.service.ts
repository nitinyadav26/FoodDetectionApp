import { prisma } from "../config/prisma";
import { ApiError } from "../utils/apiError";

export async function sendFriendRequest(senderId: string, receiverId: string) {
  if (senderId === receiverId) throw ApiError.badRequest("Cannot friend yourself");

  const existing = await prisma.friend.findFirst({
    where: {
      OR: [
        { senderId, receiverId },
        { senderId: receiverId, receiverId: senderId },
      ],
    },
  });

  if (existing) throw ApiError.badRequest("Friend request already exists");

  return prisma.friend.create({ data: { senderId, receiverId } });
}

export async function acceptFriendRequest(userId: string, friendshipId: string) {
  const friendship = await prisma.friend.findUnique({ where: { id: friendshipId } });
  if (!friendship) throw ApiError.notFound("Friend request not found");
  if (friendship.receiverId !== userId) throw ApiError.forbidden();

  return prisma.friend.update({ where: { id: friendshipId }, data: { status: "accepted" } });
}

export async function removeFriend(userId: string, friendshipId: string) {
  const friendship = await prisma.friend.findUnique({ where: { id: friendshipId } });
  if (!friendship) throw ApiError.notFound("Friendship not found");
  if (friendship.senderId !== userId && friendship.receiverId !== userId) throw ApiError.forbidden();

  return prisma.friend.delete({ where: { id: friendshipId } });
}

export async function getFriends(userId: string) {
  return prisma.friend.findMany({
    where: {
      OR: [
        { senderId: userId, status: "accepted" },
        { receiverId: userId, status: "accepted" },
      ],
    },
    include: {
      sender: { select: { id: true, displayName: true, photoUrl: true } },
      receiver: { select: { id: true, displayName: true, photoUrl: true } },
    },
  });
}

export async function getPendingRequests(userId: string) {
  return prisma.friend.findMany({
    where: { receiverId: userId, status: "pending" },
    include: {
      sender: { select: { id: true, displayName: true, photoUrl: true } },
    },
  });
}
