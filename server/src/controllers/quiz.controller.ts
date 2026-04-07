import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as quizService from "../services/quiz.service";

export const getQuiz = asyncHandler(async (req: Request, res: Response) => {
  const topic = (req.query.topic as string) || "general nutrition";
  const quiz = await quizService.generateQuiz(topic);
  res.json({ success: true, data: quiz });
});

export const submitScore = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const result = await quizService.submitQuizScore(req.user.userId, req.body.topic, req.body.score, req.body.total);
  res.json({ success: true, data: result });
});
