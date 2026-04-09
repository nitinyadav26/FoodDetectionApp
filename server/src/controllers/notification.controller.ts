import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as notificationService from "../services/notification.service";

export const registerToken = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();

  const { token, platform } = req.body;
  const result = await notificationService.registerPushToken(req.user.userId, token, platform);

  res.json({ success: true, data: result });
});
