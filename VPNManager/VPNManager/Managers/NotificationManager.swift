import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func scheduleNotifications(for customer: Customer) {
        cancelNotifications(for: customer)

        let paymentDate = customer.paymentDate
        let name = customer.name
        let amount = customer.formattedAmount
        let users = "\(customer.userCount) users"

        scheduleDayNotification(customerId: customer.id.uuidString, date: paymentDate, name: name, amount: amount, users: users)

        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: paymentDate) {
            scheduleReminderNotification(customerId: customer.id.uuidString, date: dayBefore, name: name, amount: amount, users: users)
        }
    }

    private func scheduleDayNotification(customerId: String, date: Date, name: String, amount: String, users: String) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Payment Due Today"
        content.body = "Payment due: \(name) — \(amount) — \(users)"
        content.sound = .default
        content.badge = 1

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "vpn_due_\(customerId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleReminderNotification(customerId: String, date: Date, name: String, amount: String, users: String) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Payment Due Tomorrow"
        content.body = "Reminder: \(name) — \(amount) — \(users) is due tomorrow"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "vpn_reminder_\(customerId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotifications(for customer: Customer) {
        let ids = ["vpn_due_\(customer.id.uuidString)", "vpn_reminder_\(customer.id.uuidString)"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func scheduleAllNotifications(customers: [Customer]) {
        for customer in customers {
            scheduleNotifications(for: customer)
        }
    }
}
