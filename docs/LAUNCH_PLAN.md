# FoodSense Open Source Launch — Complete Content & Action Plan

**Author:** Nitin Yadav
**Date:** April 12, 2026
**Window:** Gemma 4 launched April 2 — you have ~2 weeks of peak hype

---

## Executive Summary

You built the first open-source calorie tracker running Google's Gemma 4 on-device via llama.cpp on iPhone. No cloud, no API key, no subscription. This is a Cal AI killer positioned for the privacy-conscious, developer, and Indian food markets. This document contains every post, every word, and the exact sequence to make it viral.

---

## DAY 1 — REPOSITORY PREPARATION

### Action Items
- [ ] Clean the repo (remove .claude/worktrees/, check for leaked keys)
- [ ] Add `.gitignore` entries for `model.tflite`, `GemmaModel/`
- [ ] Create `LICENSE` (Apache 2.0)
- [ ] Create `README.md` (content below)
- [ ] Create `CONTRIBUTING.md`
- [ ] Add `screenshots/` with 5-6 app screenshots
- [ ] Record a 30-second screen recording of scanning food on iPhone
- [ ] Push to GitHub as public repo
- [ ] Add GitHub topics: `gemma`, `gemma-4`, `llama-cpp`, `on-device-ai`, `calorie-tracker`, `food-detection`, `ios`, `android`, `swiftui`, `jetpack-compose`, `nutrition`, `indian-food`

### README.md — Complete Content

```markdown
<p align="center">
  <img src="screenshots/hero.png" width="300" alt="FoodSense scanning food">
</p>

<h1 align="center">FoodSense</h1>
<p align="center">
  <strong>The first open-source calorie tracker running Gemma 4 entirely on your phone.</strong><br>
  No cloud. No API key. No subscription. Your food photos never leave your device.
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#comparison">vs Cal AI</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Gemma_4-On_Device-blue" alt="Gemma 4">
  <img src="https://img.shields.io/badge/llama.cpp-b8763-green" alt="llama.cpp">
  <img src="https://img.shields.io/badge/Platform-iOS_|_Android-orange" alt="Platform">
  <img src="https://img.shields.io/badge/License-Apache_2.0-red" alt="License">
</p>

---

## Why FoodSense?

| | FoodSense | Cal AI | MyFitnessPal |
|---|---|---|---|
| **Price** | Free forever | $8/week ($416/yr) | $80/year |
| **AI Model** | Gemma 4 E2B (on-device) | Cloud API | Manual entry |
| **Privacy** | Photos never leave phone | Uploaded to cloud | N/A |
| **Offline** | Full functionality | Requires internet | Partial |
| **Open Source** | Apache 2.0 | Proprietary | Proprietary |
| **Indian Food** | 94+ dishes detected | Limited | Manual search |

## Features

### Core
- 📸 **Scan food with camera** → instant calorie/macro estimation via Gemma 4
- 🍛 **94+ Indian food classes** detected on-device via YOLO
- 🤖 **AI Health Coach** — personalized nutrition advice from Gemma 4
- 📋 **7-day meal plan generation** — AI-powered, tailored to your goals
- 📊 **Weekly nutrition insights** with charts and trends
- ⚡ **Works completely offline** after one-time 3.2 GB model download

### Health Integration
- Apple HealthKit (iOS) / Health Connect (Android)
- BLE smart scale integration
- Water tracking, step counting, sleep monitoring

### Social & Gamification
- Friends, challenges, leaderboards
- 50 achievement badges across 6 categories
- XP system with 50 levels (Newbie → Legend)

### Technical
- SwiftUI (iOS) + Jetpack Compose (Android) + Node.js (Server)
- AIProvider architecture: seamlessly switch between Gemma (local) and Gemini (cloud)
- Custom-built llama.cpp XCFramework with multimodal vision support
- Dual-provider: user can enter their own Gemini API key OR use on-device Gemma

## How It Works

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
│  📸 Camera    │ ──→ │  YOLO TFLite    │ ──→ │  "Biryani"       │
│  (real-time) │     │  (94+ classes)   │     │  detected        │
└──────────────┘     └─────────────────┘     └────────┬─────────┘
                                                       │
                                                       ▼
                                              ┌──────────────────┐
                                              │  Gemma 4 E2B     │
                                              │  (on-device)     │
                                              │  via llama.cpp   │
                                              ├──────────────────┤
                                              │  Calories: 250   │
                                              │  Protein: 12g    │
                                              │  Carbs: 35g      │
                                              │  Fats: 8g        │
                                              └──────────────────┘
```

**Two AI models, both on your phone:**
1. **YOLO TFLite** — real-time food detection (instant, 94+ Indian food classes)
2. **Gemma 4 E2B** — nutrition analysis, coaching, meal plans (via llama.cpp with Metal GPU)

**Optional cloud path:** Enter your own Gemini API key in Settings for cloud-powered analysis with higher accuracy.

## On-Device AI Details

| Spec | Value |
|------|-------|
| Model | Gemma 4 E2B (Q4_K_M quantization) |
| Size | 3.2 GB (+ 940 MB vision projector) |
| Runtime | llama.cpp b8763 (custom XCFramework) |
| Vision | multimodal via clip/mtmd |
| GPU | Metal (Apple A12+) / Vulkan (Android) |
| Speed | ~5-15 sec per analysis on iPhone 16 Pro |
| Memory | ~3.5 GB RAM during inference |
| Offline | 100% after model download |

## Quick Start

### iOS
```bash
git clone https://github.com/nitinyadav26/FoodDetectionApp.git
cd FoodDetectionApp
pod install
open FoodDetectionApp.xcworkspace
# Build and run (Cmd+R)
# Go to Settings → On-Device AI → Download Model (3.2 GB)
# Optional: Download Vision Support (940 MB) for image analysis
```

### Android
```bash
cd android
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### Server (for social features)
```bash
cd server
npm install && npx prisma generate && npm run dev
```

> **Note:** The YOLO TFLite model (`model.tflite`) is proprietary and not included in the repo.
> The app works without it — Gemma 4 handles food analysis independently.
> To train your own YOLO model, see [docs/TRAINING_YOLO.md](docs/TRAINING_YOLO.md).

## Tech Stack

| Layer | iOS | Android | Server |
|-------|-----|---------|--------|
| Language | Swift 5.9+ | Kotlin 1.8+ | TypeScript |
| UI | SwiftUI | Jetpack Compose (Material3) | N/A |
| On-Device AI | llama.cpp + YOLO TFLite | llama.cpp + YOLO TFLite | N/A |
| Cloud AI | Gemini API (optional) | Gemini API (optional) | Gemini API |
| Database | CoreData | Room v2 | PostgreSQL (Prisma) |
| Auth | Firebase Auth | Firebase Auth | Firebase Admin + JWT |

## Architecture

```
Consumer Views (ContentView, CoachView, ScanScreen, etc.)
         │
         ▼
    APIService (thin facade — preserves all call sites)
         │
         ▼
    AIProviderManager (selects active provider)
         │
    ┌────┴────┐
    ▼         ▼
GeminiCloud  GemmaLocal
Provider     Provider
(user key)   (llama.cpp)
```

The `AIProvider` protocol allows seamless switching between cloud and on-device inference.
All 8 AI methods (analyzeFood, searchFood, getCoachAdvice, generateMealPlan, estimatePortion, compareBeforeAfter, ocrNutritionLabel, generateInsights) work with both providers.

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Good first issues:**
- [ ] Add more Indian food classes to YOLO training data
- [ ] Improve Gemma prompt templates for better JSON output
- [ ] Add support for more languages (currently English + Hindi)
- [ ] Optimize llama.cpp memory usage for 6GB devices
- [ ] Add Android on-device Gemma support via NDK

## License

Apache 2.0 — see [LICENSE](LICENSE)

The YOLO TFLite food detection model is proprietary and not included in this repository.
Gemma 4 model weights are subject to Google's Gemma Terms of Use.

## Star History

If you think on-device AI is the future of mobile apps, give us a ⭐!

---

**Built with ❤️ by [Nitin Yadav](https://github.com/nitinyadav26)**
```

---

## DAY 2 — LAUNCH POSTS (Copy-Paste Ready)

### POST 1: Twitter/X Thread

**Tweet 1 (Hook — must stop the scroll):**
```
I built a calorie tracker that runs Google's Gemma 4 entirely on an iPhone.

No cloud. No API key. No $8/week subscription like Cal AI.

Your food photos never leave your device.

It's open source. Here's the full story 🧵
```

**Tweet 2:**
```
The app uses two AI models, both running 100% on your phone:

1. YOLO — detects 94+ Indian food classes in real-time from camera
2. Gemma 4 E2B — estimates calories, protein, carbs, fats

Both work completely offline after a one-time 3.2 GB download.
```

**Tweet 3:**
```
I built a custom llama.cpp XCFramework from source (b8763) with vision support.

Gemma 4 loads all 36 layers onto the Apple A18 Pro GPU via Metal.

Here's what it looks like in the Xcode console:

[ATTACH: screenshot of the console logs showing model loading, Metal GPU init, layer offloading]
```

**Tweet 4:**
```
Cal AI charges $8/week ($416/year) and uploads every food photo to their servers.

FoodSense: free, open source, everything stays on your phone.

[ATTACH: comparison table image]
```

**Tweet 5:**
```
The architecture supports both on-device AND cloud:

• No API key? → Gemma 4 runs locally
• Have a Gemini key? → Cloud for better accuracy
• User chooses in Settings

The AIProvider protocol makes switching seamless.
```

**Tweet 6:**
```
The full source code is on GitHub:

github.com/nitinyadav26/FoodDetectionApp

Apache 2.0 licensed. Fork it. Improve it. Ship it.

⭐ if you think on-device AI is the future of mobile apps.

@GoogleDeepMind @ggaborgyatni
```

**Tags to use:** #Gemma4 #OnDeviceAI #llama_cpp #OpenSource #iOS #CalorieTracker #AI #Privacy

**People to tag:** @GoogleDeepMind @ggaborgyatni (llama.cpp creator) @bartlowtho (GGUF quantizer) @Google @HuggingFace

---

### POST 2: Reddit r/LocalLLaMA

**Title:**
```
I built a calorie tracker running Gemma 4 E2B on iPhone via llama.cpp — scans food photos on-device, no cloud needed [Open Source]
```

**Body:**
```
Hey r/LocalLLaMA,

I've been building a nutrition tracking app called FoodSense and just shipped
what I believe is the first iOS app running Gemma 4 E2B on-device for a
real-world use case.

**What it does:**
- Point your camera at food → Gemma 4 analyzes the image and returns
  calories, protein, carbs, fats
- Works completely offline (3.2 GB model + 940 MB vision projector)
- All 36 layers running on Apple A18 Pro GPU via Metal
- Also has a YOLO model for instant Indian food detection (94+ classes)
- AI health coach, meal plan generation, nutrition insights — all on-device

**Technical details:**
- Model: google_gemma-4-E2B-it-Q4_K_M.gguf (3.2 GB)
- Vision: mmproj-google_gemma-4-E2B-it-f16.gguf (940 MB)
- Framework: Custom llama.xcframework built from source (b8763) with
  clip/mtmd vision support
- Chat template: <start_of_turn>user\n...<end_of_turn>\n<start_of_turn>model\n
- Platform: iOS 15+ (Metal GPU), Android (coming)
- Architecture: AIProvider protocol with GeminiCloudProvider (optional API key)
  and GemmaLocalProvider (llama.cpp)

**Why I built this:**
Cal AI charges $8/week and sends every food photo to their cloud. I wanted a
privacy-first alternative where nothing leaves my phone. Also, Indian food is
poorly supported by Western calorie trackers — so I trained a YOLO model on
94+ Indian dishes.

**Challenges I solved:**
1. Gemma 4 E4B (7.5B params) was too big for iPhone 16 Pro's 8 GB RAM —
   switched to E2B (4.6B effective params)
2. The pre-built llama.cpp XCFramework didn't include vision headers — had to
   compile from source with mtmd/clip
3. Q4_K_S quantization + all GPU layers = OOM — used Q4_K_M with tuned
   n_gpu_layers
4. Gemma's chat template was wrong (outputting <unused28>) — fixed by wrapping
   prompts in <start_of_turn>...<end_of_turn>
5. HuggingFace URLs had wrong filenames — validated GGUF magic bytes to
   catch corrupt downloads

**GitHub:** https://github.com/nitinyadav26/FoodDetectionApp

Apache 2.0 licensed. The YOLO TFLite model is proprietary (trained on my own
dataset) but everything else is open.

Happy to answer any questions about the implementation!

[ATTACH: 2-3 screenshots of the app scanning food with "Powered by On-Device AI" badge]
```

---

### POST 3: Hacker News — Show HN

**Title:**
```
Show HN: Open-source calorie tracker running Gemma 4 on iPhone (no cloud, no subscription)
```

**Body:**
```
I built FoodSense, a calorie tracking app that runs Google's Gemma 4 E2B
entirely on-device using llama.cpp. No API key needed, no subscription,
food photos never leave your phone.

How it works:
- YOLO model detects 94+ Indian food classes from camera (instant)
- Gemma 4 E2B estimates nutrition via llama.cpp with Metal GPU acceleration
- Custom-built llama.cpp XCFramework with multimodal vision support (clip/mtmd)
- Dual provider: on-device Gemma OR cloud Gemini (user's choice)

Why: Cal AI charges $8/week and uploads photos to their cloud. I wanted
a free, private, open-source alternative that works offline.

Tech: Swift/SwiftUI + Kotlin/Compose + llama.cpp b8763 + Gemma 4 E2B GGUF

GitHub: https://github.com/nitinyadav26/FoodDetectionApp
```

**Best time to post:** Tuesday or Wednesday, 11:00 AM ET (highest HN traffic)

---

### POST 4: Reddit r/iOSProgramming

**Title:**
```
I integrated Google's Gemma 4 into an iOS app using a custom-built llama.cpp XCFramework with vision support — here's how
```

**Body:**
```
Just shipped an iOS app that runs Gemma 4 E2B (4.6B parameters) on-device via
llama.cpp. Wanted to share the technical journey since there's very little
documentation on doing this.

**The setup:**
- llama.cpp b8763 compiled from source for iOS arm64 + simulator arm64
- Built with CMake: `-DCMAKE_SYSTEM_NAME=iOS -DGGML_METAL=ON`
- Created XCFramework from static libraries (libllama.a + libmtmd.a + libggml*.a)
- Added module.modulemap for Swift interop
- Vision support via the mtmd (multimodal) API — can process images alongside text

**Key APIs used:**
- `llama_model_load_from_file()` → loads the GGUF model
- `llama_model_get_vocab()` → required in b8763+ for tokenize/detokenize
- `mtmd_init_from_file()` → loads the vision projector
- `mtmd_helper_bitmap_init_from_buf()` → converts JPEG bytes to model input
- `mtmd_helper_eval_chunks()` → processes text + image together
- `llama_sampler_sample()` → generates tokens

**Gotchas:**
1. llama.cpp b8763 changed the API — `llama_tokenize()` now takes `llama_vocab*`
   not `llama_model*`. Caused EXC_BAD_ACCESS until I figured it out.
2. Q4_K_S (5.2 GB) + all GPU layers = OOM on iPhone 16 Pro (8 GB RAM).
   Switched to E2B model (3.2 GB) which fits entirely on GPU.
3. The pre-built XCFramework from GitHub releases doesn't include vision
   headers. Had to compile from source.
4. Gemma needs a specific chat template or it outputs garbage tokens.

**Performance:**
- Model load: ~8 seconds (memory-mapped from SSD)
- Inference: ~5-15 seconds per response
- All 36 layers on Apple A18 Pro GPU via Metal
- ~3.5 GB RAM usage during inference

Full source: https://github.com/nitinyadav26/FoodDetectionApp

The relevant files:
- `FoodDetectionApp/AI/GemmaLocalProvider.swift` — the llama.cpp wrapper
- `FoodDetectionApp/AI/AIProvider.swift` — the provider protocol
- `FoodDetectionApp/AI/AIProviderManager.swift` — provider selection
```

---

### POST 5: LinkedIn

```
🚀 I just open-sourced FoodSense — the first calorie tracking app running
Google's Gemma 4 AI model entirely on your iPhone.

No cloud servers. No API keys. No $8/week subscription.

Your food photos are analyzed by a 4.6-billion-parameter AI model running
directly on your phone's GPU. Nothing ever leaves your device.

Why I built this:
→ Cal AI charges $416/year and uploads every photo to their cloud
→ Indian food is poorly supported by Western calorie trackers
→ I wanted to prove that on-device AI can replace cloud subscriptions

What's under the hood:
• Gemma 4 E2B running via llama.cpp with Metal GPU acceleration
• Custom YOLO model detecting 94+ Indian food classes
• SwiftUI (iOS) + Jetpack Compose (Android) + Node.js backend
• Full AIProvider architecture for seamless cloud/local switching

The entire source code is on GitHub under Apache 2.0:
👉 https://github.com/nitinyadav26/FoodDetectionApp

If you believe in privacy-first AI and open source, I'd appreciate a ⭐ on
the repo.

#OpenSource #AI #Gemma4 #OnDeviceAI #iOS #AndroidDev #CalorieTracking
#HealthTech #Privacy #LLM #GoogleAI
```

---

### POST 6: Product Hunt

**Tagline:**
```
Free, open-source Cal AI alternative with on-device Gemma 4
```

**Description:**
```
FoodSense is the first calorie tracking app running Google's Gemma 4 AI
model entirely on your iPhone. No cloud, no API key, no subscription.

📸 Scan food → Get instant calories, protein, carbs, fats
🍛 94+ Indian food classes detected on-device
🤖 AI Health Coach with personalized advice
📋 7-day meal plan generation
🔒 100% private — photos never leave your device
💰 Free forever — no subscription

Built with llama.cpp, custom-compiled for iOS with multimodal vision support.
The entire source code is open under Apache 2.0.
```

**Topics:** Artificial Intelligence, Health & Fitness, Open Source, Privacy, Developer Tools

---

### POST 7: Dev.to / Medium Blog Post

**Title:**
```
How I Built a Cal AI Killer That Runs Gemma 4 Entirely on an iPhone
```

**Outline:**
```
1. Introduction
   - Cal AI charges $8/week for cloud-based calorie tracking
   - I built a free, open-source alternative that runs on-device
   - Gemma 4 E2B + llama.cpp + Metal GPU = real AI on your phone

2. The Architecture
   - AIProvider protocol abstraction
   - GeminiCloudProvider (optional, user provides key)
   - GemmaLocalProvider (llama.cpp, runs offline)
   - APIService facade (zero changes to UI code)

3. Building llama.cpp for iOS with Vision
   - Cloning and cross-compiling for arm64
   - Adding mtmd/clip for multimodal image analysis
   - Creating the XCFramework with module.modulemap
   - The gotchas (API changes, memory limits, chat template)

4. Memory Optimization on iPhone
   - Q4_K_S (5.2 GB) → OOM on 8 GB iPhone
   - Switched to E2B (3.2 GB) — fits with 2.3 GB headroom
   - All 36 layers on GPU via Metal
   - Chunked prompt decoding for long inputs

5. The YOLO Food Detector
   - 94+ Indian food classes trained on custom dataset
   - Real-time detection from camera feed
   - Combined with Gemma for nutrition estimation

6. Results
   - ~5-15 seconds per food analysis
   - Works completely offline
   - Free vs $416/year for Cal AI
   - Open source under Apache 2.0

7. What's Next
   - Android on-device AI support
   - Fine-tuning Gemma on food-specific data
   - More cuisines beyond Indian food
   - Community contributions welcome

GitHub: [link]
```

---

## DAY 3 — PRODUCT HUNT + FOLLOW-UP

### Product Hunt Launch
- Schedule for 12:01 AM PT (to get full 24 hours)
- Share the PH link on Twitter/LinkedIn immediately
- Ask friends/colleagues to upvote in the first hour (critical for ranking)

### Follow-up tweets
```
The response to FoodSense has been incredible.

Here are the most-asked questions:

Q: How accurate is Gemma 4 vs cloud?
A: Approximate — think ±20% on calories. Good enough for tracking, not for clinical use.

Q: Will it work on my iPhone 12?
A: Yes! Needs iOS 15+ and 6 GB+ RAM. Best on A14 Bionic or newer.

Q: Can I train my own food model?
A: The YOLO model is proprietary, but we're working on a training guide. PRs welcome!
```

---

## WEEK 1-2 — COMMUNITY GROWTH

### GitHub Actions
- [ ] Respond to every issue within 24 hours
- [ ] Label issues: `good-first-issue`, `bug`, `enhancement`, `help-wanted`
- [ ] Merge first external PR and celebrate it publicly
- [ ] Add ROADMAP.md with planned features

### Content Calendar
| Day | Platform | Content |
|-----|----------|---------|
| Mon | Twitter | Technical deep-dive thread (building llama.cpp for iOS) |
| Tue | Reddit | Cross-post to r/MachineLearning |
| Wed | Dev.to | Full blog post published |
| Thu | Twitter | Demo video comparing FoodSense vs Cal AI |
| Fri | LinkedIn | "Week 1 stats" post (stars, forks, downloads) |
| Sat | YouTube | 15-min code walkthrough video |
| Sun | Reddit | r/androiddev post about Android plans |

### Metrics to Track
- GitHub stars (goal: 1,000 in first week)
- GitHub forks
- Twitter impressions
- Reddit upvotes
- Hacker News points
- Product Hunt upvotes

---

## KEY ASSETS NEEDED

### Screenshots (create before Day 1)
1. App scanning Indian food with "Powered by On-Device AI" badge
2. Settings → AI Configuration showing "Active Provider: On-Device AI"
3. AI Coach chat showing nutrition advice
4. Comparison table (FoodSense vs Cal AI vs MyFitnessPal)
5. Xcode console showing Gemma 4 loading on Metal GPU
6. Model Download screen showing 3.2 GB progress

### Videos
1. **30-second demo**: Scan food → see calories (no internet indicator visible)
2. **Side-by-side**: Cal AI (loading, cloud, $$$) vs FoodSense (instant, local, free)
3. **15-minute walkthrough**: Architecture, code, how to contribute

---

## FINAL CHECKLIST BEFORE GOING PUBLIC

- [ ] No API keys, server IPs, or secrets in committed code
- [ ] `model.tflite` is in `.gitignore` and NOT in the repo
- [ ] `GemmaModel/` directory is in `.gitignore`
- [ ] README.md is polished with screenshots
- [ ] LICENSE file exists (Apache 2.0)
- [ ] CONTRIBUTING.md exists
- [ ] All screenshots are taken and placed in `screenshots/`
- [ ] Demo video is recorded
- [ ] Repository is set to Public on GitHub
- [ ] GitHub topics are added
- [ ] Twitter thread is drafted
- [ ] Reddit posts are drafted
- [ ] HN submission is ready
- [ ] Product Hunt listing is prepared

---

**Remember: Ship NOW. Gemma 4 hype has a shelf life. Every day you wait, someone else gets closer to doing this. You did it first. Own it.**
