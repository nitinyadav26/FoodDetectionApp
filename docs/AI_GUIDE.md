# FoodSense AI Guide

Everything you need to know about the AI system in FoodSense -- from using it to extending it.

---

## Table of Contents

- [Overview](#overview)
- [Using Gemini Cloud](#using-gemini-cloud)
- [Using On-Device Gemma](#using-on-device-gemma)
- [Downloading the Vision Projector](#downloading-the-vision-projector)
- [Feature Support by Provider](#feature-support-by-provider)
- [Adding a New AI Feature](#adding-a-new-ai-feature)
- [Prompt Engineering Tips](#prompt-engineering-tips)
- [Model Comparison](#model-comparison)
- [Memory Requirements](#memory-requirements)
- [Known Limitations](#known-limitations)

---

## Overview

FoodSense supports two AI backends through the `AIProvider` abstraction:

| Provider | Backend | Requires Internet | Image Analysis | Cost |
|---|---|---|---|---|
| **Gemini Cloud** | Google Gemini REST API | Yes | Yes (via API) | Free tier / pay-per-use |
| **Gemma On-Device** | Gemma 4 E2B via llama.cpp | No | Yes (with vision projector) | Free forever |

The `AIProviderManager` automatically selects the best available provider using a 3-tier fallback:

1. User-provided Gemini API key (highest priority, cloud)
2. Downloaded on-device Gemma model (offline capable)
3. Legacy Info.plist/BuildConfig keys (fallback cloud)

You can use both providers -- the system will always prefer the user's explicit choice (API key) over the local model.

---

## Using Gemini Cloud

### Getting an API key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key (starts with `AI`, 39+ characters)

### Entering the key in FoodSense

1. Open FoodSense
2. Go to **Settings** (gear icon in tab bar)
3. Scroll to **AI Configuration**
4. Tap **Gemini API Key**
5. Paste your key
6. The app validates the key by calling the Gemini models endpoint
7. On success, the status shows "Gemini Cloud" as the active provider

### How it works internally

When Gemini Cloud is active:

- `GeminiCloudProvider` sends requests to `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent`
- Image analysis: images are JPEG-compressed at 50% quality, base64-encoded, and sent as `inline_data`
- JSON output: uses `responseMimeType: "application/json"` for structured responses
- Rate limiting: 1 request/second, 100 requests/day (client-side)
- Retry logic: exponential backoff (2^attempt seconds), up to 3 retries on 5xx errors

### Proxy mode

If a `PROXY_BASE_URL` is configured (via Info.plist on iOS or BuildConfig on Android), the cloud provider routes requests through your backend proxy instead of calling Gemini directly. This is useful for:

- Hiding the API key from the client
- Adding server-side rate limiting
- Logging and analytics

---

## Using On-Device Gemma

### Downloading the model

1. Open FoodSense
2. Go to **Settings > On-Device AI**
3. Tap **Download Gemma 4 E2B Model**
4. Wait for the download (~3.2 GB)
5. The app validates the GGUF magic bytes after download
6. Status changes to "On-Device AI" as active provider

### What happens during download

The `ModelDownloadManager` handles the process:

1. Creates a directory in Application Support (`GemmaModel/`)
2. Downloads `google_gemma-4-E2B-it-Q4_K_M.gguf` from HuggingFace
3. Validates the first 4 bytes match GGUF magic (`0x47475546`)
4. Moves the file to `GemmaModel/google_gemma-4-E2B-it-Q4_K_M.gguf`
5. Triggers `AIProviderManager.initialize()` to switch to local mode

### Manual download

You can also download the model file directly and place it on the device:

```bash
# Download (~3.2 GB)
wget https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/google_gemma-4-E2B-it-Q4_K_M.gguf
```

Place in the app's Application Support directory at:
`Library/Application Support/GemmaModel/google_gemma-4-E2B-it-Q4_K_M.gguf`

### How it works internally

When the on-device provider is active:

1. **First inference:** Loads the GGUF model file, initializes llama.cpp context with Metal GPU (`n_gpu_layers=99`)
2. **Subsequent inferences:** Reuses the loaded model (lazy initialization)
3. **Text generation:** Tokenize prompt -> decode in batches of 512 -> sample tokens with temp=0.7/top_k=40/top_p=0.9
4. **GPU acceleration:** All 99+ layers offloaded to Metal, runs entirely on Apple GPU
5. **Memory:** ~4 GB peak during inference

### Deleting the model

Go to **Settings > On-Device AI > Delete Model**. This removes the GGUF file and frees ~3.2 GB of storage. The app falls back to whatever provider tier is available next.

---

## Downloading the Vision Projector

The vision projector enables image analysis with the on-device model. Without it, Gemma can still process text queries (food search, coaching, meal plans) but cannot directly analyze food photos.

### Download

1. In **Settings > On-Device AI**, after the main model is downloaded
2. Tap **Download Vision Projector**
3. Wait for download (~860 MB)
4. Image analysis is now available offline

The projector file is: `mmproj-google_gemma-4-E2B-it-f16.gguf`

### How vision works

The mtmd (multimodal) system in llama.cpp:

1. Converts the food photo to JPEG bytes
2. Creates a bitmap via `mtmd_helper_bitmap_init_from_buf()`
3. Tokenizes the prompt with image patches via `mtmd_tokenize()`
4. Evaluates interleaved text + image chunks via `mtmd_helper_eval_chunks()`
5. Generates text response (same sampling loop as text-only)

### Fallback without vision projector

If the vision projector is not downloaded, image analysis requests fall back to text-only mode. The provider prefixes the prompt with "The user showed a photo of food." -- this allows the model to still attempt analysis based on the text prompt alone, though accuracy is significantly lower.

---

## Feature Support by Provider

| Feature | Gemini Cloud | Gemma On-Device | Gemma (no vision) |
|---|---|---|---|
| Food photo analysis | Yes | Yes | Text-only fallback |
| Text food search | Yes | Yes | Yes |
| AI coach chat | Yes | Yes | Yes |
| Meal plan generation | Yes | Yes | Yes |
| Portion estimation | Yes | Yes | Text-only fallback |
| Before/after comparison | Yes | Yes (single image) | Text-only fallback |
| Nutrition label OCR | Yes | Yes | Text-only fallback |
| Weekly insights | Yes | Yes | Yes |
| Nutrition quiz | Yes (server) | No (server only) | No (server only) |
| Weight prediction | Yes (server) | No (server only) | No (server only) |

Features marked "server only" are computed by the Node.js server's Gemini integration, not by the mobile client's AI provider.

---

## Adding a New AI Feature

To add a new AI-powered feature, follow these steps:

### 1. Define the method in the protocol

**iOS** (`FoodDetectionApp/AI/AIProvider.swift`):

```swift
protocol AIProvider {
    // ... existing methods ...
    func yourNewFeature(input: String) async throws -> String
}
```

**Android** (`android/.../services/ai/AIProvider.kt`):

```kotlin
interface AIProvider {
    // ... existing methods ...
    suspend fun yourNewFeature(input: String): String
}
```

### 2. Add the prompt template

**iOS** (`FoodDetectionApp/AI/PromptTemplates.swift`):

```swift
static func yourNewFeaturePrompt(context: String, forLocal: Bool = false) -> String {
    let prompt = """
    Your prompt here with \(context).
    Return JSON with keys: ...
    """
    return forLocal ? prompt + localJSONSuffix : prompt
}
```

The `forLocal` flag adds explicit JSON formatting instructions for on-device models.

### 3. Implement in GeminiCloudProvider

**iOS** (`FoodDetectionApp/AI/GeminiCloudProvider.swift`):

```swift
func yourNewFeature(input: String) async throws -> String {
    try checkRateLimit()
    let prompt = PromptTemplates.yourNewFeaturePrompt(context: input, forLocal: false)
    // Build request body, call Gemini API, parse response
    // Use AIResponseParser for structured data
}
```

### 4. Implement in GemmaLocalProvider

**iOS** (`FoodDetectionApp/AI/GemmaLocalProvider.swift`):

```swift
func yourNewFeature(input: String) async throws -> String {
    let prompt = PromptTemplates.yourNewFeaturePrompt(context: input, forLocal: true)
    return try await generate(prompt: prompt, maxTokens: 512)
}
```

For image-based features, use `generateWithImage(prompt:image:maxTokens:)` instead.

### 5. Add parsing if needed

If your feature returns structured data, add parsing methods to `AIResponseParser`:
- `parseYourFeatureFromGeminiEnvelope(data:)` for cloud responses
- `parseYourFeatureFromRawText(text:)` for local responses

### 6. Expose via APIService

**iOS** (`FoodDetectionApp/APIService.swift`):

```swift
func yourNewFeature(input: String) async throws -> String {
    try await provider.yourNewFeature(input: input)
}
```

### 7. Add the same to the Android implementation

Mirror the changes in the Kotlin files under `android/.../services/ai/`.

---

## Prompt Engineering Tips

### For food/nutrition accuracy

1. **Be explicit about output format.** Always specify exact JSON keys and value types. Example: `"Calories per 100g": Estimated calories (number as string)`

2. **Request "per 100g" values.** This normalizes across portion sizes and makes it easier to scale for actual servings

3. **Include a "Source" field.** Helps the UI distinguish between database lookups and AI estimates

4. **Ask for micronutrients separately.** The `micros` dictionary is optional -- models sometimes omit it for simpler dishes

5. **Keep local prompts shorter.** The E2B model has limited context. Avoid long system prompts for on-device use

6. **Add JSON enforcement for local models.** The `localJSONSuffix` in `PromptTemplates` exists because Gemma sometimes wraps JSON in markdown fences or adds explanatory text

### Temperature settings

- **Food analysis:** Use the default sampler settings (temp=0.7). Lower temperatures can cause the model to refuse or repeat
- **Coach advice:** temp=0.7 works well for conversational responses
- **Meal plans:** temp=0.7 for variety in suggestions
- **JSON output:** Consider lower temperature (0.3-0.5) if you see malformed JSON from local models

### Token limits

- Food analysis: 1024 tokens (default)
- Coach advice: 500 tokens
- Meal plans: 1024 tokens
- Insights: 500 tokens

Longer limits consume more memory and time on-device. Keep them as short as the feature allows.

---

## Model Comparison

### Gemma 4 E2B vs E4B

| Property | E2B (used) | E4B |
|---|---|---|
| Parameters | ~2 billion | ~4 billion |
| Q4_K_M size | ~3.2 GB | ~4.5 GB |
| RAM required | ~4 GB | ~6 GB |
| Speed (iPhone 15 Pro) | ~15-25 tok/s | ~8-15 tok/s |
| Nutrition accuracy | Good for common foods | Better for edge cases |
| Min device (iOS) | iPhone 12 (6 GB) | iPhone 15 Pro (8 GB) |

FoodSense uses E2B because it runs on a wider range of devices. The accuracy difference for common food items is minimal. E4B is better for unusual or complex dishes but requires newer hardware.

### Quantization tradeoffs

| Quantization | Size | Quality | Speed | Recommended? |
|---|---|---|---|---|
| Q2_K | ~1.5 GB | Low -- frequent errors | Fastest | No |
| Q4_K_S | ~2.8 GB | Good | Fast | Viable alternative |
| **Q4_K_M** | **~3.2 GB** | **Good -- best balance** | **Good** | **Yes (default)** |
| Q5_K_M | ~3.8 GB | Better | Moderate | If RAM allows |
| Q6_K | ~4.2 GB | Near-original | Slow | Not recommended for mobile |
| F16 | ~8+ GB | Original | Very slow | Not feasible on mobile |

Q4_K_M provides the best tradeoff between size, quality, and speed for mobile inference.

---

## Memory Requirements

### iOS

| Device | RAM | E2B Q4_K_M | Vision projector | Both loaded |
|---|---|---|---|---|
| iPhone 11 | 4 GB | Will fail | N/A | N/A |
| iPhone 12 / 13 | 4-6 GB | Tight, works | May OOM | Use text-only |
| iPhone 14 | 6 GB | Comfortable | Works | Works |
| iPhone 15 Pro | 8 GB | Comfortable | Works | Works well |
| iPhone 16 Pro | 8 GB | Comfortable | Works | Works well |
| iPad Air 4+ | 8 GB | Comfortable | Works | Works well |
| iPad Pro M1+ | 8-16 GB | Comfortable | Works | Ideal |

The model uses ~3.2 GB for weights plus ~0.5-1 GB for KV cache during inference. The vision projector adds ~860 MB when loaded. Total peak is ~4-5 GB.

### Android (planned)

Android memory requirements will depend on the LiteRT-LM integration. The same Q4_K_M model will require similar memory. Devices with 8+ GB RAM are recommended.

---

## Known Limitations

### Accuracy

- **Calorie estimates are approximate.** AI-estimated calories can vary by 15-30% from lab-measured values. Always treat them as estimates
- **Portion sizes are visual guesses.** Without a reference object or scale, portion estimation accuracy is limited
- **Regional food variations.** Nutrition data for the same dish can vary significantly by region and preparation method
- **Mixed plates.** Multi-item plates may confuse the model, especially on-device. Single-dish photos work best

### On-device limitations

- **No real-time vision.** Each analysis requires taking a photo and waiting for inference (3-10 seconds on modern devices)
- **No streaming.** Responses are generated fully before being returned. There is no token-by-token streaming in the current implementation
- **Single image for before/after.** The on-device vision pipeline can only process one image at a time. Before/after comparison on-device sends only the "before" image
- **Context window.** The 2048-token context means very long conversation histories get truncated in coach chat
- **Cold start.** The first inference after app launch takes 5-15 seconds to load the model. Subsequent calls are faster

### Vision limitations

- **Requires vision projector download.** Image analysis does not work without the separate ~860 MB mmproj file
- **JPEG compression.** Images are compressed to 70% quality before analysis, which may lose detail for small items
- **No video.** Only still photos are supported

### General

- **No offline social features.** Friends, feed, challenges, and leaderboards require the server
- **Hindi AI responses.** On-device Gemma generates responses primarily in English even when the app UI is set to Hindi
- **Quiz and weight prediction** are server-side only (Gemini API via the Node.js server)
