import { Router } from "express";
import * as ctrl from "../controllers/leaderboard.controller";
import { authMiddleware } from "../middleware/auth";

const router = Router();

router.get("/:type", authMiddleware, ctrl.getLeaderboard);

export default router;
