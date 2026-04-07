import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as badgesService from "../services/badges.service";

export const getAll = asyncHandler(async (_req: Request, res: Response) => {
  const badges = await badgesService.getAllBadges();
  res.json({ success: true, data: badges });
});

export const getUserBadges = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const badges = await badgesService.getUserBadges(req.user.userId);
  res.json({ success: true, data: badges });
});

export const checkBadges = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const awarded = await badgesService.checkAndAwardBadges(req.user.userId);
  res.json({ success: true, data: { awarded } });
});
