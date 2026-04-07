import { Router } from "express";
import * as ctrl from "../controllers/insights.controller";
import { authMiddleware } from "../middleware/auth";

const router = Router();

router.get("/weekly", authMiddleware, ctrl.getWeekly);

export default router;
