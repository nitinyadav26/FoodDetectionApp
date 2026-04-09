import { Router } from "express";
import * as ctrl from "../controllers/friends.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { friendRequestSchema } from "../validators";

const router = Router();

router.post("/request", authMiddleware, validate(friendRequestSchema), ctrl.sendRequest);
router.post("/accept/:id", authMiddleware, ctrl.acceptRequest);
router.delete("/:id", authMiddleware, ctrl.removeFriend);
router.get("/", authMiddleware, ctrl.getFriends);
router.get("/pending", authMiddleware, ctrl.getPending);

export default router;
