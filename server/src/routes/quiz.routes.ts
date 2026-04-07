import { Router } from "express";
import * as ctrl from "../controllers/quiz.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { quizSubmitSchema } from "../validators";

const router = Router();

router.get("/", authMiddleware, ctrl.getQuiz);
router.post("/submit", authMiddleware, validate(quizSubmitSchema), ctrl.submitScore);

export default router;
