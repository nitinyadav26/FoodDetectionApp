import { Router } from "express";
import * as ctrl from "../controllers/badges.controller";
import { authMiddleware } from "../middleware/auth";

const router = Router();

router.get("/", ctrl.getAll);
router.get("/mine", authMiddleware, ctrl.getUserBadges);
router.post("/check", authMiddleware, ctrl.checkBadges);

export default router;
