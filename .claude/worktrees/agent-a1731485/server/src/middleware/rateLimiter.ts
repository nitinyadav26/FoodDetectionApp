import { Request, Response, NextFunction } from "express";
import { getRedis } from "../config/redis";
import { ApiError } from "../utils/apiError";

interface RateLimitOptions {
  windowMs: number;
  max: number;
  keyPrefix?: string;
}

export function rateLimiter(options: RateLimitOptions) {
  const { windowMs, max, keyPrefix = "rl" } = options;

  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      const redis = getRedis();
      const key = `${keyPrefix}:${req.user?.uid || req.ip}`;
      const windowSec = Math.ceil(windowMs / 1000);

      const current = await redis.incr(key);
      if (current === 1) {
        await redis.expire(key, windowSec);
      }

      if (current > max) {
        throw ApiError.tooMany("Rate limit exceeded. Please try again later.");
      }

      next();
    } catch (err) {
      if (err instanceof ApiError) {
        next(err);
      } else {
        // If Redis is down, let the request through
        next();
      }
    }
  };
}
