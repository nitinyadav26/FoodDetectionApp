import { Router } from "express";
import * as ctrl from "../controllers/recipes.controller";
import { authMiddleware } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { saveRecipeSchema, recipeSuggestSchema } from "../validators";

const router = Router();

router.post("/", authMiddleware, validate(saveRecipeSchema), ctrl.save);
router.get("/", authMiddleware, ctrl.list);
router.post("/suggest", authMiddleware, validate(recipeSuggestSchema), ctrl.suggest);

export default router;
