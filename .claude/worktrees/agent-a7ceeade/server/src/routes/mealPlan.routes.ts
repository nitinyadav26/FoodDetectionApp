import { Router } from "express";
import * as ctrl from "../controllers/mealPlan.controller";
import { authMiddleware } from "../middleware/auth";

const router = Router();

router.get("/", authMiddleware, ctrl.getMealPlan);

export default router;
