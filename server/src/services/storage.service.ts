import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { config } from "../config";
import { logger } from "../utils/logger";

const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 500;

function generateUniqueName(filename: string): string {
  const ext = filename.includes(".") ? filename.substring(filename.lastIndexOf(".")) : ".jpg";
  const uniqueId = crypto.randomUUID();
  const timestamp = Date.now();
  return `food-images/${timestamp}-${uniqueId}${ext}`;
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Upload an image buffer to Firebase Cloud Storage.
 * Falls back to base64 data URL when storageBucket is not configured (dev mode).
 */
export async function uploadImage(buffer: Buffer, filename: string): Promise<string> {
  if (!config.storageBucket) {
    logger.warn("storageBucket not configured — falling back to base64 data URL");
    const base64 = buffer.toString("base64");
    return `data:image/jpeg;base64,${base64}`;
  }

  const objectName = generateUniqueName(filename);

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const bucket = admin.storage().bucket(config.storageBucket);
      const file = bucket.file(objectName);

      await file.save(buffer, {
        metadata: {
          contentType: "image/jpeg",
          metadata: {
            originalName: filename,
            uploadedAt: new Date().toISOString(),
          },
        },
        resumable: false,
      });

      // Make the file publicly readable
      await file.makePublic();

      const publicUrl = `https://storage.googleapis.com/${config.storageBucket}/${objectName}`;
      logger.info(`Image uploaded successfully: ${objectName} (${buffer.length} bytes)`);
      return publicUrl;
    } catch (err) {
      logger.error(`Upload attempt ${attempt}/${MAX_RETRIES} failed for ${objectName}:`, err);
      if (attempt < MAX_RETRIES) {
        await sleep(RETRY_DELAY_MS * attempt);
      } else {
        throw err;
      }
    }
  }

  // Unreachable, but satisfies TypeScript
  throw new Error("Upload failed after all retries");
}

/**
 * Delete an image from Firebase Cloud Storage by its public URL.
 * No-op for base64 data URLs or when storageBucket is not configured.
 */
export async function deleteImage(url: string): Promise<void> {
  if (!config.storageBucket) {
    logger.warn("storageBucket not configured — skipping delete");
    return;
  }

  if (url.startsWith("data:")) {
    logger.debug("Skipping delete for base64 data URL");
    return;
  }

  // Extract the object path from a public URL like:
  // https://storage.googleapis.com/<bucket>/food-images/...
  const prefix = `https://storage.googleapis.com/${config.storageBucket}/`;
  if (!url.startsWith(prefix)) {
    logger.warn(`Cannot extract path from URL: ${url}`);
    return;
  }

  const objectPath = url.substring(prefix.length);

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const bucket = admin.storage().bucket(config.storageBucket);
      await bucket.file(objectPath).delete();
      logger.info(`Image deleted: ${objectPath}`);
      return;
    } catch (err) {
      logger.error(`Delete attempt ${attempt}/${MAX_RETRIES} failed for ${objectPath}:`, err);
      if (attempt < MAX_RETRIES) {
        await sleep(RETRY_DELAY_MS * attempt);
      } else {
        throw err;
      }
    }
  }
}
