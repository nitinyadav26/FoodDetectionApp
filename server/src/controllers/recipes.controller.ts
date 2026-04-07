import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import * as recipesService from "../services/recipes.service";
import * as geminiService from "../services/gemini.service";
import { parsePagination, paginatedResponse } from "../utils/pagination";

export const save = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const recipe = await recipesService.saveRecipe(req.user.userId, req.body);
  res.status(201).json({ success: true, data: recipe });
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const { page, limit } = parsePagination(req);
  const mine = req.query.mine === "true" ? req.user?.userId : undefined;
  const { data, total } = await recipesService.getRecipes(page, limit, mine);
  res.json({ success: true, ...paginatedResponse(data, total, { page, limit }) });
});

export const suggest = asyncHandler(async (req: Request, res: Response) => {
  const { ingredients, dietary } = req.body;
  const result = await geminiService.generateRecipeSuggestions(ingredients, dietary);
  res.json({ success: true, data: result });
});
