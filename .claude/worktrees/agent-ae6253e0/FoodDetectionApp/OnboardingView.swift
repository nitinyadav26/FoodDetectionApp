import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    var nutritionManager = NutritionManager.shared

    @State private var currentPage = 0

    // Profile fields
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Male"
    @State private var activityLevel: String = "Moderate"
    @State private var goal: String = "Maintain"

    // Permission states
    @State private var cameraGranted = false
    @State private var healthGranted = false

    let genders = ["Male", "Female"]
    let activityLevels = ["Sedentary", "Light", "Moderate", "Active"]
    let goals = ["Lose", "Maintain", "Gain"]

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            permissionsPage.tag(1)
            profilePage.tag(2)
            allSetPage.tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .animation(.easeInOut, value: currentPage)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)

            Text("FoodSense")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your AI-powered nutrition companion")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 20) {
                featureRow(icon: "camera.viewfinder", text: "Scan food with your camera")
                featureRow(icon: "chart.bar.fill", text: "Track daily nutrition")
                featureRow(icon: "brain.head.profile", text: "Get personalized AI coaching")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: { currentPage = 1 }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)

            skipButton(destination: 2)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Page 2: Permissions

    private var permissionsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Quick Setup")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Grant permissions so FoodSense can work its magic.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                permissionCard(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "Needed to scan and identify food items.",
                    granted: cameraGranted
                ) {
                    requestCameraPermission()
                }

                permissionCard(
                    icon: "heart.fill",
                    title: "Apple Health",
                    description: "Sync steps, calories burned, and sleep data.",
                    granted: healthGranted
                ) {
                    requestHealthPermission()
                }

                permissionCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Bluetooth",
                    description: "Connect to smart kitchen scales for precise weights.",
                    granted: nil
                ) {
                    // Informational only -- no runtime request needed
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: { currentPage = 2 }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)

            skipButton(destination: 2)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Page 3: Profile Entry

    private var profilePage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                Text("We use this to calculate your daily calorie budget.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 16) {
                    profileField(title: "Weight (kg)", text: $weight, keyboard: .decimalPad)
                    profileField(title: "Height (cm)", text: $height, keyboard: .decimalPad)
                    profileField(title: "Age", text: $age, keyboard: .numberPad)

                    pickerRow(title: "Gender", selection: $gender, options: genders)
                    pickerRow(title: "Activity Level", selection: $activityLevel, options: activityLevels)
                    pickerRow(title: "Goal", selection: $goal, options: goals)
                }
                .padding(.horizontal, 24)

                Button(action: { currentPage = 3 }) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(profileValid ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(!profileValid)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Page 4: All Set

    private var allSetPage: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)

            Text("You're all set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your daily calorie budget: \(computedCalorieBudget) kcal")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: finishOnboarding) {
                Text("Start Tracking")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)
            Text(text)
                .font(.body)
        }
    }

    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        granted: Bool?,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let granted = granted {
                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Button("Allow", action: action)
                        .buttonStyle(.bordered)
                        .tint(.green)
                }
            } else {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func profileField(title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(title, text: text)
                .keyboardType(keyboard)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
    }

    private func pickerRow(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func skipButton(destination: Int) -> some View {
        Button(action: { currentPage = destination }) {
            Text("Skip")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Validation & Computation

    private var profileValid: Bool {
        Double(weight) != nil && Double(height) != nil && Int(age) != nil
    }

    private var computedCalorieBudget: Int {
        guard let w = Double(weight), let h = Double(height), let a = Int(age) else {
            return 2000
        }
        let s = gender == "Male" ? 5.0 : -161.0
        let bmr = (10 * w) + (6.25 * h) - (5 * Double(a)) + s

        var multiplier: Double = 1.2
        switch activityLevel {
        case "Light": multiplier = 1.375
        case "Moderate": multiplier = 1.55
        case "Active": multiplier = 1.725
        default: multiplier = 1.2
        }

        var tdee = bmr * multiplier
        switch goal {
        case "Lose": tdee -= 500
        case "Gain": tdee += 500
        default: break
        }
        return Int(tdee)
    }

    // MARK: - Actions

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraGranted = granted
            }
        }
    }

    private func requestHealthPermission() {
        HealthKitManager.shared.requestAuthorization()
        // HealthKitManager publishes isAuthorized; optimistically mark granted
        healthGranted = true
    }

    private func finishOnboarding() {
        saveStats()
    }

    private func saveStats() {
        guard let w = Double(weight), let h = Double(height), let a = Int(age) else {
            // If profile was skipped, save sensible defaults
            let defaults = UserStats(weight: 70, height: 170, age: 30, gender: gender, activityLevel: activityLevel, goal: goal)
            nutritionManager.saveUserStats(defaults)
            hasOnboarded = true
            AnalyticsService.logOnboardingComplete()
            return
        }

        let stats = UserStats(
            weight: w,
            height: h,
            age: a,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal
        )

        nutritionManager.saveUserStats(stats)
        hasOnboarded = true
        AnalyticsService.logOnboardingComplete()
    }
}
