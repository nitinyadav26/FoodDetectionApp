import SwiftUI
import UIKit

struct ResultView: View {
    let image: UIImage?
    let dishName: String
    let nutrition: NutritionInfo
    var onLog: () -> Void
    var onCancel: () -> Void
    
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    @State private var manualWeight: String = "100"
    @State private var isEditingWeight = false
    @State private var useScaleWeight = false
    
    var currentWeight: Double {
        if useScaleWeight && bluetoothManager.isConnected {
            return bluetoothManager.currentWeight
        }
        return Double(manualWeight) ?? 100.0
    }
    
    var displayedNutrition: NutritionInfo {
        NutritionManager.shared.calculateNutrition(for: nutrition, weight: currentWeight)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Header
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .cornerRadius(20)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 250)
                        .cornerRadius(20)
                        .overlay(Text(dishName).font(.largeTitle))
                }
                
                // Title
                Text(dishName)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                
                // Weight Input Section
                VStack(spacing: 15) {
                    if bluetoothManager.isConnected {
                        Toggle(isOn: $useScaleWeight) {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.blue)
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
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                    }
                    
                    if !useScaleWeight {
                        HStack {
                            if !bluetoothManager.isConnected {
                                Image(systemName: "scalemass")
                                    .foregroundColor(.gray)
                                Text("Scale Disconnected")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            TextField("Weight", text: $manualWeight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.title2)
                                .frame(width: 80)
                                .padding(5)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("g")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Macros
                HStack(spacing: 20) {
                    MacroRing(label: "Calories", value: displayedNutrition.calories, color: .green)
                    MacroRing(label: "Protein", value: displayedNutrition.protein, color: .blue)
                    MacroRing(label: "Carbs", value: displayedNutrition.carbs, color: .orange)
                    MacroRing(label: "Fats", value: displayedNutrition.fats, color: .red)
                }
                .padding()
                
                // Micros (if available)
                if let micros = displayedNutrition.micros, !micros.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Micronutrients")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(micros.sorted(by: >), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(value)
                                        .font(.subheadline)
                                        .bold()
                                }
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Advice
                VStack(alignment: .leading, spacing: 10) {
                    Text("Healthier Advice")
                        .font(.headline)
                    
                    Text(nutrition.recipe)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Actions
                HStack(spacing: 15) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                                .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        // Log with current weight
                        NutritionManager.shared.logFood(dish: dishName, info: nutrition, weight: currentWeight)
                        onLog()
                    }) {
                        Text("Log Food")
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            bluetoothManager.startScanning()
        }
    }
}

struct MacroRing: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: 0.7) // Static trim for visual
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(parse(value))
                    .font(.caption)
                    .bold()
            }
            .frame(width: 50, height: 50)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    func parse(_ val: String) -> String {
        let allowed = CharacterSet(charactersIn: "0123456789.")
        let filtered = val.components(separatedBy: allowed.inverted).joined()
        return filtered.isEmpty ? "0" : filtered
    }
}
