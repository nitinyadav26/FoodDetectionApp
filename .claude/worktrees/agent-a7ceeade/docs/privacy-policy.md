# FoodSense Privacy Policy

**Last Updated:** April 5, 2026

## Overview

FoodSense ("the App") is a nutrition tracking and food detection application. This privacy policy explains how we collect, use, and protect your information.

## Information We Collect

### Information You Provide
- **Profile Data:** Weight, height, age, gender, activity level, and fitness goal. This is stored locally on your device and used to calculate your daily calorie budget.
- **Food Logs:** Records of food items you log, including dish name, calories, macronutrients, and timestamps. Stored locally on your device.

### Information Collected Automatically
- **Camera Images:** When you use the food scanning feature, images are captured from your device camera. Images used for cloud AI analysis are sent to Google's Gemini API for processing and are not stored by FoodSense after analysis is complete.
- **Health Data (iOS):** With your permission, we read steps, active calories, sleep duration, and water intake from Apple HealthKit. We may write food energy and water intake data back to HealthKit. We do not store or transmit your HealthKit data to any server.
- **Health Data (Android):** With your permission, we read and write health metrics via Health Connect. We do not store or transmit your Health Connect data to any server.
- **Bluetooth Data:** If you pair a smart scale, we receive weight readings over Bluetooth Low Energy. This data is used only within the app session for portion weighing.

### Information We Do NOT Collect
- We do not collect your name, email address, phone number, or location.
- We do not use advertising trackers or sell your data.
- We do not store camera images after food analysis is complete.

## How We Use Your Information

- **Nutrition Tracking:** To calculate and display your daily calorie budget, macronutrient intake, and food history.
- **AI Food Analysis:** Camera images are sent to Google Gemini API to identify food items and estimate nutritional content. Google processes these images according to their own privacy policy.
- **AI Health Coaching:** Your recent food logs and health metrics (anonymized, no personal identifiers) are sent to Google Gemini API to generate personalized health advice.
- **Crash Reporting:** We use Firebase Crashlytics to collect anonymous crash reports to improve app stability. No personal data is included in crash reports.

## Third-Party Services

- **Google Gemini API:** Used for food image analysis and health coaching. Subject to [Google's Privacy Policy](https://policies.google.com/privacy).
- **Firebase:** Used for crash reporting and analytics. Subject to [Firebase Privacy Policy](https://firebase.google.com/support/privacy).
- **Apple HealthKit (iOS):** Health data read/written with your explicit permission. Subject to [Apple's Privacy Policy](https://www.apple.com/privacy/).
- **Health Connect (Android):** Health data read/written with your explicit permission.

## Data Storage and Security

- All personal data (profile, food logs) is stored locally on your device.
- We do not maintain user accounts or server-side databases of personal data.
- Data transmitted to Google Gemini API is sent over encrypted HTTPS connections.

## Data Retention

- **Local Data:** Retained on your device until you delete it or uninstall the app.
- **Cloud AI Processing:** Images and text sent to Gemini API are processed in real-time and not retained by FoodSense.

## Your Rights

- **Access:** You can view all your data within the app (Profile, Dashboard, Food Logs).
- **Export:** You can export all your data as a JSON file from the Settings screen.
- **Deletion:** You can delete individual food logs or all data from the Settings screen. Uninstalling the app removes all locally stored data.
- **Portability:** Your exported data is in standard JSON format.

## Children's Privacy

FoodSense is not intended for children under 13. We do not knowingly collect personal information from children under 13.

## Changes to This Policy

We may update this privacy policy from time to time. We will notify you of changes by updating the "Last Updated" date above.

## Contact Us

If you have questions about this privacy policy, please open an issue at our GitHub repository or contact us through the App Store / Play Store listing.
