import Foundation
import Combine

import SwiftUI

struct NutritionInfo: Codable {
    let calories: String
    let recipe: String
    let carbs: String
    let protein: String
    let fats: String
    let source: String
    var micros: [String: String]? // Optional micros
    
    enum CodingKeys: String, CodingKey {
        case calories = "Calories per 100g"
        case recipe = "Healthier Recipe"
        case carbs = "Carbohydrate per 100g"
        case protein = "Protein per 100 gm"
        case fats = "Fats per 100 gm"
        case source = "Source"
        case micros
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        func decodeString(forKey key: CodingKeys) -> String {
            if let value = try? container.decode(String.self, forKey: key) { return value }
            if let value = try? container.decode(Double.self, forKey: key) { return String(value) }
            if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
            return "N/A"
        }
        
        calories = decodeString(forKey: .calories)
        recipe = decodeString(forKey: .recipe)
        carbs = decodeString(forKey: .carbs)
        protein = decodeString(forKey: .protein)
        fats = decodeString(forKey: .fats)
        source = decodeString(forKey: .source)
        micros = try? container.decodeIfPresent([String: String].self, forKey: .micros)
    }
    
    // Manual init for ChatGPT results
    init(calories: String, recipe: String, carbs: String, protein: String, fats: String, source: String, micros: [String: String]?) {
        self.calories = calories
        self.recipe = recipe
        self.carbs = carbs
        self.protein = protein
        self.fats = fats
        self.source = source
        self.micros = micros
    }
}

struct UserStats: Codable {
    var weight: Double // kg
    var height: Double // cm
    var age: Int
    var gender: String // "Male", "Female"
    var activityLevel: String // "Sedentary", "Light", "Moderate", "Active"
    var goal: String // "Lose", "Maintain", "Gain"
}

class NutritionManager: ObservableObject {
    static let shared = NutritionManager()
    @Published var nutritionData: [String: NutritionInfo] = [:]
    @Published var logs: [FoodLog] = []
    @Published var userStats: UserStats?
    @Published var calorieBudget: Int = 2000
    
    struct FoodLog: Identifiable, Codable {
        var id = UUID()
        let food: String
        let calories: Int
        let protein: Int
        let carbs: Int
        let fats: Int
        let micros: [String: String]?
        let recipe: String?
        let time: Date
    }
    
    init() {
        loadData()
        loadUserStats()
    }
    

    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "nutrition_data", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.nutritionData = try decoder.decode([String: NutritionInfo].self, from: data)
        } catch {
            print("Error decoding nutrition data: \(error)")
        }
    }
    
    func loadUserStats() {
        if let data = UserDefaults.standard.data(forKey: "userStats"),
           let stats = try? JSONDecoder().decode(UserStats.self, from: data) {
            self.userStats = stats
            calculateBudget()
        }
        
        if let data = UserDefaults.standard.data(forKey: "foodLogs"),
           let savedLogs = try? JSONDecoder().decode([FoodLog].self, from: data) {
            self.logs = savedLogs
        }
    }
    
    func saveUserStats(_ stats: UserStats) {
        self.userStats = stats
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "userStats")
        }
        calculateBudget()
    }
    
    func calculateBudget() {
        guard let stats = userStats else { return }
        
        // Mifflin-St Jeor Equation
        let s = stats.gender == "Male" ? 5.0 : -161.0
        let bmr = (10 * stats.weight) + (6.25 * stats.height) - (5 * Double(stats.age)) + s
        
        var activityMultiplier: Double = 1.2
        switch stats.activityLevel {
        case "Light": activityMultiplier = 1.375
        case "Moderate": activityMultiplier = 1.55
        case "Active": activityMultiplier = 1.725
        default: activityMultiplier = 1.2
        }
        
        var tdee = bmr * activityMultiplier
        
        switch stats.goal {
        case "Lose": tdee -= 500
        case "Gain": tdee += 500
        default: break
        }
        
        self.calorieBudget = Int(tdee)
    }
    
    func getNutrition(for dish: String) -> NutritionInfo? {
        return nutritionData[dish]
    }
    
    func calculateNutrition(for info: NutritionInfo, weight: Double) -> NutritionInfo {
        let ratio = weight / 100.0
        
        func scale(_ val: String) -> String {
            let allowed = CharacterSet(charactersIn: "0123456789.")
            let filtered = val.components(separatedBy: allowed.inverted).joined()
            let num = Double(filtered) ?? 0
            return String(format: "%.1f", num * ratio)
        }
        
        var scaledMicros: [String: String]? = nil
        if let micros = info.micros {
            scaledMicros = [:]
            for (key, val) in micros {
                // Try to scale numbers in micros (e.g. "10 mg" -> "20.0 mg")
                let allowed = CharacterSet(charactersIn: "0123456789.")
                let filtered = val.components(separatedBy: allowed.inverted).joined()
                let num = Double(filtered) ?? 0
                let unit = val.trimmingCharacters(in: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")))
                scaledMicros?[key] = String(format: "%.1f%@", num * ratio, unit)
            }
        }
        
        return NutritionInfo(
            calories: scale(info.calories),
            recipe: info.recipe,
            carbs: scale(info.carbs),
            protein: scale(info.protein),
            fats: scale(info.fats),
            source: info.source,
            micros: scaledMicros
        )
    }
    
    func logFood(dish: String, info: NutritionInfo? = nil, weight: Double = 100.0) {
        var nutrition = info ?? getNutrition(for: dish)
        
        // Fallback if no nutrition info found
        if nutrition == nil {
            nutrition = NutritionInfo(
                calories: "0",
                recipe: "No recipe available.",
                carbs: "0",
                protein: "0",
                fats: "0",
                source: "Unknown",
                micros: nil
            )
        }
        
        guard let n = nutrition else { return }
        
        // Scale if weight is not 100
        if weight != 100.0 {
            nutrition = calculateNutrition(for: n, weight: weight)
        }
        
        func parse(_ val: String) -> Int {
            // Allow numbers and decimal point
            let allowed = CharacterSet(charactersIn: "0123456789.")
            let filtered = val.components(separatedBy: allowed.inverted).joined()
            return Int(Double(filtered) ?? 0)
        }
        
        let log = FoodLog(
            food: dish,
            calories: parse(nutrition!.calories),
            protein: parse(nutrition!.protein),
            carbs: parse(nutrition!.carbs),
            fats: parse(nutrition!.fats),
            micros: nutrition!.micros,
            recipe: nutrition!.recipe,
            time: Date()
        )
        logs.insert(log, at: 0)
        saveLogs()
    }
    
    func deleteLog(at offsets: IndexSet) {
        // Since we are displaying 'todayLogs' in the UI but deleting from 'logs', we need to find the correct index.
        // For MVP simplicity, we assume the UI passes the Log object or we handle it carefully.
        // SwiftUI 'onDelete' gives indices relative to the displayed collection.
        // We will filter todayLogs, find the IDs, and remove them from main logs.
        let candidates = todayLogs
        let idsToDelete = offsets.map { candidates[$0].id }
        
        logs.removeAll { idsToDelete.contains($0.id) }
        saveLogs()
    }
    
    func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: "foodLogs")
        }
    }
    
    func logs(for date: Date) -> [FoodLog] {
        let calendar = Calendar.current
        return logs.filter { calendar.isDate($0.time, inSameDayAs: date) }
    }
    
    func summary(for date: Date) -> (cals: Int, protein: Int, carbs: Int, fats: Int) {
        logs(for: date).reduce((0, 0, 0, 0)) { (result, log) in
            (result.0 + log.calories, result.1 + log.protein, result.2 + log.carbs, result.3 + log.fats)
        }
    }
    
    var todayLogs: [FoodLog] {
        logs(for: Date())
    }
    
    var todaySummary: (cals: Int, protein: Int, carbs: Int, fats: Int) {
        summary(for: Date())
    }
    
    func exportAllData() -> Data {
        struct ExportPayload: Codable {
            let stats: UserStats?
            let logs: [FoodLog]
            let exportDate: String
        }
        let formatter = ISO8601DateFormatter()
        let payload = ExportPayload(stats: userStats, logs: logs, exportDate: formatter.string(from: Date()))
        return (try? JSONEncoder().encode(payload)) ?? Data()
    }

    func deleteAllData() {
        logs.removeAll()
        userStats = nil
        calorieBudget = 2000
        UserDefaults.standard.removeObject(forKey: "foodLogs")
        UserDefaults.standard.removeObject(forKey: "userStats")
        UserDefaults.standard.removeObject(forKey: "hasOnboarded")
    }

    func getHistory(days: Int) -> String {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return "" }
        
        let filtered = logs.filter { $0.time >= startDate }
        let grouped = Dictionary(grouping: filtered) { log in
            calendar.startOfDay(for: log.time)
        }
        
        var output = ""
        let sortedKeys = grouped.keys.sorted(by: >)
        
        for date in sortedKeys {
            let dayLogs = grouped[date]!
            let totalCals = dayLogs.reduce(0) { $0 + $1.calories }
            let foods = dayLogs.map { "\($0.food)(\($0.calories))" }.joined(separator: ", ")
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let dateStr = df.string(from: date)
            
            output += "[\(dateStr)] Cals: \(totalCals) | Foods: \(foods)\n"
        }
        return output
    }
}
