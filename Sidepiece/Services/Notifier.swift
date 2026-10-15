import UserNotifications

/// Posts local notifications, showing banners even while the popover has focus.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()
    private let centre = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        centre.delegate = self
    }

    func post(_ title: String, body: String) async {
        guard (try? await centre.requestAuthorization(options: [.alert])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        try? await centre.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        .banner
    }
}
