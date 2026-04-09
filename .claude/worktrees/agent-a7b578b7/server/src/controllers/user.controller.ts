import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as userService from "../services/user.service";

export const getProfile = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const user = await userService.getUserProfile(req.user.userId);
  res.json({ success: true, data: user });
});

export const updateProfile = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const user = await userService.updateProfile(req.user.userId, req.body);
  res.json({ success: true, data: user });
});
