import Foundation
import HealthKit
import Combine

struct HealthDailyData {
    var steps: Int
    var water: Double
    var burn: Int
    var sleep: Double // Hours
}

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    // Live Data (Today)
    @Published var stepCount: Int = 0
    @Published var waterIntake: Double = 0.0 // Liters
    @Published var sleepHours: String = "--"
    @Published var activeCalories: Int = 0
    
    // History Cache
    @Published var history: [Date: HealthDailyData] = [:]
    
    @Published var isAuthorized = false
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available")
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ]
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchAllData()
                }
            }
        }
    }
    
    func fetchAllData() {
        fetchSteps()
        fetchWater()
        fetchSleep()
        fetchActiveCalories()
        
        // Fetch last 30 days history in background for Dashboard
        Task {
            await fetchHistory(days: 30)
        }
    }
    
    // ... [fetchSteps, fetchWater, fetchActiveCalories, fetchSleep identical to before] ...
    
    private func fetchSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.stepCount = steps
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchWater() {
        let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            // Convert to Liters (L)
            let liters = sum.doubleValue(for: HKUnit.liter())
            DispatchQueue.main.async {
                self.waterIntake = liters
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchActiveCalories() {
        let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            let cals = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
            DispatchQueue.main.async {
                self.activeCalories = cals
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchSleep() {
        let tryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        // Sleep query look for "InBed" samples in last 24h
        let end = Date()
        let start = end.addingTimeInterval(-24 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        
        let query = HKSampleQuery(sampleType: tryType, predicate: predicate, limit: 0, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            var totalTime: TimeInterval = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                    totalTime += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            let hours = totalTime / 3600
            DispatchQueue.main.async {
                self.sleepHours = String(format: "%.1fh", hours)
            }
        }
        healthStore.execute(query)
    }
    
    func logWater(amountML: Double) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        let quantity = HKQuantity(unit: .liter(), doubleValue: amountML / 1000.0)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: Date(), end: Date())
        
        healthStore.save(sample) { success, _ in
            if success {
                self.fetchWater()
                // Also update history eventually
                Task { await self.fetchHistory(days: 0) }
            }
        }
    }
    
    // MARK: - History
    func getData(for date: Date) -> HealthDailyData {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            // Live Data
            let sleepVal = Double(sleepHours.replacingOccurrences(of: "h", with: "")) ?? 0.0
            return HealthDailyData(steps: stepCount, water: waterIntake, burn: activeCalories, sleep: sleepVal)
        }
        
        // Historical Data
        let startOfDay = calendar.startOfDay(for: date)
        if let data = history[startOfDay] {
            return data
        }
        
        return HealthDailyData(steps: 0, water: 0, burn: 0, sleep: 0)
    }
    
    @discardableResult
    func fetchHistory(days: Int) async -> [Date: (steps: Int, water: Double, burn: Int, sleep: Double)] {
        let calendar = Calendar.current
        let now = Date()
        let endDate = now
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return [:] }
        
        let anchor = calendar.startOfDay(for: now)
        let interval = DateComponents(day: 1)
        
        // Helper to execute collection query
        func query(type: HKQuantityType, unit: HKUnit, options: HKStatisticsOptions) async -> [Date: Double] {
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil, options: options, anchorDate: anchor, intervalComponents: interval)
                
                query.initialResultsHandler = { _, results, _ in
                    var data: [Date: Double] = [:]
                    if let results = results {
                        results.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                            if let sum = stats.sumQuantity() {
                                data[stats.startDate] = sum.doubleValue(for: unit)
                            }
                        }
                    }
                    continuation.resume(returning: data)
                }
                healthStore.execute(query)
            }
        }
        
        // Parallel fetch
        async let stepsData = query(type: HKQuantityType.quantityType(forIdentifier: .stepCount)!, unit: .count(), options: .cumulativeSum)
        async let waterData = query(type: HKQuantityType.quantityType(forIdentifier: .dietaryWater)!, unit: .liter(), options: .cumulativeSum)
        async let burnData = query(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!, unit: .kilocalorie(), options: .cumulativeSum)
        
        // Sleep uses SampleQuery so we group manually
        var sleepData: [Date: Double] = [:]
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sleepPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: sleepPredicate, limit: 0, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume()
                    return
                }
                
                var dailySleep: [Date: Double] = [:]
                for sample in samples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        let dateKey = calendar.startOfDay(for: sample.endDate)
                        dailySleep[dateKey, default: 0] += duration
                    }
                }
                for (date, seconds) in dailySleep {
                    sleepData[date] = seconds / 3600.0
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
        
        let steps = await stepsData
        let water = await waterData
        let burn = await burnData
        
        // Merge & Publish
        var newHistory: [Date: HealthDailyData] = [:]
        var result: [Date: (steps: Int, water: Double, burn: Int, sleep: Double)] = [:]
        
        let allDates = Set(steps.keys).union(water.keys).union(burn.keys).union(sleepData.keys)
        
        for date in allDates {
            let s = Int(steps[date] ?? 0)
            let w = water[date] ?? 0
            let b = Int(burn[date] ?? 0)
            let sl = sleepData[date] ?? 0
            
            newHistory[date] = HealthDailyData(steps: s, water: w, burn: b, sleep: sl)
            result[date] = (s, w, b, sl)
        }
        
        DispatchQueue.main.async {
            self.history = newHistory
        }
        
        return result
    }
}
