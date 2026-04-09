const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

// The Gemini API key is stored in Firebase Functions config:
//   firebase functions:config:set gemini.key="YOUR_KEY_HERE"
// Or use environment variables in Cloud Run.
const GEMINI_MODEL = "gemini-flash-latest";

function getGeminiKey() {
  return (
    (functions.config().gemini && functions.config().gemini.key) ||
    process.env.GEMINI_API_KEY
  );
}

function geminiUrl(key) {
  return `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${key}`;
}

// Rate limiting: simple in-memory tracker (per-instance, resets on cold start).
// For production, use Firestore or Redis for distributed rate limiting.
const requestCounts = {};
const DAILY_LIMIT = 200;
const MIN_INTERVAL_MS = 500;

function checkRateLimit(userId) {
  const now = Date.now();
  const today = new Date().toISOString().slice(0, 10);

  if (!requestCounts[userId]) {
    requestCounts[userId] = { count: 0, date: today, lastRequest: 0 };
  }

  const tracker = requestCounts[userId];

  // Reset daily counter
  if (tracker.date !== today) {
    tracker.count = 0;
    tracker.date = today;
  }

  // Check minimum interval
  if (now - tracker.lastRequest < MIN_INTERVAL_MS) {
    return { allowed: false, reason: "Too many requests. Please wait a moment." };
  }

  // Check daily limit
  if (tracker.count >= DAILY_LIMIT) {
    return { allowed: false, reason: "Daily request limit reached. Try again tomorrow." };
  }

  tracker.count++;
  tracker.lastRequest = now;
  return { allowed: true };
}

// Validate request has required fields
function validateAuth(req) {
  // For now, accept all requests from the app.
  // TODO: Add Firebase App Check validation:
  //   const appCheckToken = req.header("X-Firebase-AppCheck");
  //   await admin.appCheck().verifyToken(appCheckToken);
  return true;
}

// POST /api/v1/analyze-food
// Body: { image_base64: string }
exports.analyzeFood = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const userId = req.header("X-User-Id") || req.ip;
  const rateCheck = checkRateLimit(userId);
  if (!rateCheck.allowed) {
    return res.status(429).json({ error: rateCheck.reason });
  }

  try {
    validateAuth(req);
    const { image_base64 } = req.body;
    if (!image_base64) {
      return res.status(400).json({ error: "image_base64 is required" });
    }

    const apiKey = getGeminiKey();
    if (!apiKey) {
      return res.status(500).json({ error: "Gemini API key not configured" });
    }

    const promptText = `Analyze this food image. Identify the dish and estimate nutrition per 100g.
Return JSON with keys: Dish, "Calories per 100g", "Carbohydrate per 100g", "Protein per 100 gm", "Fats per 100 gm", "Healthier Recipe", "Source", micros (optional dict of micronutrients).`;

    const geminiBody = {
      contents: [
        {
          parts: [
            { text: promptText },
            { inline_data: { mime_type: "image/jpeg", data: image_base64 } },
          ],
        },
      ],
      generationConfig: { responseMimeType: "application/json" },
    };

    const response = await fetch(geminiUrl(apiKey), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiBody),
    });

    const data = await response.json();
    return res.json(data);
  } catch (err) {
    console.error("analyzeFood error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

// POST /api/v1/search-food
// Body: { query: string }
exports.searchFood = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const userId = req.header("X-User-Id") || req.ip;
  const rateCheck = checkRateLimit(userId);
  if (!rateCheck.allowed) {
    return res.status(429).json({ error: rateCheck.reason });
  }

  try {
    validateAuth(req);
    const { query } = req.body;
    if (!query) {
      return res.status(400).json({ error: "query is required" });
    }

    const apiKey = getGeminiKey();
    if (!apiKey) {
      return res.status(500).json({ error: "Gemini API key not configured" });
    }

    const promptText = `Provide nutrition information for: "${query}".
Return JSON with keys: Dish, "Calories per 100g", "Carbohydrate per 100g", "Protein per 100 gm", "Fats per 100 gm", "Healthier Recipe", "Source", micros (optional dict of micronutrients).`;

    const geminiBody = {
      contents: [{ parts: [{ text: promptText }] }],
      generationConfig: { responseMimeType: "application/json" },
    };

    const response = await fetch(geminiUrl(apiKey), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiBody),
    });

    const data = await response.json();
    return res.json(data);
  } catch (err) {
    console.error("searchFood error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

// POST /api/v1/coach-advice
// Body: { context: string, query: string }
exports.coachAdvice = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const userId = req.header("X-User-Id") || req.ip;
  const rateCheck = checkRateLimit(userId);
  if (!rateCheck.allowed) {
    return res.status(429).json({ error: rateCheck.reason });
  }

  try {
    validateAuth(req);
    const { context, query } = req.body;
    if (!query) {
      return res.status(400).json({ error: "query is required" });
    }

    const apiKey = getGeminiKey();
    if (!apiKey) {
      return res.status(500).json({ error: "Gemini API key not configured" });
    }

    const systemPrompt =
      "You are a friendly and motivating professional health coach. " +
      "Use the provided health and nutrition data to give personalized advice.";

    const fullPrompt = `${systemPrompt}\n\n--- User Context ---\n${context || "No context provided."}\n\n--- User Question ---\n${query}`;

    const geminiBody = {
      contents: [{ parts: [{ text: fullPrompt }] }],
      generationConfig: {
        maxOutputTokens: 1000,
        temperature: 0.7,
      },
    };

    const response = await fetch(geminiUrl(apiKey), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiBody),
    });

    const data = await response.json();
    return res.json(data);
  } catch (err) {
    console.error("coachAdvice error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});
