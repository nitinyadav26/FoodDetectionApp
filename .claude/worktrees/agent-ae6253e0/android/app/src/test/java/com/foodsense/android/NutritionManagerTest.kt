package com.foodsense.android

import com.foodsense.android.data.FoodLog
import com.foodsense.android.data.NutritionInfo
import com.foodsense.android.data.UserStats
import com.foodsense.android.data.parseNumber
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

/**
 * Unit tests for NutritionManager calculation logic.
 *
 * NutritionManager requires an Android Context for SharedPreferences and assets,
 * so we test the pure calculation logic directly here using the same formulas
 * the manager uses.
 */
class NutritionManagerTest {

    // ---------------------------------------------------------------------------
    // Budget calculation helper -- mirrors NutritionManager.calculateBudget()
    // ---------------------------------------------------------------------------
    private fun calculateBudget(stats: UserStats): Int {
        val s = if (stats.gender.equals("Male", ignoreCase = true)) 5.0 else -161.0
        val bmr = (10 * stats.weight) + (6.25 * stats.height) - (5 * stats.age) + s

        val activityMultiplier = when (stats.activityLevel) {
            "Light" -> 1.375
            "Moderate" -> 1.55
            "Active" -> 1.725
            else -> 1.2
        }

        var tdee = bmr * activityMultiplier
        when (stats.goal) {
            "Lose" -> tdee -= 500
            "Gain" -> tdee += 500
        }
        return tdee.toInt()
    }

    // ---------------------------------------------------------------------------
    // Nutrition scaling helper -- mirrors NutritionManager.calculateNutrition()
    // ---------------------------------------------------------------------------
    private fun calculateNutrition(info: NutritionInfo, weight: Double): NutritionInfo {
        val ratio = weight / 100.0
        fun scaled(value: String): String = "%.1f".format(parseNumber(value) * ratio)

        val scaledMicros = info.micros?.mapValues { (_, value) ->
            val numeric = parseNumber(value)
            val unit = value.replace(Regex("[-+]?\\d*\\.?\\d+"), "").trim()
            val scaledValue = "%.1f".format(numeric * ratio)
            if (unit.isNotEmpty()) "$scaledValue $unit" else scaledValue
        }

        return NutritionInfo(
            calories = scaled(info.calories),
            recipe = info.recipe,
            carbs = scaled(info.carbs),
            protein = scaled(info.protein),
            fats = scaled(info.fats),
            source = info.source,
            micros = scaledMicros,
        )
    }

    // ---------------------------------------------------------------------------
    // Summary helper -- mirrors NutritionManager.summaryFor()
    // ---------------------------------------------------------------------------
    private data class Summary(val cals: Int, val protein: Int, val carbs: Int, val fats: Int)

    private fun summarize(logs: List<FoodLog>): Summary {
        return Summary(
            cals = logs.sumOf { it.calories },
            protein = logs.sumOf { it.protein },
            carbs = logs.sumOf { it.carbs },
            fats = logs.sumOf { it.fats },
        )
    }

    // ===== Budget Tests =====

    /**
     * Male, 80kg, 180cm, age 30, Moderate activity, Maintain goal.
     * BMR = (10 * 80) + (6.25 * 180) - (5 * 30) + 5 = 1780
     * TDEE = 1780 * 1.55 = 2759
     */
    @Test
    fun testCalorieBudgetMaleModerate() {
        val stats = UserStats(weight = 80.0, height = 180.0, age = 30, gender = "Male", activityLevel = "Moderate", goal = "Maintain")
        val budget = calculateBudget(stats)

        val expectedBMR = (10.0 * 80) + (6.25 * 180) - (5.0 * 30) + 5.0
        val expectedTDEE = expectedBMR * 1.55
        assertEquals("Male moderate budget should match Mifflin-St Jeor", expectedTDEE.toInt(), budget)
    }

    /**
     * Female, 65kg, 165cm, age 25, Moderate activity, Maintain goal.
     * BMR = (10 * 65) + (6.25 * 165) - (5 * 25) - 161 = 1395.25
     * TDEE = 1395.25 * 1.55 = 2162 (truncated)
     */
    @Test
    fun testCalorieBudgetFemale() {
        val stats = UserStats(weight = 65.0, height = 165.0, age = 25, gender = "Female", activityLevel = "Moderate", goal = "Maintain")
        val budget = calculateBudget(stats)

        val expectedBMR = (10.0 * 65) + (6.25 * 165) - (5.0 * 25) + (-161.0)
        val expectedTDEE = expectedBMR * 1.55
        assertEquals("Female budget should use -161 constant", expectedTDEE.toInt(), budget)
    }

    /**
     * Lose goal should subtract 500 from TDEE.
     */
    @Test
    fun testCalorieBudgetGoalLose() {
        val stats = UserStats(weight = 80.0, height = 180.0, age = 30, gender = "Male", activityLevel = "Moderate", goal = "Lose")
        val budget = calculateBudget(stats)

        val expectedBMR = (10.0 * 80) + (6.25 * 180) - (5.0 * 30) + 5.0
        val expectedTDEE = expectedBMR * 1.55 - 500
        assertEquals("Lose goal should subtract 500 calories", expectedTDEE.toInt(), budget)
    }

    /**
     * Gain goal should add 500 to TDEE.
     */
    @Test
    fun testCalorieBudgetGoalGain() {
        val stats = UserStats(weight = 80.0, height = 180.0, age = 30, gender = "Male", activityLevel = "Moderate", goal = "Gain")
        val budget = calculateBudget(stats)

        val expectedBMR = (10.0 * 80) + (6.25 * 180) - (5.0 * 30) + 5.0
        val expectedTDEE = expectedBMR * 1.55 + 500
        assertEquals("Gain goal should add 500 calories", expectedTDEE.toInt(), budget)
    }

    /**
     * Sedentary activity level should use 1.2 multiplier.
     */
    @Test
    fun testCalorieBudgetSedentary() {
        val stats = UserStats(weight = 70.0, height = 175.0, age = 35, gender = "Male", activityLevel = "Sedentary", goal = "Maintain")
        val budget = calculateBudget(stats)

        val expectedBMR = (10.0 * 70) + (6.25 * 175) - (5.0 * 35) + 5.0
        val expectedTDEE = expectedBMR * 1.2
        assertEquals("Sedentary should use 1.2 multiplier", expectedTDEE.toInt(), budget)
    }

    /**
     * Active activity level should use 1.725 multiplier.
     */
    @Test
    fun testCalorieBudgetActive() {
        val stats = UserStats(weight = 70.0, height = 175.0, age = 35, gender = "Male", activityLevel = "Active", goal = "Maintain")
        val budget = calculateBudget(stats)

        val expectedBMR = (10.0 * 70) + (6.25 * 175) - (5.0 * 35) + 5.0
        val expectedTDEE = expectedBMR * 1.725
        assertEquals("Active should use 1.725 multiplier", expectedTDEE.toInt(), budget)
    }

    // ===== Nutrition Scaling Tests =====

    /**
     * Scaling 200g should double the per-100g values.
     */
    @Test
    fun testNutritionScaling() {
        val info = NutritionInfo(
            calories = "250",
            recipe = "Test recipe",
            carbs = "30",
            protein = "20",
            fats = "10",
            source = "Test",
            micros = mapOf("Iron" to "5 mg", "Vitamin C" to "10 mg"),
        )

        val scaled = calculateNutrition(info, 200.0)

        assertEquals("Calories should double for 200g", "500.0", scaled.calories)
        assertEquals("Carbs should double for 200g", "60.0", scaled.carbs)
        assertEquals("Protein should double for 200g", "40.0", scaled.protein)
        assertEquals("Fats should double for 200g", "20.0", scaled.fats)
        assertEquals("Recipe should remain unchanged", "Test recipe", scaled.recipe)
        assertNotNull("Micros should be present after scaling", scaled.micros)
    }

    /**
     * Scaling 50g should halve the per-100g values.
     */
    @Test
    fun testNutritionScalingHalf() {
        val info = NutritionInfo(
            calories = "200",
            recipe = "Some recipe",
            carbs = "40",
            protein = "10",
            fats = "6",
            source = "Test",
            micros = null,
        )

        val scaled = calculateNutrition(info, 50.0)

        assertEquals("Calories should halve for 50g", "100.0", scaled.calories)
        assertEquals("Carbs should halve for 50g", "20.0", scaled.carbs)
        assertEquals("Protein should halve for 50g", "5.0", scaled.protein)
        assertEquals("Fats should halve for 50g", "3.0", scaled.fats)
    }

    /**
     * Scaling at exactly 100g should return the same numeric values.
     */
    @Test
    fun testNutritionScalingIdentity() {
        val info = NutritionInfo(
            calories = "150",
            recipe = "Salad",
            carbs = "10",
            protein = "5",
            fats = "8",
            source = "Test",
            micros = null,
        )

        val scaled = calculateNutrition(info, 100.0)

        assertEquals("150.0", scaled.calories)
        assertEquals("10.0", scaled.carbs)
        assertEquals("5.0", scaled.protein)
        assertEquals("8.0", scaled.fats)
    }

    // ===== Summary Tests =====

    /**
     * Summarize multiple food logs and verify totals.
     */
    @Test
    fun testSummaryCalculation() {
        val logs = listOf(
            FoodLog(food = "Chicken", calories = 200, protein = 31, carbs = 0, fats = 4),
            FoodLog(food = "Rice", calories = 130, protein = 3, carbs = 28, fats = 0),
        )

        val summary = summarize(logs)

        assertEquals("Total calories should be 330", 330, summary.cals)
        assertEquals("Total protein should be 34", 34, summary.protein)
        assertEquals("Total carbs should be 28", 28, summary.carbs)
        assertEquals("Total fats should be 4", 4, summary.fats)
    }

    /**
     * Empty logs should produce a zero summary.
     */
    @Test
    fun testSummaryEmpty() {
        val summary = summarize(emptyList())

        assertEquals(0, summary.cals)
        assertEquals(0, summary.protein)
        assertEquals(0, summary.carbs)
        assertEquals(0, summary.fats)
    }

    // ===== parseNumber Tests =====

    @Test
    fun testParseNumberPlainInteger() {
        assertEquals(250.0, parseNumber("250"), 0.01)
    }

    @Test
    fun testParseNumberWithUnit() {
        assertEquals(5.0, parseNumber("5 mg"), 0.01)
    }

    @Test
    fun testParseNumberDecimal() {
        assertEquals(3.6, parseNumber("3.6"), 0.01)
    }

    @Test
    fun testParseNumberNonNumeric() {
        assertEquals(0.0, parseNumber("N/A"), 0.01)
    }
}
