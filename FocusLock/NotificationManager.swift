import UserNotifications

final class NotificationManager: ObservableObject {
    @Published var permissionGranted = false

    init() {
        checkPermission()
    }

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
            }
        }
    }

    func sendNotification(blockedApp: String, restoredApp: String) {
        print("sendNotification called: \(blockedApp) -> \(restoredApp)")

        let content = UNMutableNotificationContent()
        content.title = "Blocked \(blockedApp)"
        content.body = "Restored focus to \(restoredApp)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            } else {
                print("Notification queued successfully")
            }
        }
    }
}
