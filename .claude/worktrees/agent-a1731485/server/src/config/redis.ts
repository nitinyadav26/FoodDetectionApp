import Redis from "ioredis";
import { config } from "./index";
import { logger } from "../utils/logger";

let redis: Redis | null = null;

export function getRedis(): Redis {
  if (!redis) {
    redis = new Redis(config.redisUrl, {
      maxRetriesPerRequest: 3,
      retryStrategy(times) {
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
    });
    redis.on("error", (err) => logger.error("Redis error:", err));
    redis.on("connect", () => logger.info("Redis connected"));
  }
  return redis;
}
