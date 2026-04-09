import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as challengesService from "../services/challenges.service";
import { parsePagination, paginatedResponse } from "../utils/pagination";

export const create = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const challenge = await challengesService.createChallenge(req.user.userId, req.body);
  res.status(201).json({ success: true, data: challenge });
});

export const join = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const result = await challengesService.joinChallenge(req.user.userId, req.body.challengeId);
  res.json({ success: true, data: result });
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const { page, limit } = parsePagination(req);
  const { data, total } = await challengesService.getChallenges(page, limit);
  res.json({ success: true, ...paginatedResponse(data, total, { page, limit }) });
});

export const myList = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const challenges = await challengesService.getUserChallenges(req.user.userId);
  res.json({ success: true, data: challenges });
});
