import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as xpService from "../services/xp.service";

export const getStatus = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const status = await xpService.getXpStatus(req.user.userId);
  res.json({ success: true, data: status });
});

export const addXp = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const result = await xpService.addXp(req.user.userId, req.body.amount);
  res.json({ success: true, data: result });
});
