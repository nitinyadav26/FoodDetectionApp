# FoodSense v1.1 Release Notes

**Release Date:** April 2026
**Platforms:** iOS 15.0+, Android 8.0+ (API 26)

---

## Social Features

- **Friends:** Add friends by username or QR code. View friends list and manage connections.
- **Activity Feed:** See what friends are eating, celebrate milestones with emoji reactions, and share your own nutrition wins.
- **QR Profile Cards:** Generate a shareable QR code profile card for quick friend connections.
- **Challenges:** Create or join nutrition challenges (calorie targets, protein streaks, logging consistency). Track group progress with real-time updates.
- **Leaderboards:** Compete on friends, global, weekly, and monthly leaderboards ranked by XP.
- **Leagues:** Climb through Bronze, Silver, Gold, Platinum, and Diamond tiers based on accumulated XP.

## Gamification

- **XP System:** Earn experience points for every action in the app:
  - Log food: +10 XP
  - Daily streak: +5 XP
  - Unlock badge: +25 XP
  - Win challenge: +50 XP
  - Complete quiz: +15 XP
- **50 Levels:** Progress from Level 1 to Level 50 (Level N requires N x 100 XP).
- **7 Titles:** Advance through Newbie, Beginner, Intermediate, Advanced, Expert, Master, and Legend.
- **50+ Badges:** Collect achievements across 6 categories:
  - Streak badges (consecutive logging days)
  - Logging badges (total meals logged)
  - Nutrition badges (hitting macro targets)
  - Social badges (friends and feed activity)
  - Challenge badges (participation and wins)
  - Special badges (hidden and seasonal achievements)

## AI Features

- **Voice Food Logging:** Say what you ate and FoodSense logs it automatically using on-device speech recognition. Hands-free meal tracking for when you are on the go.
- **AI Nutritionist Chat:** Persistent conversation with a personal AI health coach powered by Google Gemini. Remembers your eating patterns, goals, and previous conversations.
- **7-Day Meal Plans:** AI-generated weekly meal plans tailored to your calorie targets, dietary preferences, and nutritional goals.
- **Weekly Insights:** Visual charts showing nutrition trends over time, with weight predictions and actionable recommendations to improve your diet.
- **Daily Nutrition Quiz:** AI-generated questions to test and grow your nutrition knowledge, with XP rewards for correct answers.
- **Food Quality Scoring:** Every scanned meal receives a quality score from 0 to 100 based on nutritional balance.
- **Portion Estimation:** AI-powered portion size detection for more accurate calorie tracking.
- **Before/After Plate Analysis:** Scan your plate before and after eating to estimate actual consumption.
- **Nutrition Label OCR:** Point your camera at nutrition labels on packaged food to automatically read and log the data.

## Cloud Sync

- **Server Backend:** New Node.js server backend with PostgreSQL database for cross-device data synchronization.
- **Account Persistence:** Food logs, badges, XP, friends, and settings sync across devices when signed in.
- **Secure Auth:** Firebase Authentication with JWT-based API authorization.

## Improvements

- Redesigned 6-tab navigation with dedicated Social tab
- Improved AI food scanning accuracy with updated Gemini integration
- Enhanced dashboard with XP progress bar and badge showcase
- Home screen widget updates with streak and XP display
- Performance optimizations for faster app launch and smoother scrolling
- Bug fixes and stability improvements

---

## Minimum Requirements

| Platform | Requirement |
|----------|------------|
| iOS | 15.0 or later |
| Android | 8.0 (API 26) or later |
| Server | Docker with PostgreSQL 15 and Redis 7 |

## Upgrade Notes

- Existing v1.0 users will keep all local food logs and settings.
- Sign in with your existing Firebase account to enable cloud sync and social features.
- XP and badges start fresh; prior streaks are preserved.
