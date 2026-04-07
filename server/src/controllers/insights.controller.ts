import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as insightsService from "../services/insights.service";

export const getWeekly = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const insights = await insightsService.getWeeklyInsights(req.user.userId);
  res.json({ success: true, data: insights });
});
