import { Router } from "express";
import * as ctrl from "../controllers/leagues.controller";
import { authMiddleware } from "../middleware/auth";

const router = Router();

router.get("/", authMiddleware, ctrl.getLeagues);

export default router;
