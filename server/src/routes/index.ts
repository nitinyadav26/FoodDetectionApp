import { Router, Request, Response } from "express";
import { verifyIdToken } from "../config/firebase";
import { prisma } from "../config/prisma";
import { validate } from "../middleware/validate";
import { verifyTokenSchema } from "../validators";

import foodRoutes from "./food.routes";
import coachRoutes from "./coach.routes";
import mealPlanRoutes from "./mealPlan.routes";
import userRoutes from "./user.routes";
import friendsRoutes from "./friends.routes";
import feedRoutes from "./feed.routes";
import challengesRoutes from "./challenges.routes";
import leaderboardRoutes from "./leaderboard.routes";
import badgesRoutes from "./badges.routes";
import xpRoutes from "./xp.routes";
import leaguesRoutes from "./leagues.routes";
import recipesRoutes from "./recipes.routes";
import insightsRoutes from "./insights.routes";
import healthReportRoutes from "./healthReport.routes";
import quizRoutes from "./quiz.routes";
import notificationRoutes from "./notification.routes";

const router = Router();

// Auth verify endpoint
router.post("/auth/verify", validate(verifyTokenSchema), async (req: Request, res: Response) => {
  const { token } = req.body;
  const decoded = await verifyIdToken(token);
  if (!decoded) {
    res.status(401).json({ success: false, error: "Invalid token" });
    return;
  }

  let user = await prisma.user.findUnique({
    where: { firebaseUid: decoded.uid },
    include: { profile: true },
  });

  if (!user) {
    user = await prisma.user.create({
      data: {
        firebaseUid: decoded.uid,
        email: decoded.email || `${decoded.uid}@firebase.local`,
        displayName: decoded.name || null,
        photoUrl: decoded.picture || null,
        profile: { create: {} },
      },
      include: { profile: true },
    });
  }

  res.json({ success: true, data: user });
});

// API routes
router.use("/api/food", foodRoutes);
router.use("/api/coach", coachRoutes);
router.use("/api/meal-plan", mealPlanRoutes);
router.use("/api/user", userRoutes);
router.use("/api/friends", friendsRoutes);
router.use("/api/feed", feedRoutes);
router.use("/api/challenges", challengesRoutes);
router.use("/api/leaderboard", leaderboardRoutes);
router.use("/api/badges", badgesRoutes);
router.use("/api/xp", xpRoutes);
router.use("/api/leagues", leaguesRoutes);
router.use("/api/recipes", recipesRoutes);
router.use("/api/insights", insightsRoutes);
router.use("/api/health-report", healthReportRoutes);
router.use("/api/ai/quiz", quizRoutes);
router.use("/api/notifications", notificationRoutes);

export default router;
