import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import * as leaderboardService from "../services/leaderboard.service";

export const getLeaderboard = asyncHandler(async (req: Request, res: Response) => {
  const type = req.params.type as string;
  const period = (req.query.period as string) || "weekly";
  const limit = parseInt(req.query.limit as string) || 50;
  const data = await leaderboardService.getLeaderboard(type, period, limit);
  res.json({ success: true, data });
});
