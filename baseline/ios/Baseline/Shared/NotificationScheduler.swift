import Foundation
import UserNotifications

final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let morningIdentifier = "baseline.morning.notification"
    private let eveningIdentifier = "baseline.evening.checkin"

    private init() {}

    func scheduleMorningNotification(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Baseline"
        // Placeholder until generate-morning-notification (RES-60) is wired.
        content.body = "Your anchor is waiting."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: morningIdentifier,
            content: content,
            trigger: trigger,
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleEveningCheckin(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Baseline"
        content.body = "Time for your daily check-in."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: eveningIdentifier,
            content: content,
            trigger: trigger,
        )

        UNUserNotificationCenter.current().add(request)
    }

    func rescheduleAll(morningTime: Date, eveningTime: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [morningIdentifier, eveningIdentifier],
        )
        scheduleMorningNotification(at: morningTime)
        scheduleEveningCheckin(at: eveningTime)
    }
}
