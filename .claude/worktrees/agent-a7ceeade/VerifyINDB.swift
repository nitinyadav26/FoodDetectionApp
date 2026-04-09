import Foundation

// Copying necessary structs for testing
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

func test() {
    print("--- Starting Verification ---")
    let fileUrl = URL(fileURLWithPath: "FoodDetectionApp/indb_foods.json")
    
    do {
        let data = try Data(contentsOf: fileUrl)
        let foods = try JSONDecoder().decode([INDBFood].self, from: data)
        print("✅ Success: Loaded \(foods.count) items.")
        
        // Test 1: Search
        let query = "Dal"
        let results = foods.filter { $0.name.localizedCaseInsensitiveContains(query) }
        print("🔍 Search for '\(query)': Found \(results.count) results.")
        if let first = results.first {
            print("   Example: \(first.name) -> \(first.baseCaloriesPer100g) kcal/100g")
            print("   Servings: \(first.servings)")
            
            // Test 2: Calculation
            if let serving = first.servings.first {
                let ratio = serving.weight / 100.0
                let cals = first.baseCaloriesPer100g * ratio
                print("   🧮 Calculation for 1 \(serving.label) (\(serving.weight)g): \(cals) kcal")
            }
        }
        
        // Test 3: Macros Check
        let macroCheck = foods.filter { $0.baseProteinPer100g > 0 }
        print("✅ Macro Check: \(macroCheck.count) items have protein data.")
        
    } catch {
        print("❌ Error: \(error)")
    }
}

test()
