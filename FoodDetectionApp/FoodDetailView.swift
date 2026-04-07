import SwiftUI

struct FoodDetailView: View {
    let food: INDBFood
    @Environment(\.presentationMode) var presentationMode
    
    // Default to the first serving size or 100g
    @State private var quantity: Double = 1.0
    @State private var selectedServingIndex: Int = 0
    @State private var useCustomWeight: Bool = false
    @State private var customWeight: String = "100"
    
    // Bluetooth Scale Integration
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    @State private var useScaleWeight: Bool = false
    
    // Integration
    var onAdd: (() -> Void)?
    
    var currentWeight: Double {
        if useScaleWeight && bluetoothManager.isConnected {
            return bluetoothManager.currentWeight
        } else if useCustomWeight {
            return Double(customWeight) ?? 0
        } else {
             if food.servings.indices.contains(selectedServingIndex) {
                return food.servings[selectedServingIndex].weight * quantity
            } else {
                return 100.0 * quantity // Fallback (shouldn't happen if servings exist)
            }
        }
    }
    
    var nutrition: (cals: Double, prot: Double, carbs: Double, fats: Double) {
        let ratio = currentWeight / 100.0
        return (
            food.baseCaloriesPer100g * ratio,
            food.baseProteinPer100g * ratio,
            food.baseCarbsPer100g * ratio,
            food.baseFatPer100g * ratio
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text(food.name)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Divider()
                
                // Input Section
                VStack(alignment: .leading, spacing: 15) {
                    
                    // SmartScale Toggle
                    if bluetoothManager.isConnected {
                        Toggle(isOn: $useScaleWeight) {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.blue)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading) {
                                    Text("Use SmartScale")
                                        .font(.headline)
                                    if useScaleWeight {
                                        Text("Reading: \(String(format: "%.1f", bluetoothManager.currentWeight))g")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .accessibilityLabel("Use SmartScale")
                        .accessibilityHint("Toggles using the connected Bluetooth scale for weight measurement")
                        .padding(.bottom, 10)
                        .onChange(of: useScaleWeight) { newValue in
                            if newValue {
                                useCustomWeight = false
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "scalemass")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            Text("SmartScale Disconnected")
                                .foregroundColor(.secondary)
                            Spacer()
                            NavigationLink(destination: BluetoothPairingView()) {
                                Text("Connect")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .accessibilityLabel("Connect SmartScale")
                            .accessibilityHint("Opens the Bluetooth pairing screen to connect a scale")
                        }
                        .padding(.bottom, 10)
                    }
                    
                    Divider()
                    
                    if !useScaleWeight {
                        Text("Serving Size")
                            .font(.headline)
                        
                        if !food.servings.isEmpty {
                            Picker("Serving", selection: $selectedServingIndex) {
                                ForEach(food.servings.indices, id: \.self) { index in
                                    let s = food.servings[index]
                                    Text("\(s.label) (\(Int(s.weight))g)").tag(index)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedServingIndex) { _ in useCustomWeight = false }
                        }
                        
                        // Quantity Stepper
                        HStack {
                            Text("Quantity: \(quantity, specifier: "%.1f")")
                            Spacer()
                            Stepper("", value: $quantity, in: 0.5...10, step: 0.5)
                                .labelsHidden()
                        }
                        .padding(.vertical)
                        
                        // Custom Weight Toggle
                        Toggle("Enter Exact Grams", isOn: $useCustomWeight)
                        
                        if useCustomWeight {
                            HStack {
                                Text("Weight (g)")
                                Spacer()
                                TextField("100", text: $customWeight)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Live Nutrition Preview
                VStack(spacing: 15) {
                    Text("Nutritional Value")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        MacroView(label: "Calories", value: "\(Int(nutrition.cals))", color: .green)
                        MacroView(label: "Protein", value: String(format: "%.1fg", nutrition.prot), color: .blue)
                        MacroView(label: "Carbs", value: String(format: "%.1fg", nutrition.carbs), color: .orange)
                        MacroView(label: "Fats", value: String(format: "%.1fg", nutrition.fats), color: .red)
                    }
                }
                .padding()
                
                Spacer()
                
                // Add Button
                Button(action: logFood) {
                    Text("Add to Log")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                .accessibilityLabel("Add \(food.name) to log")
                .accessibilityHint("Logs this food item with the selected serving size to your daily nutrition")
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func logFood() {
        let info = NutritionInfo(
            calories: String(Int(food.baseCaloriesPer100g)),
            recipe: "Manual Entry from INDB Database",
            carbs: String(format: "%.1f", food.baseCarbsPer100g),
            protein: String(format: "%.1f", food.baseProteinPer100g),
            fats: String(format: "%.1f", food.baseFatPer100g),
            source: "INDB",
            micros: nil
        )
        
        NutritionManager.shared.logFood(dish: food.name, info: info, weight: currentWeight)
        AnalyticsService.logFoodLogged(dish: food.name, calories: Int(nutrition.cals))

        // Post notification to close parent
        NotificationCenter.default.post(name: NSNotification.Name("CloseManualLog"), object: nil)
    }
}

struct MacroView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
