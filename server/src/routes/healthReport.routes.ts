import { Router } from "express";
import * as ctrl from "../controllers/healthReport.controller";
import { authMiddleware } from "../middleware/auth";

const router = Router();

router.get("/", authMiddleware, ctrl.getReport);

export default router;
