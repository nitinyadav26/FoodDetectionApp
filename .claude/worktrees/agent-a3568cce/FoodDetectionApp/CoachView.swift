import SwiftUI

struct CoachView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var healthManager = HealthKitManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var advice: String = "Tap a button to get personalized advice!"
    @State private var isLoading = false
    @State private var historyString: String = "Loading history..."
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("AI Health Coach")
                                .font(.title.bold())
                            Text("Your 30-day health companion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    
                    // Quick Actions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CoachChip(title: "🥗 Recipe", icon: "carrot.fill", color: .green) {
                                getAdvice(query: "Give me a healthy recipe using ingredients I eat often.")
                            }
                            .accessibilityLabel("Recipe Ideas")
                            .accessibilityHint("Asks the AI coach for a healthy recipe based on your eating habits")

                            CoachChip(title: "🍎 What to eat?", icon: "fork.knife", color: .orange) {
                                getAdvice(query: "What should I eat for my next meal based on my nutrition today?")
                            }
                            .accessibilityLabel("What to Eat")
                            .accessibilityHint("Asks the AI coach what to eat for your next meal")

                            CoachChip(title: "❤️ Health Check", icon: "heart.text.square.fill", color: .red) {
                                getAdvice(query: "Analyze my last 30 days of health data. How am I doing?")
                            }
                            .accessibilityLabel("Health Check")
                            .accessibilityHint("Asks the AI coach to analyze your 30-day health data")

                            CoachChip(title: "✨ Motivation", icon: "sparkles", color: .purple) {
                                getAdvice(query: "Give me some general motivation.")
                            }
                            .accessibilityLabel("Motivation")
                            .accessibilityHint("Asks the AI coach for motivational advice")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Advice Card
                    VStack(alignment: .leading) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Analyzing 30 days of data...")
                                Spacer()
                            }
                            .padding()
                            .accessibilityLabel("Analyzing your 30 days of health data, please wait")
                        } else {
                            Text(LocalizedStringKey(advice))
                                .font(.body)
                                .padding()
                                .contextMenu {
                                    Button("Copy") {
                                        UIPasteboard.general.string = advice
                                    }
                                }
                                .accessibilityLabel(advice)
                                .accessibilityHint("Long press to copy the advice text")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding()
                    
                    // History Debug
                    DisclosureGroup("View Data Context") {
                        Text(historyString)
                            .font(.system(.caption2, design: .monospaced)) // SAFE for iOS 15
                            .padding()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Coach")
            .navigationBarHidden(true)
            .onAppear(perform: loadHistory)
        }
        .navigationViewStyle(.stack)
    }
    
    func loadHistory() {
        Task {
            // 1. Get Food History (String)
            let foodHist = nutritionManager.getHistory(days: 7)
            
            // 2. Get Health History (Map)
            // Call on shared instance to avoid ObservedObject async wrapper issues if any
            let healthHist = await HealthKitManager.shared.fetchHistory(days: 7)
            
            // 3. Merge
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var healthString = "--- Health Data (Steps, Water, Burn, Sleep) ---\n"
            let sortedHealth = healthHist.keys.sorted(by: >)
            for date in sortedHealth {
                let dStr = dateFormatter.string(from: date)
                if let h = healthHist[date] {
                    healthString += "[\(dStr)] Steps:\(h.steps) Water:\(String(format: "%.1f", h.water)) Burn:\(h.burn) Sleep:\(String(format: "%.1f", h.sleep))\n"
                }
            }
            
            let finalToon = healthString + "\n--- Food Data ---\n" + foodHist
            
            DispatchQueue.main.async {
                self.historyString = finalToon
            }
        }
    }
    
    func getAdvice(query: String) {
        guard networkMonitor.isConnected else {
            advice = "You're offline. AI Coach requires an internet connection."
            return
        }
        isLoading = true

        let healthData = "Steps: \(healthManager.stepCount), Sleep: \(healthManager.sleepHours), Water: \(healthManager.waterIntake)L, Burn: \(healthManager.activeCalories)"
        
        Task {
            do {
                let response = try await APIService.shared.getCoachAdvice(
                    userStats: nutritionManager.userStats,
                    logs: nutritionManager.todayLogs,
                    healthData: healthData,
                    historyTOON: historyString,
                    userQuery: query
                )
                DispatchQueue.main.async {
                    self.advice = response
                    self.isLoading = false
                    AnalyticsService.logCoachQuery(query: query)
                }
            } catch {
                DispatchQueue.main.async {
                    self.advice = "Coach is busy. (Error: \(error.localizedDescription))"
                    self.isLoading = false
                }
            }
        }
    }
}

struct CoachChip: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption.bold()) // Safe for iOS 15 used properly
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(width: 100, height: 100)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
