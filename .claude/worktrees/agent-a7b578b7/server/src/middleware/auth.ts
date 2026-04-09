import { Request, Response, NextFunction } from "express";
import { verifyIdToken } from "../config/firebase";
import { prisma } from "../config/prisma";
import { ApiError } from "../utils/apiError";

export const authMiddleware = async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      throw ApiError.unauthorized("Missing or invalid Authorization header");
    }

    const token = authHeader.slice(7);
    const decoded = await verifyIdToken(token);
    if (!decoded) {
      throw ApiError.unauthorized("Invalid Firebase token");
    }

    // Find or create user
    let user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid } });
    if (!user) {
      user = await prisma.user.create({
        data: {
          firebaseUid: decoded.uid,
          email: decoded.email || `${decoded.uid}@firebase.local`,
          displayName: decoded.name || null,
          photoUrl: decoded.picture || null,
          profile: { create: {} },
        },
      });
    }

    req.user = { uid: decoded.uid, email: decoded.email, userId: user.id };
    next();
  } catch (err) {
    next(err);
  }
};
