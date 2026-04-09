
# Smart Food Detection & Coaching App

## Overview
This is a comprehensive iOS application designed to help users track their nutrition and improve their health using advanced AI and hardware integration. The app combines real-time object detection, Generative AI analysis, and smart hardware connectivity to provide a seamless health tracking experience.

### Key Features
*   **AI-Powered Food Analysis**: Uses **Google Gemini 1.5 Flash** to analyze food images, identifying dishes and estimating nutritional content (Calories, Macros, Micros) from photos.
*   **On-Device Object Detection**: Utilizes **TensorFlow Lite** for real-time, offline detection of common food items directly on the device.
*   **Smart Scale Integration**: Connects via **Bluetooth Low Energy (BLE)** to a custom smart scale to get precise food weights.
*   **AI Health Coach**: A personalized chatbot powered by Gemini that provides health advice based on your recent logs, daily stats, and health goals.
*   **HealthKit Integration**: Syncs with Apple Health to track steps, active energy, and other vital metrics.
*   **Indian Nutrient Databank (INDB)**: Includes a comprehensive database of Indian foods for manual logging.

---

## Technical Stack
*   **Platform**: iOS 15.0+
*   **Language**: Swift (SwiftUI)
*   **AI/ML**:
    *   **Google Gemini API** (Cloud analysis & Chat)
    *   **TensorFlow Lite** (On-device vision)
*   **Data**: JSON (Local storage), CoreData/UserDefaults (User prefs)
*   **Connectivity**: CoreBluetooth (BLE), HealthKit
*   **Tools**: CocoaPods (Dependency Management), Python (Data processing)

---

## Setup & Installation

### Prerequisites
*   Mac with macOS Monterey or later.
*   Xcode 13+ installed.
*   CocoaPods installed (`sudo gem install cocoapods`).
*   Python 3.x (for data scripts).

### Installation Steps
1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd FoodDetectionApp
    ```

2.  **Install Dependencies**:
    ```bash
    pod install
    ```
    *Note: Always open the `FoodDetectionApp.xcworkspace` file, NOT the `.xcodeproj` file.*

3.  **Configure API Keys**:
    *   Open `FoodDetectionApp/APIService.swift`.
    *   Replace `private let apiKey = "YOUR_KEY"` with your valid Google Gemini API Key.

4.  **Run the App**:
    *   Select your target simulator or physical device in Xcode.
    *   Press `Cmd+R` to build and run.
    *   *Note: Physical device required for Camera and Bluetooth features.*

---

## Documentation
For more detailed information, please refer to the following documents:

*   **[App Documentation](App_Documentation.md)**: Detailed breakdown of the iOS app architecture, views, and services.
*   **[Data Processing & Sources](Data_Processing.md)**: Explanation of the food databases (INDB) and python processing scripts.

---

## Project Structure
*   `FoodDetectionApp/`: Main iOS application source code.
*   `INDB_data/`: Python scripts and raw Excel files for generating the food database.
*   `Pods/`: Managed dependencies (do not edit manually).

---

## License
[License Information Here]
