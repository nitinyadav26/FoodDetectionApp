import { Router } from "express";
import * as ctrl from "../controllers/coach.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { coachChatSchema } from "../validators";

const router = Router();

router.post("/chat", authMiddleware, validate(coachChatSchema), ctrl.chat);

export default router;
