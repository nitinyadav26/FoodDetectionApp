<div align="center">

# FoodSense

### The first open-source calorie tracker running Gemma 4 on your phone

[![Gemma 4](https://img.shields.io/badge/Gemma_4-E2B_on--device-4285F4?logo=google&logoColor=white)](https://ai.google.dev/gemma)
[![llama.cpp](https://img.shields.io/badge/llama.cpp-b8763-black?logo=cplusplus&logoColor=white)](https://github.com/ggerganov/llama.cpp)
[![Platform](https://img.shields.io/badge/Platform-iOS_15%2B_|_Android_8%2B-green)](.)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Server](https://img.shields.io/badge/Server-Node.js_20-339933?logo=nodedotjs&logoColor=white)](server/)

**Snap a photo. Get calories. No cloud required.**

FoodSense runs Google's Gemma 4 E2B model directly on your iPhone via llama.cpp with Metal acceleration. Your food photos never leave your device. Optionally connect to Gemini Cloud for higher accuracy, or self-host the full server for social features.

[Get Started](#quick-start) | [Architecture](docs/ARCHITECTURE.md) | [AI Guide](docs/AI_GUIDE.md) | [Contributing](CONTRIBUTING.md)

</div>

---

## Why FoodSense?

|  | **FoodSense** | Cal AI | MyFitnessPal |
|---|---|---|---|
| **Price** | Free forever | $70/year | $80/year |
| **Privacy** | On-device AI, your data stays local | Cloud-only | Cloud-only |
| **Offline** | Full analysis without internet | No | Manual only |
| **Open Source** | Apache 2.0 | No | No |
| **On-device AI** | Gemma 4 via llama.cpp | No | No |
| **Cloud AI** | Gemini (bring your own key) | Proprietary | N/A |
| **Indian Food DB** | 1000+ items with regional data | Limited | Limited |
| **Health Integration** | HealthKit + Health Connect | Apple Health only | Both |

---

## Features

**Core**
- Camera food detection -- point, shoot, get calories in seconds
- On-device YOLOv8 model trained on 94+ Indian food classes
- On-device Gemma 4 E2B for nutrition analysis without internet
- Optional Gemini Cloud with your own API key
- Barcode scanning for packaged foods
- Manual food search and logging
- Calorie and macro tracking with daily/weekly charts
- HealthKit (iOS) and Health Connect (Android) sync
- BLE smart scale integration
- Water intake tracking
- Home screen widgets (WidgetKit / Glance)
- Localization: English and Hindi
- Dark mode and theme customization

**AI-Powered**
- Voice food logging via Speech framework
- AI nutritionist chat with conversation history
- 7-day meal plan generation
- Weekly nutrition insights with charts
- Food quality scoring (0-100)
- Portion size estimation from photos
- Before/after plate analysis
- Nutrition label OCR
- Weight trend prediction
- Daily nutrition quiz

**Social & Gamification**
- Friends system with QR code profile cards
- Activity feed with emoji reactions
- Create and join nutrition challenges
- Leaderboards (friends, global, weekly, monthly)
- League tiers based on XP
- 50 badges across 6 categories
- XP system with 50 levels and 7 titles (Newbie to Legend)

---

## Architecture

```
                         FoodSense Architecture
  +------------------------------------------------------------------+
  |                                                                    |
  |   Mobile Client (iOS / Android)                                    |
  |                                                                    |
  |   +-------------------+    +------------------+                    |
  |   |   Camera Input    |    |   Text / Voice   |                    |
  |   +--------+----------+    +--------+---------+                    |
  |            |                        |                               |
  |            v                        v                               |
  |   +-------------------+    +------------------+                    |
  |   |   YOLO TFLite     |    |   Food Search    |                    |
  |   | (94+ food classes)|    | (text query)     |                    |
  |   +--------+----------+    +--------+---------+                    |
  |            |                        |                               |
  |            +----------+-------------+                               |
  |                       |                                             |
  |                       v                                             |
  |            +---------------------+                                  |
  |            |   AIProvider        |                                  |
  |            |   (protocol)        |                                  |
  |            +---+-------------+---+                                  |
  |                |             |                                      |
  |          +-----v-----+ +----v-----------+                          |
  |          | Gemma 4    | | Gemini Cloud   |                         |
  |          | E2B Local  | | (user API key) |                         |
  |          | llama.cpp  | | REST API       |                         |
  |          | Metal GPU  | |                |                         |
  |          +-----------+ +----------------+                          |
  |                |             |                                      |
  |                +------+------+                                      |
  |                       v                                             |
  |            +---------------------+                                  |
  |            |  Nutrition Info     |                                  |
  |            |  calories, macros,  |                                  |
  |            |  micros, score      |                                  |
  |            +----------+----------+                                  |
  |                       |                                             |
  |                       v                                             |
  |            +---------------------+                                  |
  |            | CoreData / Room     |                                  |
  |            | Local Food Log      |                                  |
  |            +---------------------+                                  |
  |                                                                    |
  +----------------------------+---------------------------------------+
                               |
                    (optional) | HTTPS
                               v
                +-----------------------------+
                |   Node.js Server            |
                |   Express + Prisma          |
                |   PostgreSQL + Redis        |
                |   DigitalOcean / Docker     |
                |                             |
                |   Social, Leaderboards,     |
                |   Challenges, Friends,      |
                |   Feed, Meal Plans,         |
                |   AI Coach, Quiz            |
                +-----------------------------+
```

---

## On-Device AI Specs

| Property | Value |
|---|---|
| Model | Google Gemma 4 E2B Instruct |
| Quantization | Q4_K_M (4-bit) |
| Size on disk | ~3.2 GB |
| Runtime | llama.cpp (C/C++) via XCFramework |
| GPU acceleration | Metal (Apple GPU, all layers offloaded) |
| Vision | mtmd (multimodal) with f16 projector (~860 MB) |
| Context window | 2048 tokens |
| Batch size | 512 |
| Sampling | temp=0.7, top_k=40, top_p=0.9 |
| Inference speed | ~15-25 tok/s on iPhone 15 Pro |
| Memory usage | ~4 GB peak (model + KV cache) |
| Minimum device | iPhone 12 / iPad Air 4 (6 GB RAM) |

---

## Quick Start

### iOS

**Prerequisites:** Xcode 15+, CocoaPods, ~4 GB free disk space for model

```bash
# Clone the repo
git clone https://github.com/nitinyadav26/FoodDetectionApp.git
cd FoodDetectionApp

# Install CocoaPods dependencies
pod install

# Open in Xcode (always use .xcworkspace)
open FoodDetectionApp.xcworkspace

# Build and run on device or simulator
# Scheme: FoodDetectionApp
# Minimum deployment: iOS 15.0
```

> **Note:** The `llama.xcframework` must be built from source or obtained separately.
> See [docs/BUILDING.md](docs/BUILDING.md) for step-by-step instructions on building
> the XCFramework from llama.cpp with Metal and vision (mtmd) support.

> **Note:** `model.tflite` (the YOLOv8 food detection model, 237 MB) is proprietary
> and tracked via Git LFS. It is **not** included in public clones. The app will still
> work using Gemma or Gemini for food analysis -- YOLO provides faster initial detection
> but is not required.

After building, go to **Settings > On-Device AI** to download the Gemma 4 model
directly to your device. Alternatively, enter a Gemini API key for cloud-based analysis.

### Android

**Prerequisites:** Android Studio, JDK 17+, Min SDK 26

```bash
cd android

# Debug build
./gradlew assembleDebug

# Install on connected device/emulator
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Launch
adb shell am start -n com.foodsense.android/.MainActivity
```

> Android on-device inference (via LiteRT-LM) is in development. Currently, Android
> uses Gemini Cloud. Enter your API key in Settings.

### Server (Optional -- required for social features)

**Prerequisites:** Docker, Docker Compose

```bash
cd server

# Copy and edit environment variables
cp .env.example .env
# Edit .env with your database password, Redis password, Gemini key, JWT secret

# Start all services
docker compose up -d

# Run database migrations
docker compose exec app npx prisma migrate deploy

# Seed initial data (badges, leagues)
docker compose exec app npx prisma db seed

# Verify
curl http://localhost:3000/health
```

See [docs/SERVER_SETUP.md](docs/SERVER_SETUP.md) for production deployment with HTTPS, nginx, and security hardening.

---

## Tech Stack

| Layer | iOS | Android | Server |
|---|---|---|---|
| Language | Swift 5.9+ | Kotlin 1.8+ | TypeScript |
| UI | SwiftUI | Jetpack Compose (Material 3) | N/A |
| Architecture | MVVM (singletons) | MVVM (singletons) | Express + Controllers + Services |
| Database | CoreData | Room v2 | PostgreSQL (Prisma ORM) |
| On-device AI | llama.cpp + Metal | LiteRT-LM (planned) | N/A |
| Cloud AI | Gemini API | Gemini API | Gemini API |
| Food Detection | TFLite (YOLOv8) | TFLite + ML Kit | Gemini Vision |
| Auth | Firebase Auth | Firebase Auth | Firebase Admin SDK + JWT |
| Health | HealthKit | Health Connect | N/A |
| Networking | URLSession | OkHttp | node-fetch |
| Caching | UserDefaults / Keychain | SharedPreferences / Encrypted SP | Redis (ioredis) |
| Push | UNNotification | AlarmManager + FCM | FCM via firebase-admin |
| Widget | WidgetKit | Glance AppWidget | N/A |
| CI/CD | GitHub Actions (macOS) | GitHub Actions (Ubuntu) | Docker |

---

## Project Structure

```
FoodDetectionApp/
├── FoodDetectionApp/              # iOS app source
│   ├── AI/                        # AIProvider system
│   │   ├── AIProvider.swift       #   Protocol definition
│   │   ├── AIProviderManager.swift#   3-tier fallback provider selection
│   │   ├── GeminiCloudProvider.swift# Gemini REST API implementation
│   │   ├── GemmaLocalProvider.swift #  On-device llama.cpp implementation
│   │   ├── ModelDownloadManager.swift# GGUF model download + validation
│   │   ├── APIKeyManager.swift    #   Keychain storage for API keys
│   │   ├── PromptTemplates.swift  #   Centralized prompt strings
│   │   └── AIResponseParser.swift #   Cloud envelope + raw text parsing
│   ├── *Manager.swift             # Singleton ObservableObject services
│   ├── *View.swift                # SwiftUI views
│   ├── APIService.swift           # Facade (delegates to active AIProvider)
│   ├── en.lproj/ hi.lproj/       # Localization (English, Hindi)
│   ├── model.tflite               # YOLO food detection (LFS, proprietary)
│   └── indb_foods.json            # Indian food database (1000+ items)
├── llama.xcframework/             # llama.cpp static library (built from source)
│   ├── ios-arm64/                 #   Device binary + headers
│   └── ios-arm64-simulator/       #   Simulator binary + headers
├── android/                       # Android app
│   └── app/src/main/java/com/foodsense/android/
│       ├── services/ai/           # AIProvider system (Kotlin mirror)
│       ├── data/                  # Room entities, DAOs, data models
│       ├── services/              # Business logic managers
│       ├── ui/                    # Compose screens
│       └── widget/                # CalorieWidget
├── server/                        # Node.js backend
│   ├── prisma/schema.prisma       # 18 database tables
│   ├── src/
│   │   ├── config/                # Prisma, Redis, Firebase, Gemini
│   │   ├── middleware/            # Auth, rate limit, validation
│   │   ├── routes/                # 17 route modules
│   │   ├── controllers/           # Request handlers
│   │   ├── services/              # Business logic
│   │   └── validators/            # Zod schemas
│   ├── Dockerfile                 # Multi-stage Node 20 Alpine
│   └── docker-compose.yml         # postgres:15 + redis:7 + app
├── .github/workflows/             # CI (ios.yml, android.yml, server.yml)
├── docs/                          # Documentation
└── Podfile                        # iOS CocoaPods
```

---

## Documentation

| Document | Description |
|---|---|
| [BUILDING.md](docs/BUILDING.md) | Build everything from source, including the llama.cpp XCFramework |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical architecture, AI provider system, data flow |
| [AI_GUIDE.md](docs/AI_GUIDE.md) | How to use cloud vs on-device AI, model details, prompt engineering |
| [SERVER_SETUP.md](docs/SERVER_SETUP.md) | Server deployment with Docker, HTTPS, and security |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute, code style, PR process |

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas where help is especially welcome:

- Android on-device inference (porting llama.cpp / LiteRT-LM integration)
- Additional food databases for non-Indian cuisines
- Localization for more languages
- UI/UX improvements
- Server API test coverage
- Documentation and tutorials

---

## License

```
Copyright 2026 Nitin Yadav

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

The Gemma 4 model is subject to [Google's Gemma Terms of Use](https://ai.google.dev/gemma/terms).

---

<div align="center">

If FoodSense helps you, consider giving it a star.

It helps others discover the project and motivates continued development.

**[Star this repo](https://github.com/nitinyadav26/FoodDetectionApp)**

</div>
