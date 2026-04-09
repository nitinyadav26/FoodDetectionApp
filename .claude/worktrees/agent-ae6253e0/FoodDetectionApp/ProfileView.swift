import SwiftUI

struct ProfileView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var xpManager = XPManager.shared
    @ObservedObject var badgeManager = BadgeManager.shared

    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Male"
    @State private var activityLevel: String = "Moderate"
    @State private var goal: String = "Maintain"
    @State private var isEditing = false
    
    let genders = ["Male", "Female", "Other"]
    let activityLevels = ["Sedentary", "Light", "Moderate", "Active"]
    let goals = ["Lose", "Maintain", "Gain"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Physical Stats")) {
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        if isEditing {
                            TextField("kg", text: $weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text("\(nutritionManager.userStats?.weight ?? 70, specifier: "%.1f")")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        if isEditing {
                            TextField("cm", text: $height)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text("\(nutritionManager.userStats?.height ?? 170, specifier: "%.0f")")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        if isEditing {
                            TextField("Years", text: $age)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text("\(nutritionManager.userStats?.age ?? 25)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isEditing {
                        Picker("Gender", selection: $gender) {
                            ForEach(genders, id: \.self) { Text($0) }
                        }
                    } else {
                        HStack {
                            Text("Gender")
                            Spacer()
                            Text(nutritionManager.userStats?.gender ?? "Male")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Goals & Activity")) {
                    if isEditing {
                        Picker("Activity Level", selection: $activityLevel) {
                            ForEach(activityLevels, id: \.self) { Text($0) }
                        }
                        Picker("Goal", selection: $goal) {
                            ForEach(goals, id: \.self) { Text($0) }
                        }
                    } else {
                        HStack {
                            Text("Activity Level")
                            Spacer()
                            Text(nutritionManager.userStats?.activityLevel ?? "Moderate")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Goal")
                            Spacer()
                            Text(nutritionManager.userStats?.goal ?? "Maintain")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Daily Calorie Budget")
                        Spacer()
                        Text("\(nutritionManager.calorieBudget) kcal")
                            .bold()
                            .foregroundColor(.green)
                    }
                }

                // Achievements Section
                Section(header: Text(NSLocalizedString("achievements_title", comment: ""))) {
                    // Level & Title
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lv.\(xpManager.level) \(xpManager.title)")
                                .font(.headline)
                            Text("\(xpManager.totalXP) \(NSLocalizedString("xp_total", comment: ""))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    // XP Progress Bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(NSLocalizedString("xp_progress", comment: ""))
                                .font(.caption)
                            Spacer()
                            Text("\(xpManager.xpInCurrentLevel)/\(xpManager.xpToNextLevel)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: xpManager.progressToNext)
                            .tint(.blue)
                    }

                    // Badge Count
                    HStack {
                        Image(systemName: "rosette")
                            .foregroundColor(.orange)
                        Text(NSLocalizedString("badges_earned_label", comment: ""))
                        Spacer()
                        Text("\(badgeManager.earnedCount)/\(badgeManager.totalCount)")
                            .foregroundColor(.secondary)
                    }

                    // Navigate to BadgesView
                    NavigationLink(destination: BadgesView()) {
                        HStack {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.blue)
                            Text(NSLocalizedString("view_all_badges", comment: ""))
                        }
                    }
                }
            }
            .navigationTitle("Your Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Opens the app settings screen")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveStats()
                        } else {
                            loadStatsForEditing()
                        }
                        isEditing.toggle()
                    }
                    .accessibilityLabel(isEditing ? "Save profile" : "Edit profile")
                    .accessibilityHint(isEditing ? "Saves your profile changes" : "Enables editing of your profile information")
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if nutritionManager.userStats == nil {
                isEditing = true
                weight = "70"
                height = "170"
                age = "25"
            }
        }
    }
    
    func loadStatsForEditing() {
        if let stats = nutritionManager.userStats {
            weight = String(stats.weight)
            height = String(stats.height)
            age = String(stats.age)
            gender = stats.gender
            activityLevel = stats.activityLevel
            goal = stats.goal
        }
    }
    
    func saveStats() {
        let newStats = UserStats(
            weight: Double(weight) ?? 70,
            height: Double(height) ?? 170,
            age: Int(age) ?? 25,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal
        )
        nutritionManager.saveUserStats(newStats)
    }
}
