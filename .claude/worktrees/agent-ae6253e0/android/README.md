# FoodSense Android Port

This folder contains a native Android (Jetpack Compose + Kotlin) version of the iOS FoodSense app.

## What was ported

- Onboarding flow + profile capture
- Bottom tab navigation (Dashboard, Scan, AI Coach, Pair Scale, Profile)
- Dashboard nutrition rings, health cards, date slider, food log history, manual log entry
- Camera scan flow:
  - Local on-device detection (TensorFlow Lite `model.tflite`)
  - Cloud food analysis (Gemini)
- Result sheets for single-item and multi-item logging
- AI Coach chips + contextual prompt history
- BLE scale pairing screen + live weight read integration
- Local persistence for user stats, logs, and health history

## Project location

- Android project root: `/Users/nitin/Desktop/FoodDetectionApp 2/android`

## Build & run (CLI)

```bash
cd /Users/nitin/Desktop/FoodDetectionApp\ 2/android
./gradlew assembleDebug
./gradlew installDebug
adb -e shell am start -n com.foodsense.android/.MainActivity
```

## Emulator (if needed via CLI)

```bash
~/Library/Android/sdk/emulator/emulator -avd Small_Phone -no-window -gpu swiftshader_indirect -no-snapshot-save -no-boot-anim
```

## Notes

- Gemini key is read from Gradle property `GEMINI_API_KEY` if provided; otherwise a default key value is used in `app/build.gradle.kts`.
- Android cannot use Apple HealthKit APIs; equivalent dashboard health data is backed by local storage in `HealthDataManager`.
