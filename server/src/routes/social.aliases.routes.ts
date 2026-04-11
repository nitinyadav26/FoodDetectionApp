/**
 * Social aliases router.
 *
 * Exposes legacy path conventions used by older client builds:
 *   - iOS clients: /social/* (e.g. /social/friends)
 *   - Android clients: /api/v1/social/* (e.g. /api/v1/social/friends)
 *
 * The iOS and Android social features will be migrated to call the
 * canonical /api/* endpoints directly. Until those rebuilds ship,
 * this file provides:
 *   1. Mount aliases for the path-shape-compatible endpoints (re-uses
 *      the existing routers verbatim — no middleware injection, no
 *      body transformation).
 *   2. Four narrow shim handlers that translate path-/query-shape
 *      mismatches by mutating req before delegating to the existing
 *      controllers. Body shapes are NOT rewritten.
 *
 * Endpoints whose body shape, HTTP method, or feature surface differ
 * from the canonical routes are intentionally NOT aliased here. They
 * will be fixed on the client side, not the server side.
 */
import { Router, Request, Response, NextFunction } from "express";

import friendsRoutes from "./friends.routes";
import feedRoutes from "./feed.routes";
import challengesRoutes from "./challenges.routes";

import * as friendsCtrl from "../controllers/friends.controller";
import * as challengesCtrl from "../controllers/challenges.controller";
import * as leaderboardCtrl from "../controllers/leaderboard.controller";

import { authMiddleware } from "../middleware/auth";

const router = Router();

// ────────────────────────────────────────────────────────────────────
// Mount aliases — iOS convention (/social/*)
// Only path-shape-compatible sub-paths work through these mounts;
// everything else naturally 404s.
// ────────────────────────────────────────────────────────────────────
router.use("/social/friends", friendsRoutes);
router.use("/social/feed", feedRoutes);
router.use("/social/challenges", challengesRoutes);

// ────────────────────────────────────────────────────────────────────
// Mount aliases — Android convention (/api/v1/social/*)
// ────────────────────────────────────────────────────────────────────
router.use("/api/v1/social/friends", friendsRoutes);
router.use("/api/v1/social/feed", feedRoutes);
router.use("/api/v1/social/challenges", challengesRoutes);

// ────────────────────────────────────────────────────────────────────
// Shim 1 (iOS): GET /social/leaderboard?scope=&period=
//   → /api/leaderboard/:type   (where :type = scope)
//
// iOS sends scope ∈ {"friends", "global"} (a category, not a period).
// The `period` query param passes through unchanged because the
// underlying controller already reads it from req.query.
// ────────────────────────────────────────────────────────────────────
const IOS_LEADERBOARD_SCOPES = ["friends", "global"] as const;

router.get(
  "/social/leaderboard",
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const scope = typeof req.query.scope === "string" ? req.query.scope : undefined;
    if (!scope || !IOS_LEADERBOARD_SCOPES.includes(scope as typeof IOS_LEADERBOARD_SCOPES[number])) {
      res.status(400).json({
        success: false,
        error: `'scope' query parameter is required and must be one of: ${IOS_LEADERBOARD_SCOPES.join(", ")}`,
      });
      return;
    }
    (req.params as { type: string }).type = scope;
    await leaderboardCtrl.getLeaderboard(req, res, next);
  },
);

// ────────────────────────────────────────────────────────────────────
// Shim 2 (iOS): POST /social/challenges/:id/join
//   → POST /api/challenges/join with body { challengeId: <:id> }
// ────────────────────────────────────────────────────────────────────
router.post(
  "/social/challenges/:id/join",
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    req.body = { ...(req.body ?? {}), challengeId: req.params.id };
    await challengesCtrl.join(req, res, next);
  },
);

// ────────────────────────────────────────────────────────────────────
// Shim 3 (Android): GET /api/v1/social/friend-requests
//   → GET /api/friends/pending
// ────────────────────────────────────────────────────────────────────
router.get("/api/v1/social/friend-requests", authMiddleware, friendsCtrl.getPending);

// ────────────────────────────────────────────────────────────────────
// Shim 4 (Android): POST /api/v1/social/friend-requests/:id
//   → POST /api/friends/accept/:id  (accept only — decline is a
//     non-goal until clients are rewritten)
// ────────────────────────────────────────────────────────────────────
router.post("/api/v1/social/friend-requests/:id", authMiddleware, friendsCtrl.acceptRequest);

export default router;
