import SwiftUI

struct ManualLogView: View {
    @ObservedObject var foodDB = FoodDatabase.shared
    @State private var searchText = ""
    @State private var remoteResults: [INDBFood] = []
    @State private var isSearchingRemote = false
    @Environment(\.presentationMode) var presentationMode
    
    func performRemoteSearch() {
        guard !searchText.isEmpty else { return }
        isSearchingRemote = true
        remoteResults = []
        
        Task {
            do {
                let (name, info) = try await APIService.shared.searchFood(query: searchText)
                
                // Convert to INDBFood model
                // Parse strings "100" to Double, handling potential errors
                let cals = Double(info.calories) ?? 0
                let prot = Double(info.protein) ?? 0
                let carbs = Double(info.carbs) ?? 0
                let fats = Double(info.fats) ?? 0
                
                let remoteFood = INDBFood(
                    id: UUID().uuidString,
                    name: name,
                    baseCaloriesPer100g: cals,
                    baseProteinPer100g: prot,
                    baseCarbsPer100g: carbs,
                    baseFatPer100g: fats,
                    servings: [
                        ServingSize(label: "Standard Serving", weight: 100),
                        ServingSize(label: "Small Portion", weight: 50),
                        ServingSize(label: "Large Portion", weight: 200)
                    ]
                )
                
                await MainActor.run {
                    self.remoteResults = [remoteFood] // For now, just one result from Gemini
                    self.isSearchingRemote = false
                    AnalyticsService.logManualSearch(query: searchText)
                }
            } catch {
                print("Remote search error: \(error)")
                await MainActor.run {
                    self.isSearchingRemote = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    TextField("Search for food (e.g. 'Dal Fry')", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .accessibilityLabel("Search for food")
                        .accessibilityHint("Type a food name to search the database")
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Clear search")
                        .accessibilityHint("Clears the current search text")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
                
                if foodDB.foods.isEmpty {
                    // Loading State
                    if !foodDB.isLoaded {
                        Spacer()
                        ProgressView("Loading Database...")
                        Spacer()
                    }
                }
                
                List {
                    let results = foodDB.search(query: searchText)
                    
                    if searchText.isEmpty {
                        Text("Type to search for Indian dishes...")
                            .foregroundColor(.secondary)
                    } else if results.isEmpty {
                        // Section for Remote Search / Fallback
                        Section {
                            if isSearchingRemote {
                                HStack {
                                    ProgressView()
                                    Text("Searching online...")
                                        .foregroundColor(.secondary)
                                }
                            } else if !remoteResults.isEmpty {
                                ForEach(remoteResults) { food in
                                    NavigationLink(destination: FoodDetailView(food: food)) {
                                        VStack(alignment: .leading) {
                                            Text(food.name)
                                                .font(.headline)
                                            Text("Adjusted by AI • \(Int(food.baseCaloriesPer100g)) kcal/100g")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .accessibilityLabel("\(food.name), \(Int(food.baseCaloriesPer100g)) kilocalories per 100 grams, AI result")
                                    .accessibilityHint("Double-tap to view details and add to log")
                                }
                            } else {
                                Button(action: {
                                    performRemoteSearch()
                                }) {
                                    HStack {
                                        Image(systemName: "globe")
                                            .accessibilityHidden(true)
                                        Text("Search online for '\(searchText)'")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .accessibilityLabel("Search online for \(searchText)")
                                .accessibilityHint("Searches the internet for nutrition information")
                            }
                        }
                    } else {
                        // Local Results
                        ForEach(results) { food in
                            NavigationLink(destination: FoodDetailView(food: food)) {
                                VStack(alignment: .leading) {
                                    Text(food.name)
                                        .font(.headline)
                                    Text("\(Int(food.baseCaloriesPer100g)) kcal / 100g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .accessibilityLabel("\(food.name), \(Int(food.baseCaloriesPer100g)) kilocalories per 100 grams")
                            .accessibilityHint("Double-tap to view details and add to log")
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Log Food")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .accessibilityLabel("Close")
            .accessibilityHint("Dismisses the food logging screen")
            )
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloseManualLog"))) { _ in
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
