import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as geminiService from "../services/gemini.service";
import * as foodService from "../services/food.service";
import * as badgesService from "../services/badges.service";
import { parsePagination, paginatedResponse } from "../utils/pagination";

export const analyzeFood = asyncHandler(async (req: Request, res: Response) => {
  const { image_base64 } = req.body;
  const result = await geminiService.analyzeFoodImage(image_base64);
  res.json({ success: true, data: result });
});

export const searchFood = asyncHandler(async (req: Request, res: Response) => {
  const { query } = req.body;
  const result = await geminiService.searchFoodNutrition(query);
  res.json({ success: true, data: result });
});

export const logFood = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const log = await foodService.createFoodLog(req.user.userId, req.body);
  await badgesService.checkAndAwardBadges(req.user.userId);
  res.status(201).json({ success: true, data: log });
});

export const getFoodLogs = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const { page, limit } = parsePagination(req);
  const { data, total } = await foodService.getFoodLogs(req.user.userId, page, limit);
  res.json({ success: true, ...paginatedResponse(data, total, { page, limit }) });
});
