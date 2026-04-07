import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import { getUserProfile } from "../services/user.service";
import * as geminiService from "../services/gemini.service";

export const getMealPlan = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const days = parseInt(req.query.days as string) || 1;
  const user = await getUserProfile(req.user.userId);
  const profile = user?.profile || {};
  const result = await geminiService.generateMealPlan(profile as Record<string, unknown>, days);
  res.json({ success: true, data: result });
});
