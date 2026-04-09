import Foundation
import CoreData

/// CoreData stack built programmatically (no .xcdatamodeld file required).
/// Manages two entities: CDFoodLog and CDUserStats, mirroring the existing
/// UserDefaults-backed models in NutritionManager.
final class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // MARK: - Initialisation

    private init() {
        let model = PersistenceController.buildManagedObjectModel()
        container = NSPersistentContainer(name: "FoodSense", managedObjectModel: model)
        container.loadPersistentStores { description, error in
            if let error = error {
                print("CoreData failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        migrateFromUserDefaultsIfNeeded()
    }

    // MARK: - Programmatic Model

    private static func buildManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // --- CDFoodLog entity ---
        let foodLogEntity = NSEntityDescription()
        foodLogEntity.name = "CDFoodLog"
        foodLogEntity.managedObjectClassName = "CDFoodLog"

        foodLogEntity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("food", .stringAttributeType, optional: false),
            attribute("calories", .integer32AttributeType, optional: false),
            attribute("protein", .integer32AttributeType, optional: false),
            attribute("carbs", .integer32AttributeType, optional: false),
            attribute("fats", .integer32AttributeType, optional: false),
            attribute("micros", .transformableAttributeType, optional: true),  // [String:String] via NSSecureCoding
            attribute("recipe", .stringAttributeType, optional: true),
            attribute("time", .dateAttributeType, optional: false),
        ]

        // --- CDUserStats entity ---
        let userStatsEntity = NSEntityDescription()
        userStatsEntity.name = "CDUserStats"
        userStatsEntity.managedObjectClassName = "CDUserStats"

        userStatsEntity.properties = [
            attribute("id", .integer32AttributeType, optional: false),   // always 1
            attribute("weight", .doubleAttributeType, optional: false),
            attribute("height", .doubleAttributeType, optional: false),
            attribute("age", .integer32AttributeType, optional: false),
            attribute("gender", .stringAttributeType, optional: false),
            attribute("activityLevel", .stringAttributeType, optional: false),
            attribute("goal", .stringAttributeType, optional: false),
        ]

        model.entities = [foodLogEntity, userStatsEntity]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        return attr
    }

    // MARK: - Save

    func saveContext() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            print("CoreData save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Migration from UserDefaults

    private func migrateFromUserDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "coredata_migration_done") else { return }

        let ctx = container.viewContext

        // Migrate food logs
        if let data = defaults.data(forKey: "foodLogs"),
           let logs = try? JSONDecoder().decode([LegacyFoodLog].self, from: data) {
            for log in logs {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "CDFoodLog", into: ctx)
                obj.setValue(log.id, forKey: "id")
                obj.setValue(log.food, forKey: "food")
                obj.setValue(Int32(log.calories), forKey: "calories")
                obj.setValue(Int32(log.protein), forKey: "protein")
                obj.setValue(Int32(log.carbs), forKey: "carbs")
                obj.setValue(Int32(log.fats), forKey: "fats")
                obj.setValue(log.micros as NSDictionary?, forKey: "micros")
                obj.setValue(log.recipe, forKey: "recipe")
                obj.setValue(log.time, forKey: "time")
            }
        }

        // Migrate user stats
        if let data = defaults.data(forKey: "userStats"),
           let stats = try? JSONDecoder().decode(LegacyUserStats.self, from: data) {
            let obj = NSEntityDescription.insertNewObject(forEntityName: "CDUserStats", into: ctx)
            obj.setValue(Int32(1), forKey: "id")
            obj.setValue(stats.weight, forKey: "weight")
            obj.setValue(stats.height, forKey: "height")
            obj.setValue(Int32(stats.age), forKey: "age")
            obj.setValue(stats.gender, forKey: "gender")
            obj.setValue(stats.activityLevel, forKey: "activityLevel")
            obj.setValue(stats.goal, forKey: "goal")
        }

        saveContext()
        defaults.set(true, forKey: "coredata_migration_done")
        print("PersistenceController: UserDefaults -> CoreData migration complete")
    }
}

// MARK: - Legacy Codable types used only during migration decoding

private struct LegacyFoodLog: Codable {
    let id: UUID
    let food: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
    let micros: [String: String]?
    let recipe: String?
    let time: Date
}

private struct LegacyUserStats: Codable {
    let weight: Double
    let height: Double
    let age: Int
    let gender: String
    let activityLevel: String
    let goal: String
}
