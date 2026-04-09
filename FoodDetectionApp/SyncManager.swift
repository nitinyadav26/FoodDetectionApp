import Foundation
import Combine
import UIKit

/// Syncs local food logs with the server via NetworkService.
/// Uses `/api/sync/push` to upload unsynced logs and `/api/sync/pull` to fetch remote changes.
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private var cancellables = Set<AnyCancellable>()
    private let isoFormatter = ISO8601DateFormatter()

    private init() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSyncTimestamp") as? Double {
            lastSyncDate = Date(timeIntervalSince1970: timestamp)
        }

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.syncIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public

    func syncIfNeeded() {
        guard AuthManager.shared.isSignedIn,
              NetworkMonitor.shared.isConnected,
              !isSyncing else {
            return
        }

        Task { @MainActor in
            isSyncing = true
            defer { isSyncing = false }

            do {
                try await pushLocalLogs()
                try await pullRemoteLogs()

                let now = Date()
                lastSyncDate = now
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "lastSyncTimestamp")
            } catch {
                print("[SyncManager] sync failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Push

    private func pushLocalLogs() async throws {
        let allLogs = NutritionManager.shared.logs
        let logsToSync = lastSyncDate.map { since in
            allLogs.filter { $0.time > since }
        } ?? allLogs
        guard !logsToSync.isEmpty else { return }

        let formatter = isoFormatter
        let payload = SyncPushRequest(logs: logsToSync.map { log in
            SyncFoodLogDTO(
                clientId: log.id.uuidString,
                dishName: log.food,
                calories: log.calories,
                proteinG: log.protein,
                carbsG: log.carbs,
                fatsG: log.fats,
                micronutrients: log.micros,
                healthierRecipe: log.recipe,
                loggedAt: formatter.string(from: log.time)
            )
        })

        let _: SyncPushResponse = try await NetworkService.shared.post("/api/sync/push", body: payload)
    }

    // MARK: - Pull

    private func pullRemoteLogs() async throws {
        var queryItems: [URLQueryItem]? = nil
        if let last = lastSyncDate {
            queryItems = [URLQueryItem(name: "since", value: isoFormatter.string(from: last))]
        }

        let response: SyncPullResponse = try await NetworkService.shared.get("/api/sync/pull", queryItems: queryItems)

        guard !response.data.isEmpty else { return }

        let formatter = isoFormatter
        let existingIds = Set(NutritionManager.shared.logs.map { $0.id.uuidString })
        let newLogs = response.data.compactMap { remote -> NutritionManager.FoodLog? in
            guard !existingIds.contains(remote.id) else { return nil }
            return NutritionManager.FoodLog(
                id: UUID(uuidString: remote.id) ?? UUID(),
                food: remote.dishName,
                calories: Int(remote.calories ?? 0),
                protein: Int(remote.proteinG ?? 0),
                carbs: Int(remote.carbsG ?? 0),
                fats: Int(remote.fatsG ?? 0),
                micros: remote.micronutrients,
                recipe: remote.healthierRecipe,
                time: formatter.date(from: remote.loggedAt) ?? Date()
            )
        }

        if !newLogs.isEmpty {
            await MainActor.run {
                NutritionManager.shared.logs.append(contentsOf: newLogs)
                NutritionManager.shared.saveLogs()
            }
        }
    }
}

// MARK: - DTOs

private struct SyncPushRequest: Encodable {
    let logs: [SyncFoodLogDTO]
}

private struct SyncFoodLogDTO: Encodable {
    let clientId: String
    let dishName: String
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatsG: Int
    let micronutrients: [String: String]?
    let healthierRecipe: String?
    let loggedAt: String
}

private struct SyncPushResponse: Decodable {
    let success: Bool
    let data: SyncPushData
}

private struct SyncPushData: Decodable {
    let upserted: Int
}

private struct SyncPullResponse: Decodable {
    let success: Bool
    let data: [RemoteFoodLog]
}

private struct RemoteFoodLog: Decodable {
    let id: String
    let dishName: String
    let calories: Double?
    let proteinG: Double?
    let carbsG: Double?
    let fatsG: Double?
    let micronutrients: [String: String]?
    let healthierRecipe: String?
    let loggedAt: String
}
