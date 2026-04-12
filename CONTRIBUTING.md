# Contributing to FoodSense

Thank you for your interest in contributing to FoodSense! This document explains how to get involved.

---

## Table of Contents

- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Good First Issues](#good-first-issues)
- [Code of Conduct](#code-of-conduct)

---

## Reporting Bugs

Open an issue on GitHub with:

1. **Title:** Short, descriptive summary
2. **Platform:** iOS version + device, Android version + device, or Server
3. **Steps to reproduce:** Numbered list of actions
4. **Expected behavior:** What should happen
5. **Actual behavior:** What actually happens
6. **Screenshots/logs:** Attach any relevant output
7. **AI provider:** Were you using Gemma (on-device) or Gemini Cloud?

Use the `bug` label when creating the issue.

---

## Suggesting Features

Open an issue with the `enhancement` label. Include:

1. **Problem:** What limitation are you running into?
2. **Proposed solution:** How you think it could work
3. **Alternatives considered:** Other approaches you thought of
4. **Platform scope:** iOS only, Android only, server, or all?

---

## Development Setup

### Prerequisites

See [docs/BUILDING.md](docs/BUILDING.md) for full prerequisites. Quick summary:

- **iOS:** Xcode 15+, CocoaPods
- **Android:** Android Studio, JDK 17+
- **Server:** Node.js 20, Docker

### Getting started

```bash
# Clone
git clone https://github.com/nitinyadav26/FoodDetectionApp.git
cd FoodDetectionApp

# iOS
pod install
open FoodDetectionApp.xcworkspace

# Android
cd android && ./gradlew assembleDebug

# Server
cd server && npm install && npm run dev
```

### Branch workflow

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes
3. Test on at least one platform
4. Push and open a PR against `main`

---

## Code Style

### Swift (iOS)

- **Architecture:** MVVM with singleton managers (`static let shared = ClassName()`)
- **State management:** `@Published` properties on `ObservableObject` managers, consumed via `@ObservedObject` / `@StateObject` in views
- **Async:** Use `async/await` for all asynchronous work
- **AI integration:** All AI calls go through the `AIProvider` protocol. Add new AI features by:
  1. Adding the method to `AIProvider.swift`
  2. Implementing in both `GeminiCloudProvider.swift` and `GemmaLocalProvider.swift`
  3. Adding the prompt to `PromptTemplates.swift`
  4. Adding parsing to `AIResponseParser.swift`
  5. Exposing via `APIService.swift`
- **Localization:** Every user-facing string must have keys in both `en.lproj/Localizable.strings` and `hi.lproj/Localizable.strings`
- **Naming:** PascalCase for types, camelCase for properties/functions, `*Manager.swift` for services, `*View.swift` for views
- **Accessibility:** Add `.accessibilityLabel()` to all interactive elements

### Kotlin (Android)

- **Architecture:** MVVM with singleton-like managers in `FoodSenseApplication`
- **State management:** Compose `mutableStateOf` in service classes (not ViewModel/StateFlow)
- **DI:** Manual lazy initialization in `FoodSenseApplication`, passed via `app` parameter
- **Coroutines:** `CoroutineScope(Dispatchers.IO)` for background work
- **Database:** Room v2 with migrations
- **Screens:** Follow `@Composable fun XxxScreen(app: FoodSenseApplication)` pattern
- **Naming:** PascalCase for types, camelCase for functions/properties
- **Accessibility:** Add `contentDescription` to all interactive elements

### TypeScript (Server)

- **Architecture:** Route -> Controller -> Service -> Prisma
- **Auth:** Firebase token verification middleware sets `req.user.uid`
- **Validation:** Define Zod schemas in `validators/`, apply via `validate()` middleware
- **Error handling:** Throw `ApiError` for expected errors, wrap controllers in `asyncHandler`
- **AI calls:** All Gemini interactions go through `config/gemini.ts` with retry logic
- **Naming:** camelCase for variables/functions, PascalCase for types/classes

### General

- **No secrets in code.** API keys go in `.env`, Keychain, EncryptedSharedPreferences, or Xcode Build Settings
- **Commit messages:** Present tense, descriptive. Example: "Add portion estimation to GemmaLocalProvider"
- **Comments:** Explain *why*, not *what*. Code should be self-documenting for the *what*

---

## Pull Request Process

1. **Fork and branch.** Create a feature branch from `main` named `feature/your-change` or `fix/your-fix`

2. **Make changes.** Follow the code style guidelines above

3. **Test.** Run tests on the platforms you changed:
   ```bash
   # iOS
   xcodebuild test -workspace FoodDetectionApp.xcworkspace -scheme FoodDetectionApp -destination 'platform=iOS Simulator,name=iPhone 16'

   # Android
   cd android && ./gradlew testDebugUnitTest

   # Server
   cd server && npx tsc --noEmit
   ```

4. **Open PR.** Target `main`. Include:
   - Summary of changes
   - Which platforms are affected
   - How to test (screenshots for UI changes)
   - Whether the change affects the AI provider interface

5. **CI checks.** GitHub Actions will run iOS build, Android build, and server type checks

6. **Review.** The maintainer (Nitin Yadav) will review. Expect feedback within a few days

7. **Merge.** After approval, the PR will be squash-merged into `main`

---

## Good First Issues

Here are areas where new contributors can make a meaningful impact:

### Documentation
- Add JSDoc comments to server controllers and services
- Improve inline code comments in Swift managers
- Write integration test guides

### Testing
- Add unit tests for `AIResponseParser` edge cases (malformed JSON, empty responses)
- Add unit tests for Android `PromptTemplates`
- Add server API integration tests with Supertest

### Localization
- Add a new language (e.g., Spanish, Tamil, Bengali)
- Audit existing Hindi translations for accuracy

### UI/UX
- Improve VoiceOver/TalkBack accessibility across all screens
- Add animations to calorie tracking charts
- Improve error states and empty states in social features

### Features
- Add food database entries for non-Indian cuisines
- Implement barcode scanning for Android (CameraX + ML Kit)
- Add data export (CSV/JSON) for food logs

### Android On-Device AI
- Port llama.cpp JNI integration for Android
- Implement `GemmaLocalProvider` with actual inference calls
- Add model download UI matching iOS implementation

---

## Code of Conduct

We are committed to providing a welcoming and inclusive experience for everyone. By participating in this project, you agree to:

- Be respectful and considerate in all communications
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Accept responsibility for mistakes and learn from them
- Prioritize the community's well-being over individual preferences

Unacceptable behavior includes harassment, trolling, personal attacks, and publishing others' private information. Violations can be reported to the project maintainer.

---

## Questions?

Open a GitHub Discussion or reach out to the maintainer. We are happy to help you get started.
