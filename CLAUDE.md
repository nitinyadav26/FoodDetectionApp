# FoodSense - CLAUDE.md

## Project Overview

FoodSense is an AI-powered nutrition tracking app for iOS and Android with a Node.js server backend. It detects food from photos (on-device TFLite + cloud Gemini), tracks calories/macros, integrates with health platforms, and includes social/gamification features.

**Repo**: `https://github.com/nitinyadav26/FoodDetectionApp`
**Owner**: Nitin Yadav (`nitinyadav26`)

## Tech Stack

| Layer | iOS | Android | Server |
|-------|-----|---------|--------|
| Language | Swift 5.9+ | Kotlin 1.8+ | TypeScript |
| UI | SwiftUI | Jetpack Compose (Material3) | N/A |
| Architecture | MVVM (singletons) | MVVM (singletons) | Express + Controllers + Services |
| Database | CoreData | Room v2 | PostgreSQL (Prisma ORM) |
| ML/AI | TFLite + Vision | TFLite + ML Kit | Gemini API |
| Auth | Firebase Auth | Firebase Auth | Firebase Admin SDK + JWT |
| Health | HealthKit | Health Connect | N/A |
| BLE | CoreBluetooth | Android BLE | N/A |
| Networking | URLSession | OkHttp | node-fetch |
| Caching | UserDefaults | SharedPreferences | Redis (ioredis) |
| Push | UNNotification | AlarmManager + FCM | FCM via firebase-admin |
| Widget | WidgetKit | Glance AppWidget | N/A |
| CI/CD | GitHub Actions (macOS) | GitHub Actions (Ubuntu) | Docker |

## Directory Structure

```
FoodDetectionApp/
├── FoodDetectionApp/          # iOS app source (52 Swift files)
│   ├── *Manager.swift         # Singleton ObservableObject services
│   ├── *View.swift            # SwiftUI views
│   ├── en.lproj/              # English localization
│   ├── hi.lproj/              # Hindi localization
│   ├── model.tflite           # YOLOv8 food detection (237MB, LFS)
│   ├── indb_foods.json        # Indian food database (1000+ items)
│   └── nutrition_data.json    # Nutrition reference data
├── FoodDetectionAppTests/     # iOS unit tests (2 files)
├── FoodDetectionAppUITests/   # iOS UI tests (2 files)
├── FoodSenseWidget/           # iOS widget extension
├── android/                   # Android app
│   └── app/src/main/java/com/foodsense/android/
│       ├── data/              # Room entities, DAOs, data models
│       ├── services/          # Business logic managers
│       ├── ui/                # Compose screens
│       ├── widget/            # CalorieWidget
│       ├── MainActivity.kt    # Entry point + bottom nav
│       └── FoodSenseApplication.kt  # DI via lazy vals
├── server/                    # Node.js backend (for DigitalOcean)
│   ├── prisma/schema.prisma   # 18 database tables
│   ├── src/
│   │   ├── config/            # Prisma, Redis, Firebase, Gemini
│   │   ├── middleware/        # Auth, rate limit, validation, upload
│   │   ├── routes/            # 15 route modules
│   │   ├── controllers/       # Request handlers
│   │   ├── services/          # Business logic + Gemini calls
│   │   ├── validators/        # Zod schemas
│   │   └── utils/             # Logger, errors, pagination
│   ├── Dockerfile             # Multi-stage Node 20 Alpine
│   └── docker-compose.yml     # postgres:15 + redis:7 + app
├── backend/functions/         # Legacy Firebase Cloud Functions (3 endpoints)
├── docs/                      # Privacy policy, terms, deployment guide PDF
├── store-assets/              # App Store + Play Store descriptions
├── INDB_data/                 # Raw Indian nutrient database files
├── Podfile                    # iOS CocoaPods dependencies
└── .github/workflows/         # CI pipelines (ios.yml, android.yml)
```

## Build & Run Commands

### iOS
```bash
# Install dependencies
cd "/Users/nitin/Desktop/FoodDetectionApp 2" && pod install

# Open in Xcode (use .xcworkspace, NOT .xcodeproj)
open FoodDetectionApp.xcworkspace

# Build for simulator
xcodebuild build -scheme FoodDetectionApp -destination 'platform=iOS Simulator,name=iPhone 16'
```
**Min iOS**: 15.0 | **Xcode**: 26.4+

### Android
```bash
cd android

# Debug build
./gradlew assembleDebug

# Install on connected device/emulator
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Launch
adb shell am start -n com.foodsense.android/.MainActivity

# Run tests
./gradlew testDebugUnitTest
```
**Min SDK**: 26 (Android 8) | **Target SDK**: 34

### Server
```bash
cd server

# Local development
npm install
npx prisma generate
npx prisma migrate dev
npm run dev          # ts-node-dev with hot reload

# Production (Docker)
docker compose up -d
docker compose exec api npx prisma migrate deploy
docker compose exec api npx prisma db seed

# Type check
npx tsc --noEmit

# Health check
curl http://localhost:3000/health
```

## Architecture Patterns

### iOS Patterns
- **Singletons**: All managers use `static let shared = ClassName()` pattern
- **State**: `@Published` properties on `ObservableObject` managers
- **Data binding**: `@ObservedObject` / `@StateObject` in views
- **Persistence**: UserDefaults for settings/XP/badges, CoreData for food logs
- **API calls**: `APIService` for Gemini (proxy-first, direct fallback), `NetworkService` for server API
- **Navigation**: 6-tab `TabView` in `ContentView.swift`

### Android Patterns
- **DI**: Manual lazy initialization in `FoodSenseApplication`, passed as `app` parameter to Composables
- **State**: Compose `mutableStateOf` in service classes (NOT ViewModel/StateFlow)
- **Coroutines**: `CoroutineScope(Dispatchers.IO)` for background work
- **Database**: Room v2 with 6 entities, migration from v1
- **Navigation**: 6-tab `NavigationBar` via `AppTab` enum in `MainActivity.kt`
- **Screens**: `@Composable fun XxxScreen(app: FoodSenseApplication)` pattern

### Server Patterns
- **Route → Controller → Service → Prisma** layered architecture
- **Auth**: Firebase token verification middleware → `req.user.uid`
- **Validation**: Zod schemas via `validate()` middleware
- **Error handling**: `ApiError` class + `asyncHandler` wrapper + global error handler
- **AI**: All Gemini calls go through `config/gemini.ts` with retry logic
- **Rate limiting**: Redis-backed via `rate-limiter-flexible`

## Database Schema (Server - Prisma)

18 tables: `User`, `Profile`, `FoodLog`, `Badge`, `UserBadge`, `League`, `LeagueMember`, `Leaderboard`, `Challenge`, `ChallengeParticipant`, `Friend`, `FeedPost`, `Reaction`, `ChatSession`, `QuizScore`, `MealPlan`, `Recipe`, `PushToken`

## API Endpoints (Server - 35+ routes)

- `POST /auth/verify` — Firebase token → JWT
- `/api/food/*` — analyze, search, log, history (4 routes)
- `/api/user/*` — profile get/update (2 routes)
- `/api/xp/*` — get XP, award XP (2 routes)
- `/api/badges/*` — list, mine, check (3 routes)
- `/api/friends/*` — request, accept, remove, list, pending (5 routes)
- `/api/feed/*` — create post, list, react (3 routes)
- `/api/challenges/*` — create, join, list, mine (4 routes)
- `/api/leaderboard/:type` — ranked scores (1 route)
- `/api/leagues` — tier listings (1 route)
- `/api/coach/chat` — AI coaching (1 route)
- `/api/ai/quiz` — quiz get/submit (2 routes)
- `/api/recipes/*` — save, list, suggest (3 routes)
- `/api/meal-plan` — get meal plan (1 route)
- `/api/insights/weekly` — nutrition insights (1 route)
- `/api/health-report` — PDF report (1 route)
- `GET /health` — health check

## Key Features by Category

### Core (30 - implemented since v1)
Food detection (TFLite + Gemini), barcode scanning, manual logging, calorie/macro tracking, HealthKit/Health Connect, BLE smart scale, streaks, notifications, water tracking, onboarding, Firebase Auth, themes, widgets, localization (en/hi), CI/CD

### Gamification (added April 2026)
- **XP System**: 50 levels, 7 titles (Newbie → Legend), level N = N×100 XP
- **50 Badges**: 6 categories (Streak, Logging, Nutrition, Social, Challenges, Special)
- **XP Awards**: Log food +10, Streak day +5, Badge +25, Win challenge +50, Quiz +15

### Social (added April 2026)
Friends, activity feed with emoji reactions, challenges (create/join/progress), leaderboards (friends/global/weekly/monthly), leagues, QR profile cards

### AI Features (added April 2026)
Voice food logging (Speech framework), persistent nutritionist chat, 7-day meal plans, weekly insights with charts, weight prediction, food quality scoring (0-100), portion estimation, before/after plate analysis, nutrition label OCR, daily quiz

## Environment Variables

### Server (`server/.env`)
```
DATABASE_URL=postgresql://user:pass@postgres:5432/foodsense
REDIS_URL=redis://:password@redis:6379
GEMINI_API_KEY=your-key
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
JWT_SECRET=random-secret
PORT=3000
NODE_ENV=production
```

### Android (`gradle.properties`)
```
PROXY_BASE_URL=https://your-firebase-functions-url
GEMINI_API_KEY=your-key          # local.properties only
SOCIAL_API_BASE_URL=http://10.0.2.2:3000  # emulator → localhost
```

### iOS
- `PROXY_BASE_URL` — set in Xcode Build Settings
- `GEMINI_API_KEY` — set in Build Settings (dev only)
- `GoogleService-Info.plist` — Firebase config file in app bundle

## Testing

### iOS Tests
- `NutritionManagerTests` — calorie budget (Mifflin-St Jeor), macro scaling, food log CRUD
- `APIResponseParsingTests` — Gemini response parsing, JSON extraction, error handling
- `OnboardingUITests` — full onboarding flow
- `FoodLoggingUITests` — tab navigation, settings access

### Android Tests
- `NutritionManagerTest` — same coverage as iOS
- `APIResponseParsingTest` — same coverage as iOS
- `OnboardingUITest` — onboarding flow
- `FoodLoggingUITest` — tab navigation

## Deployment

- **Server**: Docker on DigitalOcean (see `docs/FoodSense_Deployment_Guide.pdf`)
- **iOS**: Xcode Archive → App Store Connect
- **Android**: `./gradlew bundleRelease` → Play Console
- **TFLite model**: Git LFS tracked (`model.tflite`, 237MB). Android uses Play Asset Delivery (`model_pack` module).

## Important Files to Know

| File | Why It Matters |
|------|---------------|
| `FoodDetectionApp/ContentView.swift` | iOS root navigation (6 tabs) |
| `FoodDetectionApp/APIService.swift` | All Gemini API calls (proxy + direct) |
| `FoodDetectionApp/NutritionManager.swift` | Calorie budget formula (Mifflin-St Jeor), food log CRUD |
| `android/...MainActivity.kt` | Android root navigation (6 tabs via AppTab enum) |
| `android/...FoodSenseApplication.kt` | Android DI container (all lazy vals) |
| `android/...FoodSenseDatabase.kt` | Room DB config, all entities + migrations |
| `server/prisma/schema.prisma` | Full database schema |
| `server/src/config/gemini.ts` | Gemini API prompts and response parsing |
| `server/src/routes/index.ts` | All route mounting + /auth/verify |
| `backend/functions/index.js` | Legacy Firebase Functions (still operational) |

## Conventions

- **Commit messages**: Present tense, descriptive. Co-authored with Claude when AI-assisted.
- **Branching**: Feature branches (`feature/xxx`), merge to `main` via PR
- **Localization**: Every user-facing string must have keys in both `en` and `hi` localization files
- **No secrets in code**: API keys via env vars / Build Settings / .env files only
- **Accessibility**: VoiceOver labels (iOS) and contentDescription (Android) on all interactive elements
