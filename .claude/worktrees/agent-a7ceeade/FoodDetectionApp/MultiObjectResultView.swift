import SwiftUI
import UIKit

struct MultiObjectResultView: View {
    let image: UIImage?
    let results: [InferenceResult]
    var onLog: ([String]) -> Void
    var onCancel: () -> Void
    
    @State private var selectedItems: Set<String> = []
    @State private var quantities: [String: String] = [:] // Map label to weight string
    
    // Bluetooth Scale Integration
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    @State private var activeWeighingLabel: String? = nil
    
    // Nutrition Manager to get calorie info for preview
    private let nutritionManager = NutritionManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                // Header Image
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .padding()
                }
                
                Text("Detected Items")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 5)
                
                Text("Select items to log")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                List {
                    ForEach(results, id: \.label) { result in
                        HStack {
                            // Checkbox
                            Button(action: {
                                toggleSelection(result.label)
                            }) {
                                Image(systemName: selectedItems.contains(result.label) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedItems.contains(result.label) ? .green : .gray)
                                    .font(.title2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading) {
                                Text(result.label)
                                    .font(.headline)
                                
                                if let info = nutritionManager.getNutrition(for: result.label) {
                                    Text("\(info.calories) kcal / 100g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("No nutrition info")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            // Weight Input & Scale Integration
                            if selectedItems.contains(result.label) {
                                if activeWeighingLabel == result.label {
                                    // Weighing Mode
                                    HStack {
                                        Text("\(Int(bluetoothManager.currentWeight))")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                            .frame(width: 50)
                                        
                                        Button(action: {
                                            // Lock the weight
                                            quantities[result.label] = String(Int(bluetoothManager.currentWeight))
                                            activeWeighingLabel = nil
                                        }) {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                } else {
                                    // Manual/Static Mode
                                    HStack {
                                        TextField("100", text: binding(for: result.label))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 50)
                                            .padding(4)
                                            .background(Color(UIColor.secondarySystemBackground))
                                            .cornerRadius(4)
                                        
                                        Text("g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if bluetoothManager.isConnected {
                                            Button(action: {
                                                activeWeighingLabel = result.label
                                            }) {
                                                Image(systemName: "scalemass")
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                    
                    Button(action: {
                        var logList: [String] = []
                        for label in selectedItems {
                            logList.append(label)
                            // Also log individually to manager logic
                            if let info = nutritionManager.getNutrition(for: label) {
                                let weight = Double(quantities[label] ?? "100") ?? 100.0
                                nutritionManager.logFood(dish: label, info: info, weight: weight)
                                AnalyticsService.logFoodLogged(dish: label, calories: Int(info.calories) ?? 0)
                            }
                        }
                        onLog(Array(selectedItems))
                    }) {
                        Text("Log Selected (\(selectedItems.count))")
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedItems.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(selectedItems.isEmpty)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            bluetoothManager.startScanning()
            // Auto-select highly confident items? Or select all by default
            for res in results {
                selectedItems.insert(res.label)
                quantities[res.label] = "100"
            }
        }
        
        // Listen to scale if weighing
        .onReceive(bluetoothManager.$currentWeight) { newWeight in
            if let label = activeWeighingLabel {
                quantities[label] = String(Int(newWeight))
            }
        }
    }
    
    private func toggleSelection(_ label: String) {
        if selectedItems.contains(label) {
            selectedItems.remove(label)
            if activeWeighingLabel == label {
                activeWeighingLabel = nil
            }
        } else {
            selectedItems.insert(label)
        }
    }
    
    private func binding(for label: String) -> Binding<String> {
        return Binding(
            get: { self.quantities[label] ?? "100" },
            set: { self.quantities[label] = $0 }
        )
    }
}
