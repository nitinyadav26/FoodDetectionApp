
# iOS Application Documentation

## Architecture
The application follows the **MVVM (Model-View-ViewModel)** architectural pattern, leveraging SwiftUI for the user interface and Combine for data binding.

### Core Architecture Components
*   **Views**: SwiftUI views (e.g., `DashboardView`, `CoachView`, `CameraView`) responsible for UI rendering.
*   **ViewModels / Managers**: Singleton classes (e.g., `NutritionManager`, `APIService`) acting as the source of truth for data.
*   **Models**: Swift structs (e.g., `FoodLog`, `UserStats`, `NutritionInfo`) defining the data schema.

---

## Key Services & Managers

### 1. `NutritionManager`
*   **Role**: The central data store for the application.
*   **Responsibilities**:
    *   **Data Persistence**: Loads and saves `foodLogs` and `userStats` using `UserDefaults`.
    *   **Budget Calculation**: Calculates Daily Calorie Budget (TDEE) using the **Mifflin-St Jeor Equation** based on user stats (age, weight, height, activity).
    *   **Logging**: Handles adding/deleting food logs and calculating daily summaries (Calories, Protein, Carbs, Fats).
    *   **Unit Conversion**: Scales nutrition data based on food quantity (default 100g).

### 2. `APIService` (Gemini Integration)
*   **Role**: Handles all cloud-based AI interactions.
*   **Model**: Google **Gemini 1.5 Flash**.
*   **Key Functions**:
    *   `analyzeFood(image: UIImage)`: Sends an image to Gemini to identify the dish and return structured JSON nutrition data.
    *   `searchFood(query: String)`: Analyzes a text query to estimate nutrition for manual entries.
    *   `getCoachAdvice(...)`: Sends a "Context String" (User stats + Recent Logs + Health Data) to Gemini to generate personalized health advice.

### 3. `ModelDataHandler` (On-Device AI)
*   **Role**: Performs real-time object detection using TensorFlow Lite.
*   **Model**: Custom YOLO-based model (`model.tflite`).
*   **Classes**: Detects **72 specific Indian food classes** (e.g., *Biryani, Dosa, Samosa, Butter Chicken*).
*   **Pipeline**:
    1.  **Input**: Camera frame (`CVPixelBuffer`).
    2.  **Preprocessing**: Resize to **640x640**, normalize pixel values (0-1).
    3.  **Inference**: Runs TFLite interpreter.
    4.  **Post-Process**: Decodes YOLO output (center-x, center-y, width, height) and applies **Non-Max Suppression (NMS)** to filter overlapping boxes.

### 4. `HealthKitManager`
*   **Role**: Syncs data with Apple Health.
*   **Metrics**: Steps, Active Energy Burned, Sleep Analysis, Water Intake.
*   **Privacy**: Request authorization for both Read and Write permissions on launch.

---

## Data Flow

### Food Logging Flow
1.  **Detection**:
    *   User points camera -> `CameraView` -> `ModelDataHandler` -> Returns generic label (e.g., "Biryani").
    *   **OR** User takes photo -> `APIService` (Gemini) -> Returns detailed breakdown.
2.  **Confirmation**:
    *   User confirms or edits the food name and quantity in `ResultView` or `ManualLogView`.
3.  **Storage**:
    *   Data is passed to `NutritionManager.logFood()`.
    *   Log is appended to `logs` array and saved to `UserDefaults`.

### AI Coach Flow
1.  **Data Aggregation**: `CoachView` collects:
    *   User Profile (Weight, Goal).
    *   Today's Logs (from `NutritionManager`).
    *   Last 7 days history (from `HealthKitManager` & `NutritionManager`).
2.  **Prompt Engineering**: specific system prompts are constructed to define the persona ("Friendly Health Coach").
3.  **Response**: Gemini generates text advice which is displayed in the chat interface.

---

## File Overview
*   **`FoodInput/`**:
    *   `CameraView.swift`: Real-time camera preview.
    *   `ManualLogView.swift`: Search and manual entry UI.
*   **`Dashboard/`**:
    *   `DashboardView.swift`: Main home screen with rings and list.
    *   `ProfileView.swift`: User settings and goal configuration.
*   **`Coach/`**:
    *   `CoachView.swift`: AI Chat interface.
*   **`Core/`**:
    *   `NutritionManager.swift`: State management.
    *   `ModelDataHandler.swift`: TFLite logic.
