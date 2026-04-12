# FoodSense Architecture

Technical architecture documentation covering the AI provider system, data flow, and server design.

---

## Table of Contents

- [High-Level Overview](#high-level-overview)
- [AI Provider System](#ai-provider-system)
- [APIService Facade](#apiservice-facade)
- [AIProviderManager Fallback Logic](#aiprovidermanager-fallback-logic)
- [Prompt Templates](#prompt-templates)
- [Response Parsing](#response-parsing)
- [Food Detection Pipeline](#food-detection-pipeline)
- [On-Device Inference Flow](#on-device-inference-flow)
- [Vision Pipeline](#vision-pipeline)
- [Gemma Chat Template](#gemma-chat-template)
- [Data Flow Diagrams](#data-flow-diagrams)
- [Server Architecture](#server-architecture)
- [Database Schema](#database-schema)

---

## High-Level Overview

FoodSense is a three-platform system:

```
+------------------+    +------------------+    +------------------+
|   iOS App        |    |   Android App    |    |   Node.js Server |
|   Swift/SwiftUI  |    |   Kotlin/Compose |    |   TypeScript     |
|                  |    |                  |    |                  |
|   llama.cpp      |    |   LiteRT-LM     |    |   Gemini API     |
|   TFLite YOLO    |    |   TFLite/MLKit  |    |   Prisma ORM     |
|   Firebase Auth  |    |   Firebase Auth  |    |   PostgreSQL     |
|   CoreData       |    |   Room v2        |    |   Redis          |
|   HealthKit      |    |   Health Connect |    |   Firebase Admin |
+--------+---------+    +--------+---------+    +--------+---------+
         |                       |                       |
         +----------+------------+----------+------------+
                    |                       |
            Firebase Auth           REST API (HTTPS)
           (authentication)      (social features)
```

- **iOS** has full on-device AI via llama.cpp with Metal GPU acceleration
- **Android** has the same AI provider abstraction but currently uses Gemini Cloud (on-device via LiteRT-LM is planned)
- **Server** is optional -- provides social features (friends, feed, challenges, leaderboard), AI coaching, and meal plans

Each mobile app can function fully offline for core calorie tracking. The server is only needed for social and multiplayer features.

---

## AI Provider System

The AI system is built around a protocol/interface abstraction that lets the app swap between cloud and on-device inference without changing any UI code.

### iOS Protocol (`FoodDetectionApp/AI/AIProvider.swift`)

```swift
protocol AIProvider {
    var providerName: String { get }

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo)
    func searchFood(query: String) async throws -> (name: String, info: NutritionInfo)
    func getCoachAdvice(...) async throws -> String
    func generateMealPlan(...) async throws -> [PlannedMeal]
    func estimatePortion(image: UIImage) async throws -> (name: String, info: NutritionInfo, estimatedGrams: Double)
    func compareBeforeAfter(before: UIImage, after: UIImage) async throws -> String
    func ocrNutritionLabel(image: UIImage) async throws -> (name: String, info: NutritionInfo)
    func generateInsights(...) async throws -> String
}
```

### Android Interface (`android/.../services/ai/AIProvider.kt`)

```kotlin
interface AIProvider {
    val providerName: String

    suspend fun analyzeFood(image: Bitmap): Pair<String, NutritionInfo>
    suspend fun searchFood(query: String): Pair<String, NutritionInfo>
    suspend fun getCoachAdvice(...): String
    suspend fun generateMealPlan(...): List<MealPlanDay>
    suspend fun getWeeklyInsights(...): WeeklyInsight
    suspend fun getQuizQuestion(): QuizQuestion
    suspend fun predictWeight(...): String
}
```

### Implementations

| Class | Platform | Backend | Status |
|---|---|---|---|
| `GeminiCloudProvider` | iOS | Gemini REST API | Production |
| `GemmaLocalProvider` | iOS | llama.cpp via XCFramework | Production |
| `GeminiCloudProvider` | Android | Gemini REST API | Production |
| `GemmaLocalProvider` | Android | LiteRT-LM (stub) | Planned |

---

## APIService Facade

`APIService` (`FoodDetectionApp/APIService.swift`) is a thin facade that preserves backward compatibility. All existing views call `APIService.shared.analyzeFood(image:)` etc. -- they do not need to know which provider is active.

```
  Views (SwiftUI)
       |
       v
  APIService.shared.analyzeFood(image:)
       |
       v
  AIProviderManager.shared.activeProvider   <-- resolves at runtime
       |
       +---> GeminiCloudProvider.analyzeFood(image:)
       |           OR
       +---> GemmaLocalProvider.analyzeFood(image:)
```

The facade simply delegates:

```swift
class APIService {
    static let shared = APIService()

    private var provider: AIProvider {
        get throws {
            guard let p = AIProviderManager.shared.activeProvider else {
                throw ... // "No AI provider configured"
            }
            return p
        }
    }

    func analyzeFood(image: UIImage) async throws -> (name: String, info: NutritionInfo) {
        try await provider.analyzeFood(image: image)
    }
    // ... all other methods delegate the same way
}
```

---

## AIProviderManager Fallback Logic

`AIProviderManager` (`FoodDetectionApp/AI/AIProviderManager.swift`) selects the active provider using a 3-tier fallback:

```
  Tier 1: User-provided Gemini API key (Keychain)
     |
     +---> found? --> GeminiCloudProvider(apiKey: userKey)  [cloudReady]
     |
     v (not found)
  Tier 2: On-device Gemma model downloaded?
     |
     +---> available? --> GemmaLocalProvider(modelPath: ...)  [localReady]
     |
     v (not available)
  Tier 3: Legacy Info.plist keys (PROXY_BASE_URL or GEMINI_API_KEY)
     |
     +---> found? --> GeminiCloudProvider(apiKey/proxy)  [cloudReady]
     |
     v (not found)
  No provider available  [noProvider]
```

States: `initializing`, `cloudReady`, `localReady`, `noProvider`

The manager re-initializes whenever:
- User saves or clears an API key (`setAPIKey()` / `clearAPIKey()`)
- User downloads or deletes the local model
- App launches

### Android Implementation

The Android `AIProviderManager` (`android/.../services/ai/AIProviderManager.kt`) follows the same pattern but uses `EncryptedSharedPreferences` instead of Keychain and `BuildConfig` instead of Info.plist.

---

## Prompt Templates

All prompts are centralized in `PromptTemplates` (`FoodDetectionApp/AI/PromptTemplates.swift`). Each prompt has a `forLocal` parameter that controls formatting:

- **Cloud (`forLocal: false`):** Prompts rely on Gemini's `responseMimeType: "application/json"` to enforce JSON output
- **Local (`forLocal: true`):** Appends explicit instructions: `"IMPORTANT: Return ONLY a valid JSON object. No markdown, no code fences, no explanation text before or after."`

This distinction exists because the Gemini API can enforce JSON schema at the protocol level, while local models need stronger prompt-level guidance to produce clean JSON.

### Example: Food Analysis Prompt

```
Analyze this food image. Identify the dish.
Return a JSON object with these exact keys:
- "Dish": Name of the dish
- "Calories per 100g": Estimated calories (number as string)
- "Carbohydrate per 100g": Estimated carbs (number as string)
- "Protein per 100 gm": Estimated protein (number as string)
- "Fats per 100 gm": Estimated fats (number as string)
- "Healthier Recipe": A short advice to make it healthier
- "Source": "AI Analysis"
- "micros": A dictionary of key micronutrients
Return ONLY the JSON.
```

When `forLocal: true`, appended:

```
IMPORTANT: Return ONLY a valid JSON object. No markdown, no code fences, no explanation text before or after.
```

---

## Response Parsing

`AIResponseParser` (`FoodDetectionApp/AI/AIResponseParser.swift`) handles two parse paths per response type:

### Cloud (Gemini Envelope)

Gemini REST API responses come wrapped in an envelope:

```json
{
  "candidates": [{
    "content": {
      "parts": [{ "text": "{\"Dish\": \"Dal Makhani\", ...}" }]
    },
    "finishReason": "STOP"
  }]
}
```

The parser unwraps `candidates[0].content.parts[0].text`, then proceeds to JSON parsing. It also handles `finishReason` values: `SAFETY`, `RECITATION`, `MAX_TOKENS`.

### Local (Raw Text)

Gemma returns raw text directly. The parser:
1. Strips markdown fences (` ```json ` ... ` ``` `)
2. Finds the first `{` and last `}` to extract JSON boundaries
3. Decodes into `NutritionInfo` via `JSONDecoder`

This robustness is critical because local models sometimes prepend explanatory text before the JSON.

---

## Food Detection Pipeline

```
  Camera Frame
       |
       v
  +-------------------+
  | YOLO TFLite       |     On-device, no network
  | model.tflite      |     94+ Indian food classes
  | (237 MB, LFS)     |     Bounding boxes + confidence
  +--------+----------+
           |
           v
  Detected class name
  + bounding box
           |
           v
  +-------------------+
  | Local DB Lookup   |     indb_foods.json (1000+ items)
  | nutrition_data.json|    Pre-computed nutrition values
  +--------+----------+
           |
           v
  Quick result (offline)
           |
           +---> (optional) Send to AIProvider for refined analysis
                 AIProvider returns full nutrition with micros
```

YOLO provides fast initial detection (< 100ms) for common Indian foods. The AI provider (Gemma or Gemini) provides more detailed analysis when available.

---

## On-Device Inference Flow

The `GemmaLocalProvider` uses the llama.cpp C API through the `llama` Swift module (imported from the XCFramework). The inference pipeline for text:

```
  1. llama_backend_init()              -- Initialize GGML backend
  2. llama_model_load_from_file()      -- Load GGUF model, n_gpu_layers=99
  3. llama_init_from_model()           -- Create context (n_ctx=2048, n_batch=512)
  4. llama_sampler_chain_init()        -- Build sampler chain:
     |  llama_sampler_init_temp(0.7)
     |  llama_sampler_init_top_k(40)
     |  llama_sampler_init_top_p(0.9)
     |  llama_sampler_init_dist(random_seed)
     v
  5. Format prompt with Gemma template
  6. llama_tokenize()                  -- Text to tokens
  7. llama_memory_clear()              -- Clear KV cache
  8. llama_decode() in chunks          -- Process prompt (batch_size=512)
  9. Loop:
     a. llama_sampler_sample()         -- Sample next token
     b. llama_vocab_is_eog()           -- Check for end-of-generation
     c. llama_token_to_piece()         -- Convert token to text
     d. llama_decode() with new token  -- Feed back for next iteration
  10. Return accumulated text
```

Model loading is lazy -- the first inference call triggers loading. Subsequent calls reuse the loaded model, context, and sampler. The model is freed in `deinit`.

---

## Vision Pipeline

For image analysis, `GemmaLocalProvider` uses the mtmd (multimodal) API. This requires the vision projector file (`mmproj-google_gemma-4-E2B-it-f16.gguf`).

```
  1. Convert UIImage to JPEG bytes (quality 0.7)
  2. mtmd_helper_bitmap_init_from_buf()   -- Create bitmap from JPEG
  3. mtmd_input_chunks_init()             -- Initialize chunk container
  4. Format prompt with image marker:
     "<image>\n{prompt text}"
  5. mtmd_tokenize()                      -- Tokenize text + image together
     (produces interleaved text tokens and image embedding chunks)
  6. llama_memory_clear()                 -- Clear KV cache
  7. mtmd_helper_eval_chunks()            -- Evaluate all chunks at once
     (image patches are projected into the model's embedding space)
  8. Standard generation loop (same as text):
     llama_sampler_sample() -> llama_token_to_piece() -> llama_decode()
  9. Return accumulated text
```

If the vision projector is not downloaded, the provider falls back to text-only mode with a prefix: "The user showed a photo of food."

---

## Gemma Chat Template

Gemma 4 uses a specific chat template format:

```
<start_of_turn>system
{system message}<end_of_turn>
<start_of_turn>user
{user message}<end_of_turn>
<start_of_turn>model
```

The `formatPrompt()` method in `GemmaLocalProvider` constructs this format. The system turn is optional. The model turn is left open-ended so the model generates its response.

For vision prompts, the image marker is inserted at the beginning of the user message, before the text prompt.

---

## Data Flow Diagrams

### Food Photo Analysis (iOS)

```
  User taps camera
       |
       v
  CameraView captures UIImage
       |
       v
  APIService.shared.analyzeFood(image:)
       |
       v
  AIProviderManager.shared.activeProvider
       |
       +---> GemmaLocalProvider:
       |       formatPrompt(system: nil, user: analyzeFoodPrompt)
       |       generateWithImage(prompt, image)
       |       mtmd_tokenize + eval + sample loop
       |       AIResponseParser.parseNutritionFromRawText()
       |
       +---> GeminiCloudProvider:
       |       base64-encode image
       |       POST to Gemini REST API
       |       AIResponseParser.parseNutritionFromGeminiEnvelope()
       |
       v
  (name: String, info: NutritionInfo)
       |
       v
  NutritionManager.logFood()
       |
       v
  CoreData persistence + UI update
```

### AI Coach Chat

```
  User types question in CoachView
       |
       v
  APIService.shared.getCoachAdvice(
    userStats, logs, healthData, historyTOON, userQuery)
       |
       v
  Active AIProvider:
    - Builds context from user stats + food logs + health data
    - Cloud: full prompt with system role
    - Local: Gemma template with system turn
       |
       v
  Response string
       |
       v
  Displayed in chat bubble UI
  Persisted in ChatSession (server) or local history
```

### Server Social Flow

```
  User opens Friends tab
       |
       v
  NetworkService.shared.getFriends()
       |
       v
  GET /api/friends
       |
       v
  authMiddleware verifies JWT
       |
       v
  friendsController.list()
       |
       v
  friendsService.getFriends(userId)
       |
       v
  prisma.friend.findMany(where: { status: "accepted" })
       |
       v
  JSON response -> decoded on client
       |
       v
  FriendsView renders list
```

---

## Server Architecture

The server follows a layered architecture:

```
  HTTP Request
       |
       v
  Express Router (routes/*.ts)
       |
       +---> authMiddleware (Firebase token -> req.user.uid)
       +---> validate() middleware (Zod schema)
       +---> rateLimitMiddleware (Redis-backed)
       |
       v
  Controller (controllers/*.ts)
       |  - extracts params, calls service
       |  - wraps in asyncHandler for error catching
       v
  Service (services/*.ts)
       |  - business logic
       |  - calls Prisma or Gemini
       v
  Prisma ORM / Gemini API
       |
       v
  PostgreSQL / Google Cloud
```

### Route Modules

The server mounts 17 route modules in `src/routes/index.ts`:

| Route | Module | Description |
|---|---|---|
| `POST /auth/verify` | `index.ts` | Firebase token verification, user upsert |
| `/api/food/*` | `food.routes.ts` | Analyze, search, log, history |
| `/api/coach/*` | `coach.routes.ts` | AI coaching chat |
| `/api/meal-plan` | `mealPlan.routes.ts` | AI meal plan generation |
| `/api/user/*` | `user.routes.ts` | Profile get/update |
| `/api/friends/*` | `friends.routes.ts` | Request, accept, remove, list |
| `/api/feed/*` | `feed.routes.ts` | Activity feed, reactions |
| `/api/challenges/*` | `challenges.routes.ts` | Create, join, list challenges |
| `/api/leaderboard/*` | `leaderboard.routes.ts` | Ranked scores by type |
| `/api/badges/*` | `badges.routes.ts` | Badge definitions and awards |
| `/api/xp/*` | `xp.routes.ts` | XP balance and awards |
| `/api/leagues` | `leagues.routes.ts` | League tier listings |
| `/api/recipes/*` | `recipes.routes.ts` | Save, list, AI suggestions |
| `/api/insights/*` | `insights.routes.ts` | Weekly nutrition insights |
| `/api/health-report` | `healthReport.routes.ts` | PDF health report |
| `/api/ai/quiz` | `quiz.routes.ts` | Nutrition quiz |
| `/api/notifications` | `notification.routes.ts` | Push token registration |
| `/api/sync` | `sync.routes.ts` | Data sync |

### Gemini Integration (Server)

The server's Gemini integration (`src/config/gemini.ts`) uses the `gemini-2.0-flash` model with retry logic (exponential backoff, 3 retries). Functions:

- `analyzeFoodImage(base64)` -- Image analysis with vision
- `searchFoodNutrition(query)` -- Text-based food search
- `getCoachAdvice(context, query, history)` -- AI coaching
- `generateMealPlan(profile, days)` -- Meal planning
- `generateWeeklyInsights(logs)` -- Nutrition analytics
- `generateHealthReport(logs, profile)` -- Health reports
- `generateQuiz(topic)` -- Quiz generation
- `generateRecipeSuggestions(ingredients)` -- Recipe AI

---

## Database Schema

The Prisma schema (`server/prisma/schema.prisma`) defines 18 models:

```
  User -----> Profile (1:1)
    |
    +-------> FoodLog[] (1:N)
    +-------> UserBadge[] (N:M with Badge)
    +-------> Friend[] (self-referential, sender/receiver)
    +-------> FeedPost[] (1:N)
    +-------> Reaction[] (1:N, on FeedPost)
    +-------> ChallengeParticipant[] (N:M with Challenge)
    +-------> Leaderboard[] (1:N, scored by type/period)
    +-------> LeagueMember[] (N:M with League)
    +-------> Recipe[] (1:N)
    +-------> ChatSession[] (1:N, conversation history)
    +-------> MealPlan[] (1:N)
    +-------> QuizScore[] (1:N)
    +-------> PushToken[] (1:N)
    +-------> Challenge[] (1:N, as creator)
```

Key design decisions:

- **User** is keyed by UUID, with `firebaseUid` as a unique identifier for auth
- **Profile** is separated from User for optional enrichment (age, weight, goals)
- **FoodLog** includes full nutrition data (calories, macros) plus micronutrients as JSON
- **Friend** uses a self-referential pattern with sender/receiver + status (pending/accepted)
- **Leaderboard** is composite-keyed by user+type+period+periodKey for efficient ranking queries
- **ChatSession** stores the full message history as a JSON array for stateful AI conversations
