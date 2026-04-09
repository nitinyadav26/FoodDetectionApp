import Foundation
import Combine
import SwiftUI

// MARK: - Data Models
struct INDBFood: Codable, Identifiable {
    let id: String
    let name: String
    let baseCaloriesPer100g: Double
    let baseProteinPer100g: Double
    let baseCarbsPer100g: Double
    let baseFatPer100g: Double
    let servings: [ServingSize]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case baseCaloriesPer100g = "base_calories_per_100g"
        case baseProteinPer100g = "base_protein_per_100g"
        case baseCarbsPer100g = "base_carbs_per_100g"
        case baseFatPer100g = "base_fat_per_100g"
        case servings
    }
}

struct ServingSize: Codable, Hashable {
    let label: String
    let weight: Double
}

// MARK: - Food Database Manager
class FoodDatabase: ObservableObject {
    static let shared = FoodDatabase()
    
    @Published var foods: [INDBFood] = []
    @Published var isLoaded: Bool = false
    
    private init() {
        // Load data in background to avoid blocking main thread on launch
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        guard let url = Bundle.main.url(forResource: "indb_foods", withExtension: "json") else {
            print("❌ indb_foods.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let loadedFoods = try decoder.decode([INDBFood].self, from: data)
            
            await MainActor.run {
                self.foods = loadedFoods
                self.isLoaded = true
                print("✅ Internal Food Database loaded: \(self.foods.count) items")
            }
        } catch {
            print("❌ Error loading INDB data: \(error)")
        }
    }
    
    func search(query: String) -> [INDBFood] {
        guard !query.isEmpty else { return [] }
        
        // Simple case-insensitive contains search
        // Can be optimized for large datasets, but fine for ~1000 items
        return foods.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getFood(id: String) -> INDBFood? {
        return foods.first { $0.id == id }
    }
}
