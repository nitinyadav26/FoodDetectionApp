import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as friendsService from "../services/friends.service";

export const sendRequest = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const result = await friendsService.sendFriendRequest(req.user.userId, req.body.friendId);
  res.status(201).json({ success: true, data: result });
});

export const acceptRequest = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const result = await friendsService.acceptFriendRequest(req.user.userId, req.params.id as string);
  res.json({ success: true, data: result });
});

export const removeFriend = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  await friendsService.removeFriend(req.user.userId, req.params.id as string);
  res.json({ success: true, message: "Friend removed" });
});

export const getFriends = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const friends = await friendsService.getFriends(req.user.userId);
  res.json({ success: true, data: friends });
});

export const getPending = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const pending = await friendsService.getPendingRequests(req.user.userId);
  res.json({ success: true, data: pending });
});
