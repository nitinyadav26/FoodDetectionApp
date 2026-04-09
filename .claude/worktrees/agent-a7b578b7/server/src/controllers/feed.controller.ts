import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as feedService from "../services/feed.service";
import { parsePagination, paginatedResponse } from "../utils/pagination";

export const createPost = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const post = await feedService.createPost(req.user.userId, req.body);
  res.status(201).json({ success: true, data: post });
});

export const getFeed = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const { page, limit } = parsePagination(req);
  const { data, total } = await feedService.getFeed(req.user.userId, page, limit);
  res.json({ success: true, ...paginatedResponse(data, total, { page, limit }) });
});

export const addReaction = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const postId = req.params.postId as string;
  const reaction = await feedService.addReaction(req.user.userId, postId, req.body.type);
  res.json({ success: true, data: reaction });
});
