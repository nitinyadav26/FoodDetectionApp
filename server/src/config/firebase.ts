import * as admin from "firebase-admin";
import { config } from "./index";
import { logger } from "../utils/logger";

let initialized = false;

export function initFirebase(): void {
  if (initialized) return;
  try {
    if (config.firebaseServiceAccountPath) {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const serviceAccount = require(config.firebaseServiceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: config.storageBucket || undefined,
      });
    } else {
      admin.initializeApp({
        storageBucket: config.storageBucket || undefined,
      });
    }
    initialized = true;
    logger.info("Firebase Admin initialized");
  } catch (err) {
    logger.warn("Firebase Admin init skipped (no credentials):", err);
    initialized = true;
  }
}

export async function verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken | null> {
  try {
    return await admin.auth().verifyIdToken(token);
  } catch {
    return null;
  }
}

export { admin };
