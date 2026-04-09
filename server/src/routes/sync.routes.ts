import { Router } from "express";
import * as ctrl from "../controllers/sync.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { syncPushSchema, syncPullSchema } from "../validators";

const router = Router();

router.post("/push", authMiddleware, validate(syncPushSchema), ctrl.pushLogs);
router.get("/pull", authMiddleware, validate(syncPullSchema, "query"), ctrl.pullLogs);

export default router;
