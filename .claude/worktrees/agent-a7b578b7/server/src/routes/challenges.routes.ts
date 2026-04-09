import { Router } from "express";
import * as ctrl from "../controllers/challenges.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { createChallengeSchema, joinChallengeSchema } from "../validators";

const router = Router();

router.post("/", authMiddleware, validate(createChallengeSchema), ctrl.create);
router.post("/join", authMiddleware, validate(joinChallengeSchema), ctrl.join);
router.get("/", authMiddleware, ctrl.list);
router.get("/mine", authMiddleware, ctrl.myList);

export default router;
