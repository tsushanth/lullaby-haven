//
//  NotificationManager.swift
//  LullabyHaven
//
//  User notifications for sleep timer completion
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let timerNotificationID = "com.appfactory.lullabyhaven.timer"

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("[NotificationManager] Permission error: \(error)")
            return false
        }
    }

    func scheduleSleepTimerNotification(at date: Date) {
        cancelTimerNotification()

        let content = UNMutableNotificationContent()
        content.title = "Sweet Dreams 🌙"
        content.body = "Lullaby Haven sleep timer has ended. Your baby is sleeping soundly."
        content.sound = .default

        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: timerNotificationID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[NotificationManager] Schedule error: \(error)") }
        }
    }

    func cancelTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [timerNotificationID]
        )
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
