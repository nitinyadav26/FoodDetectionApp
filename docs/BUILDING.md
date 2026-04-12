# Building FoodSense from Source

This guide covers building all three platforms (iOS, Android, Server) from source, including the critical step of building the llama.cpp XCFramework for on-device AI.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [iOS Build](#ios-build)
- [Building llama.cpp XCFramework](#building-llamacpp-xcframework)
- [Downloading Gemma Model Files](#downloading-gemma-model-files)
- [Android Build](#android-build)
- [Server Setup](#server-setup)

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Xcode | 15.0+ | iOS build, XCFramework creation |
| CocoaPods | Latest | iOS dependency management |
| CMake | 3.21+ | Building llama.cpp |
| Android Studio | Hedgehog+ | Android build |
| JDK | 17+ | Android Gradle |
| Node.js | 20 LTS | Server runtime |
| Docker + Docker Compose | Latest | Server deployment |
| Git LFS | Latest | Large file support (model.tflite) |
| Python | 3.x | Data processing scripts (optional) |

Install on macOS:

```bash
# Xcode command line tools
xcode-select --install

# Homebrew packages
brew install cmake cocoapods node@20 docker docker-compose git-lfs

# Initialize Git LFS
git lfs install
```

---

## iOS Build

### 1. Clone and install dependencies

```bash
git clone https://github.com/nitinyadav26/FoodDetectionApp.git
cd FoodDetectionApp

# Install CocoaPods (TensorFlowLite, Firebase)
pod install
```

### 2. Open in Xcode

```bash
# IMPORTANT: Always open the .xcworkspace, not the .xcodeproj
open FoodDetectionApp.xcworkspace
```

### 3. Configure signing

- Select the `FoodDetectionApp` target
- Under Signing & Capabilities, set your Team and Bundle Identifier
- Do the same for the `FoodSenseWidget` target

### 4. Build

```bash
# Build for simulator
xcodebuild build \
  -workspace FoodDetectionApp.xcworkspace \
  -scheme FoodDetectionApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Or build for device
xcodebuild build \
  -workspace FoodDetectionApp.xcworkspace \
  -scheme FoodDetectionApp \
  -destination 'generic/platform=iOS'
```

### 5. Run tests

```bash
xcodebuild test \
  -workspace FoodDetectionApp.xcworkspace \
  -scheme FoodDetectionApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

> **Note:** `model.tflite` (237 MB) is proprietary and tracked via Git LFS. It is not
> included in public clones. The app compiles and runs without it -- YOLO detection will
> be unavailable, but Gemma and Gemini analysis work independently.

---

## Building llama.cpp XCFramework

This is the most involved step. You need to compile llama.cpp as a static library for both iOS device (arm64) and iOS simulator (arm64), then package them into an XCFramework that Xcode can consume.

The XCFramework includes llama (text inference), ggml (tensor operations with Metal), and mtmd (multimodal/vision support).

### 1. Clone llama.cpp

```bash
cd /tmp
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
git checkout b8763    # Known-good tag -- adjust as needed
```

### 2. Build for iOS device (arm64)

```bash
mkdir build-ios-device && cd build-ios-device

cmake .. \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="" \
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Release

cmake --build . --config Release -j$(sysctl -n hw.ncpu)
cd ..
```

### 3. Build for iOS simulator (arm64)

```bash
mkdir build-ios-sim && cd build-ios-sim

cmake .. \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Release

cmake --build . --config Release -j$(sysctl -n hw.ncpu)
cd ..
```

### 4. Merge static libraries with libtool

Each build produces multiple `.a` files (libllama.a, libggml.a, libggml-base.a, libggml-metal.a, libggml-cpu.a, libmtmd.a, etc.). Merge them into a single fat static library for each platform:

```bash
# Device
libtool -static -o build-ios-device/libllama-all.a \
  build-ios-device/src/libllama.a \
  build-ios-device/ggml/src/libggml.a \
  build-ios-device/ggml/src/libggml-base.a \
  build-ios-device/ggml/src/libggml-metal.a \
  build-ios-device/ggml/src/libggml-cpu.a \
  build-ios-device/tools/mtmd/libmtmd.a

# Simulator
libtool -static -o build-ios-sim/libllama-all.a \
  build-ios-sim/src/libllama.a \
  build-ios-sim/ggml/src/libggml.a \
  build-ios-sim/ggml/src/libggml-base.a \
  build-ios-sim/ggml/src/libggml-metal.a \
  build-ios-sim/ggml/src/libggml-cpu.a \
  build-ios-sim/tools/mtmd/libmtmd.a
```

> **Tip:** The exact list of `.a` files may vary by llama.cpp version. Run
> `find build-ios-device -name "*.a"` to see all produced libraries and include
> them all in the libtool command.

### 5. Collect headers

```bash
# Create header directories
mkdir -p xcfw-staging/device/Headers
mkdir -p xcfw-staging/simulator/Headers

# Copy merged libraries
cp build-ios-device/libllama-all.a xcfw-staging/device/
cp build-ios-sim/libllama-all.a xcfw-staging/simulator/

# Copy required headers
for dir in device simulator; do
  cp include/llama.h                 xcfw-staging/$dir/Headers/
  cp ggml/include/ggml.h             xcfw-staging/$dir/Headers/
  cp ggml/include/ggml-alloc.h       xcfw-staging/$dir/Headers/
  cp ggml/include/ggml-backend.h     xcfw-staging/$dir/Headers/
  cp ggml/include/ggml-metal.h       xcfw-staging/$dir/Headers/
  cp ggml/include/ggml-cpu.h         xcfw-staging/$dir/Headers/
  cp ggml/include/gguf.h             xcfw-staging/$dir/Headers/
  cp tools/mtmd/mtmd.h               xcfw-staging/$dir/Headers/
  cp tools/mtmd/mtmd-helper.h        xcfw-staging/$dir/Headers/
  cp tools/mtmd/clip.h               xcfw-staging/$dir/Headers/
done
```

### 6. Create module.modulemap

Create `xcfw-staging/device/Headers/module.modulemap` (and copy to simulator):

```
module llama {
    header "llama.h"
    header "ggml.h"
    header "ggml-alloc.h"
    header "ggml-backend.h"
    header "ggml-metal.h"
    header "ggml-cpu.h"
    header "gguf.h"
    header "mtmd.h"
    header "mtmd-helper.h"
    header "clip.h"
    link "c++"
    export *
}
```

```bash
cp xcfw-staging/device/Headers/module.modulemap xcfw-staging/simulator/Headers/
```

### 7. Create the XCFramework

```bash
xcodebuild -create-xcframework \
  -library xcfw-staging/device/libllama-all.a \
  -headers xcfw-staging/device/Headers \
  -library xcfw-staging/simulator/libllama-all.a \
  -headers xcfw-staging/simulator/Headers \
  -output llama.xcframework
```

### 8. Install into the project

```bash
# Copy into the FoodDetectionApp project root
cp -R llama.xcframework /path/to/FoodDetectionApp/

# In Xcode:
# 1. Select FoodDetectionApp target > General > Frameworks, Libraries
# 2. Add llama.xcframework
# 3. Ensure "Embed & Sign" is not selected (static libraries don't embed)
# 4. Add to "Link Binary With Libraries" if not already linked
```

After this, `import llama` will work in Swift files and `GemmaLocalProvider` will compile.

---

## Downloading Gemma Model Files

The on-device AI requires two GGUF model files. Users can download them through the app's Settings screen, or you can pre-download them:

### Main model (required for all on-device AI features)

- **File:** `google_gemma-4-E2B-it-Q4_K_M.gguf`
- **Size:** ~3.2 GB
- **Source:** [bartowski/google_gemma-4-E2B-it-GGUF](https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF) on HuggingFace

```bash
# Direct download
wget https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/google_gemma-4-E2B-it-Q4_K_M.gguf
```

### Vision projector (required for image analysis)

- **File:** `mmproj-google_gemma-4-E2B-it-f16.gguf`
- **Size:** ~860 MB
- **Source:** Same HuggingFace repo as above

```bash
wget https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/mmproj-google_gemma-4-E2B-it-f16.gguf
```

### In-app download

Go to **Settings > On-Device AI** in the app. The `ModelDownloadManager` handles downloading, GGUF magic-byte validation, and placement in the app's Application Support directory. The vision projector is available as a separate download on the same screen.

---

## Android Build

### 1. Open in Android Studio

```bash
cd android
```

Open the `android/` directory in Android Studio. Let Gradle sync complete.

### 2. Configure API keys

Create or edit `android/local.properties`:

```properties
GEMINI_API_KEY=your-gemini-api-key-here
```

For server connectivity (development), edit `android/gradle.properties`:

```properties
PROXY_BASE_URL=https://your-firebase-functions-url
SOCIAL_API_BASE_URL=http://10.0.2.2:3000
```

> `10.0.2.2` is the Android emulator's alias for the host machine's `localhost`.

### 3. Build

```bash
# Debug APK
./gradlew assembleDebug

# Release bundle (for Play Store)
./gradlew bundleRelease

# Install debug APK on connected device
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### 4. Run tests

```bash
./gradlew testDebugUnitTest
```

### 5. Firebase setup

Place your `google-services.json` in `android/app/`.

---

## Server Setup

### 1. Install dependencies (local development)

```bash
cd server
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env`:

```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/foodsense
REDIS_URL=redis://:your_redis_password@localhost:6379
POSTGRES_PASSWORD=your_password
REDIS_PASSWORD=your_redis_password
GEMINI_API_KEY=your-gemini-api-key
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
JWT_SECRET=your-random-secret-at-least-32-chars
PORT=3000
NODE_ENV=development
```

### 3. Firebase Admin SDK

Download your Firebase project's service account key from the Firebase Console:
- Project Settings > Service Accounts > Generate New Private Key
- Save as `server/firebase-service-account.json`

### 4. Database setup

```bash
# Generate Prisma client
npx prisma generate

# Run migrations (creates all 18 tables)
npx prisma migrate dev

# Seed initial data
npx prisma db seed
```

### 5. Run locally

```bash
npm run dev    # ts-node-dev with hot reload on port 3000
```

### 6. Production deployment (Docker)

```bash
docker compose up -d

# Run migrations inside container
docker compose exec app npx prisma migrate deploy
docker compose exec app npx prisma db seed

# Health check
curl http://localhost:3000/health
```

### 7. Type checking

```bash
npx tsc --noEmit
```

See [SERVER_SETUP.md](SERVER_SETUP.md) for full production deployment with HTTPS, nginx, and security hardening.
