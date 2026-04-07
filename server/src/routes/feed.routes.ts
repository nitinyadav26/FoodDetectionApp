import { Router } from "express";
import * as ctrl from "../controllers/feed.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { feedPostSchema, reactionSchema } from "../validators";

const router = Router();

router.post("/", authMiddleware, validate(feedPostSchema), ctrl.createPost);
router.get("/", authMiddleware, ctrl.getFeed);
router.post("/:postId/reaction", authMiddleware, validate(reactionSchema), ctrl.addReaction);

export default router;
