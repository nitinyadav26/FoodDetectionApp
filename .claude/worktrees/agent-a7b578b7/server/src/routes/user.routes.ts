import { Router } from "express";
import * as ctrl from "../controllers/user.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { profileUpdateSchema } from "../validators";

const router = Router();

router.get("/profile", authMiddleware, ctrl.getProfile);
router.put("/profile", authMiddleware, validate(profileUpdateSchema), ctrl.updateProfile);

export default router;
