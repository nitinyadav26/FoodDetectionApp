import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as healthReportService from "../services/healthReport.service";

export const getReport = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const report = await healthReportService.generateReport(req.user.userId);
  res.json({ success: true, data: report });
});
