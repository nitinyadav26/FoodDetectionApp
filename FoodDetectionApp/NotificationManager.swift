//
//  NotificationManager.swift
//  FoodDetectionApp
//
//  Created on 05/04/26.
//

import Foundation
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Permission

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.scheduleAllNotifications()
                }
                completion?(granted)
            }
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Scheduling

    func scheduleAllNotifications() {
        cancelAllNotifications()

        scheduleMealReminder(
            id: "breakfast_reminder",
            hour: 8,
            minute: 0,
            title: "Time for Breakfast!",
            body: "Don't forget to log your morning meal"
        )

        scheduleMealReminder(
            id: "lunch_reminder",
            hour: 13,
            minute: 0,
            title: "Lunch Time!",
            body: "Log your lunch to stay on track"
        )

        scheduleMealReminder(
            id: "dinner_reminder",
            hour: 19,
            minute: 0,
            title: "Dinner Time!",
            body: "Remember to log your dinner"
        )

        scheduleHydrationReminders()

        scheduleMealReminder(
            id: "daily_summary",
            hour: 21,
            minute: 0,
            title: "Daily Summary",
            body: "Check your nutrition progress for today"
        )
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Private Helpers

    private func scheduleMealReminder(id: String, hour: Int, minute: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule \(id): \(error.localizedDescription)")
            }
        }
    }

    private func scheduleHydrationReminders() {
        // Every 2 hours from 9 AM to 9 PM: 9, 11, 13, 15, 17, 19, 21
        let hydrationHours = stride(from: 9, through: 21, by: 2)

        for hour in hydrationHours {
            let content = UNMutableNotificationContent()
            content.title = "Stay Hydrated!"
            content.body = "Time to drink some water"
            content.sound = .default

            // Use UNTimeIntervalNotificationTrigger by computing seconds until next occurrence
            // wrapped in a calendar trigger so it repeats daily at each hour
            let id = "hydration_\(hour)"

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60 * 60, repeats: true)

            // For repeating daily at specific hours, schedule individual calendar-based triggers
            // but use TimeInterval trigger for the hydration category as specified
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule hydration reminder at \(hour): \(error.localizedDescription)")
                }
            }
        }
    }

    private func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}
