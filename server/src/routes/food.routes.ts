import { Router } from "express";
import * as ctrl from "../controllers/food.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { analyzeFoodSchema, searchFoodSchema, logFoodSchema } from "../validators";

const router = Router();

router.post("/analyze", authMiddleware, validate(analyzeFoodSchema), ctrl.analyzeFood);
router.post("/search", authMiddleware, validate(searchFoodSchema), ctrl.searchFood);
router.post("/log", authMiddleware, validate(logFoodSchema), ctrl.logFood);
router.get("/logs", authMiddleware, ctrl.getFoodLogs);

export default router;
