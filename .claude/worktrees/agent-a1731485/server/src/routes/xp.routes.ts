import { Router } from "express";
import * as ctrl from "../controllers/xp.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { addXpSchema } from "../validators";

const router = Router();

router.get("/", authMiddleware, ctrl.getStatus);
router.post("/add", authMiddleware, validate(addXpSchema), ctrl.addXp);

export default router;
