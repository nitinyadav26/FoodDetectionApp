import SwiftUI

struct DashboardView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var healthManager = HealthKitManager.shared
    @ObservedObject var streakManager = StreakManager.shared
    @ObservedObject var xpManager = XPManager.shared
    @ObservedObject var badgeManager = BadgeManager.shared
    @State private var selectedLog: NutritionManager.FoodLog?
    @State private var selectedDate = Date()
    @State private var showManualLog = false
    @State private var showVoiceLog = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header & Date Slider
                VStack(spacing: 10) {
                    HStack {
                        Text("🍛 FoodSense")
                            .font(.title)
                            .bold()
                        Spacer()
                        Button(action: { showVoiceLog = true }) {
                            Image(systemName: "mic.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                        }
                        .accessibilityLabel("Voice log")
                        .accessibilityHint("Opens voice food logging")
                        Button(action: { showManualLog = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Add food")
                        .accessibilityHint("Opens the manual food logging screen")
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    DateSlider(selectedDate: $selectedDate)
                        .padding(.bottom, 10)
                }
                .background(Color(UIColor.secondarySystemBackground))
                
                List {
                    // Summary Section
                    Section {
                        // Nutrition Summary
                        VStack(spacing: 15) {
                            let summary = nutritionManager.summary(for: selectedDate)
                            
                            HStack {
                                Text(isToday(selectedDate) ? "Nutrition Today" : "Nutrition for \(formatDate(selectedDate))")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            HStack(spacing: 20) {
                                StatRing(label: "Cals", value: summary.cals, target: nutritionManager.calorieBudget, color: .green)
                                    .accessibilityLabel("Calories: \(summary.cals) of \(nutritionManager.calorieBudget)")
                                    .accessibilityValue("\(Int(Double(summary.cals) / Double(max(nutritionManager.calorieBudget, 1)) * 100)) percent")
                                StatRing(label: "Prot", value: summary.protein, target: 150, color: .blue)
                                    .accessibilityLabel("Protein: \(summary.protein) of 150 grams")
                                    .accessibilityValue("\(Int(Double(summary.protein) / 150.0 * 100)) percent")
                                StatRing(label: "Carb", value: summary.carbs, target: 250, color: .orange)
                                    .accessibilityLabel("Carbs: \(summary.carbs) of 250 grams")
                                    .accessibilityValue("\(Int(Double(summary.carbs) / 250.0 * 100)) percent")
                                StatRing(label: "Fat", value: summary.fats, target: 70, color: .red)
                                    .accessibilityLabel("Fat: \(summary.fats) of 70 grams")
                                    .accessibilityValue("\(Int(Double(summary.fats) / 70.0 * 100)) percent")
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground)) // Changed to system for contrast in List
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // Health Kit Summary
                        VStack(spacing: 15) {
                            let health = healthManager.getData(for: selectedDate)
                            let isToday = isToday(selectedDate)
                            
                            Text(isToday ? "Activity & Health (Today)" : "Activity & Health (\(formatDate(selectedDate)))")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 15) {
                                HealthCard(icon: "figure.walk", value: "\(health.steps)", unit: "steps", color: .orange)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Steps: \(health.steps)")
                                HealthCard(icon: "bed.double.fill", value: String(format: "%.1fh", health.sleep), unit: "", color: .purple)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Sleep: \(String(format: "%.1f", health.sleep)) hours")
                                HealthCard(icon: "flame.fill", value: "\(health.burn)", unit: "kcal", color: .red)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Active calories burned: \(health.burn) kilocalories")
                            }
                            
                            // Water Tracker
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.blue)
                                    .accessibilityHidden(true)
                                Text("Water: \(health.water, specifier: "%.1f") L")
                                    .font(.headline)
                                Spacer()

                                if isToday {
                                    Button(action: {
                                        healthManager.logWater(amountML: 250)
                                        AnalyticsService.logWaterLogged(ml: 250)
                                    }) {
                                        Text("+ 250ml")
                                            .font(.caption)
                                            .bold()
                                            .padding(8)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(8)
                                    }
                                    .accessibilityLabel("Log 250 milliliters of water")
                                    .accessibilityHint("Adds 250 milliliters to today's water intake")
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    // Streak & XP Card
                    Section {
                        VStack(spacing: 12) {
                            // Streak row
                            HStack {
                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(streakManager.currentStreak) Day Streak")
                                        .font(.headline)
                                    Text("Longest: \(streakManager.longestStreak) days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .accessibilityElement(children: .combine)

                            // XP Progress Bar
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Lv.\(xpManager.level) \(xpManager.title)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(xpManager.totalXP) XP")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                ProgressView(value: xpManager.progressToNext)
                                    .tint(.blue)
                                    .accessibilityLabel("XP progress: \(Int(xpManager.progressToNext * 100)) percent to next level")
                            }
                            .padding(.vertical, 4)

                            // Top 3 earned badges + View All
                            let topBadges = badgeManager.topEarnedBadges(count: 3)
                            if !topBadges.isEmpty {
                                HStack(spacing: 12) {
                                    ForEach(topBadges) { badge in
                                        HStack(spacing: 4) {
                                            Image(systemName: badge.icon)
                                                .foregroundColor(.blue)
                                            Text(NSLocalizedString(badge.name, comment: ""))
                                                .font(.caption2)
                                        }
                                    }
                                    Spacer()
                                }
                            }

                            NavigationLink(destination: BadgesView()) {
                                HStack {
                                    Image(systemName: "rosette")
                                        .foregroundColor(.blue)
                                    Text(NSLocalizedString("view_all_badges", comment: ""))
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("\(badgeManager.earnedCount)/\(badgeManager.totalCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // Log History Section
                    Section(header: Text("Log History").font(.title2).bold()) {
                        let logs = nutritionManager.logs(for: selectedDate)
                        
                        if logs.isEmpty {
                            Text("No food logged for this day")
                                .foregroundColor(.secondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(logs) { log in
                                Button(action: {
                                    selectedLog = log
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(log.food)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(log.time, style: .time)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("\(log.calories) kcal")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.green)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(log.food), \(log.calories) kilocalories")
                                .accessibilityHint("Double-tap to view details")
                            }
                            .onDelete(perform: deleteLog)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedLog) { log in
                LogDetailView(log: log)
            }
            .sheet(isPresented: $showManualLog) {
                ManualLogView()
            }
            .sheet(isPresented: $showVoiceLog) {
                VoiceLogView()
            }
            .onAppear {
                healthManager.requestAuthorization()
                streakManager.updateStreak()
            }
        }
        .navigationViewStyle(.stack)
    }

    func deleteLog(at offsets: IndexSet) {
        // We need to delete from the MAIN list based on IDs, not just the index in the filtered list
        let currentLogs = nutritionManager.logs(for: selectedDate)
        let idsToDelete = offsets.map { currentLogs[$0].id }
        
        // Directly remove from manager's main list
        nutritionManager.logs.removeAll { idsToDelete.contains($0.id) }
        nutritionManager.saveLogs()
    }
    
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Date Slider Component
struct DateSlider: View {
    @Binding var selectedDate: Date
    
    // Generate last 30 days (Today -> Past)
    var dates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(dates, id: \.self) { date in
                    DateBubble(date: date, isSelected: Calendar.current.isDate(selectedDate, inSameDayAs: date))
                        .onTapGesture {
                            withAnimation {
                                selectedDate = date
                            }
                        }
                        // Use a stable ID for sorting if needed, but self is fine for distinct dates
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DateBubble: View {
    let date: Date
    let isSelected: Bool
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue
        return formatter.string(from: date).uppercased()
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var fullDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    var body: some View {
        VStack {
            Text(dayName)
                .font(.caption2)
                .fontWeight(.bold)
            Text(dayNumber)
                .font(.body)
                .fontWeight(.bold)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground)))
        .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fullDateLabel)\(isToday ? ", today" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double-tap to view this day's data")
    }
}

struct LogDetailView: View {
    let log: NutritionManager.FoodLog
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Dismisses the food detail view")
                }
                .padding()
                
                // Title
                Text(log.food)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text(log.time, style: .date)
                    .foregroundColor(.secondary)
                
                // Macros
                HStack(spacing: 20) {
                    MacroRing(label: "Calories", value: String(log.calories), color: .green)
                    MacroRing(label: "Protein", value: String(log.protein) + "g", color: .blue)
                    MacroRing(label: "Carbs", value: String(log.carbs) + "g", color: .orange)
                    MacroRing(label: "Fats", value: String(log.fats) + "g", color: .red)
                }
                .padding()
                
                // Micros (if available)
                if let micros = log.micros, !micros.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Micronutrients")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(micros.sorted(by: >), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(value)
                                        .font(.subheadline)
                                        .bold()
                                }
                                .padding(10)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Recipe/Advice (if available)
                if let recipe = log.recipe {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Healthier Advice")
                            .font(.headline)
                        
                        Text(recipe)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
}

struct HealthCard: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(5)
            Text(value)
                .font(.headline)
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StatRing: View {
    let label: String
    let value: Int
    let target: Int
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: min(CGFloat(value) / CGFloat(max(target, 1)), 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(value)")
                    .font(.caption)
                    .bold()
            }
            .frame(width: 50, height: 50)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
