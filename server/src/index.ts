import app from "./app";
import { config } from "./config";
import { initFirebase } from "./config/firebase";
import { logger } from "./utils/logger";

async function main() {
  // Initialize Firebase Admin
  initFirebase();

  app.listen(config.port, () => {
    logger.info(`FoodSense server running on port ${config.port} [${config.nodeEnv}]`);
  });
}

main().catch((err) => {
  logger.error("Failed to start server:", err);
  process.exit(1);
});
