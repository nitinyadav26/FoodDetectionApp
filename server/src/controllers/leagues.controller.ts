import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import * as leaguesService from "../services/leagues.service";

export const getLeagues = asyncHandler(async (_req: Request, res: Response) => {
  const leagues = await leaguesService.getLeagues();
  res.json({ success: true, data: leagues });
});
