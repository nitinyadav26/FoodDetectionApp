import XCTest
@testable import FoodDetectionApp

final class NutritionManagerTests: XCTestCase {
    var manager: NutritionManager!

    override func setUp() {
        super.setUp()
        manager = NutritionManager()
        // Clear any persisted state so tests start fresh
        manager.logs = []
        manager.userStats = nil
        manager.calorieBudget = 2000
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Calorie Budget Tests

    /// Male, 80kg, 180cm, age 30, Moderate activity, Maintain goal.
    /// Mifflin-St Jeor: BMR = (10 * 80) + (6.25 * 180) - (5 * 30) + 5 = 800 + 1125 - 150 + 5 = 1780
    /// TDEE = 1780 * 1.55 = 2759
    func testCalorieBudgetMaleModerate() {
        let stats = UserStats(weight: 80, height: 180, age: 30, gender: "Male", activityLevel: "Moderate", goal: "Maintain")
        manager.saveUserStats(stats)

        let expectedBMR = (10.0 * 80) + (6.25 * 180) - (5.0 * 30) + 5.0 // 1780
        let expectedTDEE = expectedBMR * 1.55 // 2759
        XCTAssertEqual(manager.calorieBudget, Int(expectedTDEE), "Male moderate budget should match Mifflin-St Jeor")
    }

    /// Female, 65kg, 165cm, age 25, Moderate activity, Maintain goal.
    /// BMR = (10 * 65) + (6.25 * 165) - (5 * 25) + (-161) = 650 + 1031.25 - 125 - 161 = 1395.25
    /// TDEE = 1395.25 * 1.55 = 2162.6375
    func testCalorieBudgetFemale() {
        let stats = UserStats(weight: 65, height: 165, age: 25, gender: "Female", activityLevel: "Moderate", goal: "Maintain")
        manager.saveUserStats(stats)

        let expectedBMR = (10.0 * 65) + (6.25 * 165) - (5.0 * 25) + (-161.0) // 1395.25
        let expectedTDEE = expectedBMR * 1.55 // 2162.6375
        XCTAssertEqual(manager.calorieBudget, Int(expectedTDEE), "Female budget should use -161 constant")
    }

    /// Lose goal should subtract 500 from TDEE.
    /// Male, 80kg, 180cm, age 30, Moderate.
    /// TDEE = 1780 * 1.55 - 500 = 2259
    func testCalorieBudgetGoalLose() {
        let stats = UserStats(weight: 80, height: 180, age: 30, gender: "Male", activityLevel: "Moderate", goal: "Lose")
        manager.saveUserStats(stats)

        let expectedBMR = (10.0 * 80) + (6.25 * 180) - (5.0 * 30) + 5.0
        let expectedTDEE = expectedBMR * 1.55 - 500
        XCTAssertEqual(manager.calorieBudget, Int(expectedTDEE), "Lose goal should subtract 500 calories")
    }

    /// Gain goal should add 500 to TDEE.
    func testCalorieBudgetGoalGain() {
        let stats = UserStats(weight: 80, height: 180, age: 30, gender: "Male", activityLevel: "Moderate", goal: "Gain")
        manager.saveUserStats(stats)

        let expectedBMR = (10.0 * 80) + (6.25 * 180) - (5.0 * 30) + 5.0
        let expectedTDEE = expectedBMR * 1.55 + 500
        XCTAssertEqual(manager.calorieBudget, Int(expectedTDEE), "Gain goal should add 500 calories")
    }

    // MARK: - Nutrition Scaling

    /// Scaling 200g should double the per-100g values.
    func testNutritionScaling() {
        let info = NutritionInfo(
            calories: "250",
            recipe: "Test recipe",
            carbs: "30",
            protein: "20",
            fats: "10",
            source: "Test",
            micros: ["Iron": "5 mg", "Vitamin C": "10 mg"]
        )

        let scaled = manager.calculateNutrition(for: info, weight: 200)

        XCTAssertEqual(scaled.calories, "500.0", "Calories should double for 200g")
        XCTAssertEqual(scaled.carbs, "60.0", "Carbs should double for 200g")
        XCTAssertEqual(scaled.protein, "40.0", "Protein should double for 200g")
        XCTAssertEqual(scaled.fats, "20.0", "Fats should double for 200g")
        XCTAssertEqual(scaled.recipe, "Test recipe", "Recipe should remain unchanged")
        XCTAssertNotNil(scaled.micros, "Micros should be present after scaling")
    }

    // MARK: - Food Logging

    /// Log a food item and verify it appears in todayLogs.
    func testLogFood() {
        let info = NutritionInfo(
            calories: "200",
            recipe: "Grilled chicken",
            carbs: "0",
            protein: "31",
            fats: "3.6",
            source: "USDA",
            micros: nil
        )

        manager.logFood(dish: "Chicken Breast", info: info)

        XCTAssertEqual(manager.todayLogs.count, 1, "Should have one log entry")
        XCTAssertEqual(manager.todayLogs.first?.food, "Chicken Breast")
        XCTAssertEqual(manager.todayLogs.first?.calories, 200)
        XCTAssertEqual(manager.todayLogs.first?.protein, 31)
    }

    /// Log multiple items and verify summary totals.
    func testTodaySummary() {
        let chicken = NutritionInfo(
            calories: "200", recipe: "", carbs: "0", protein: "31", fats: "4", source: "Test", micros: nil
        )
        let rice = NutritionInfo(
            calories: "130", recipe: "", carbs: "28", protein: "3", fats: "0", source: "Test", micros: nil
        )

        manager.logFood(dish: "Chicken", info: chicken)
        manager.logFood(dish: "Rice", info: rice)

        let summary = manager.todaySummary
        XCTAssertEqual(summary.cals, 330, "Total calories should be 200 + 130")
        XCTAssertEqual(summary.protein, 34, "Total protein should be 31 + 3")
        XCTAssertEqual(summary.carbs, 28, "Total carbs should be 0 + 28")
        XCTAssertEqual(summary.fats, 4, "Total fats should be 4 + 0")
    }

    /// Log then delete, verify removed.
    func testDeleteLog() {
        let info = NutritionInfo(
            calories: "100", recipe: "", carbs: "10", protein: "5", fats: "2", source: "Test", micros: nil
        )

        manager.logFood(dish: "Snack", info: info)
        XCTAssertEqual(manager.todayLogs.count, 1)

        manager.deleteLog(at: IndexSet(integer: 0))
        XCTAssertEqual(manager.todayLogs.count, 0, "Log should be removed after deletion")
    }

    // MARK: - Export

    /// Verify exportAllData returns valid JSON with expected keys.
    func testExportAllData() {
        let stats = UserStats(weight: 70, height: 170, age: 28, gender: "Male", activityLevel: "Light", goal: "Maintain")
        manager.saveUserStats(stats)

        let info = NutritionInfo(
            calories: "150", recipe: "Salad", carbs: "10", protein: "5", fats: "8", source: "Test", micros: nil
        )
        manager.logFood(dish: "Salad", info: info)

        let exportData = manager.exportAllData()
        XCTAssertFalse(exportData.isEmpty, "Export data should not be empty")

        // Verify it parses as valid JSON with expected structure
        let parsed = try? JSONSerialization.jsonObject(with: exportData) as? [String: Any]
        XCTAssertNotNil(parsed, "Export should produce valid JSON")
        XCTAssertNotNil(parsed?["stats"], "Export should contain stats")
        XCTAssertNotNil(parsed?["logs"], "Export should contain logs")
        XCTAssertNotNil(parsed?["exportDate"], "Export should contain exportDate")

        if let logs = parsed?["logs"] as? [[String: Any]] {
            XCTAssertEqual(logs.count, 1, "Export should contain one log entry")
        } else {
            XCTFail("logs should be an array of dictionaries")
        }
    }
}
