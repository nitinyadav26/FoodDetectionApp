import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as syncService from "../services/sync.service";

export const pushLogs = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const { logs } = req.body;
  const result = await syncService.upsertFoodLogs(req.user.userId, logs);
  res.json({ success: true, data: { upserted: result.length } });
});

export const pullLogs = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const since = req.query.since as string | undefined;
  const logs = await syncService.getLogsSince(req.user.userId, since);
  res.json({ success: true, data: logs });
});
