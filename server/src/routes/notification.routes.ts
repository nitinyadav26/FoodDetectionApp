import { Router } from "express";
import * as ctrl from "../controllers/notification.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { registerPushTokenSchema } from "../validators";

const router = Router();

router.post("/register-token", authMiddleware, validate(registerPushTokenSchema), ctrl.registerToken);

export default router;
