import AppKit
import Combine

final class FocusMonitor: ObservableObject {
    @Published var log: [FocusEvent] = []

    private let settings: SettingsStore
    private var previousApp: NSRunningApplication?
    private var currentApp: NSRunningApplication?
    private var observer: NSObjectProtocol?
    private let maxLogEntries = 100

    // Callback for when focus is restored (for notifications)
    var onFocusRestored: ((String, String) -> Void)?

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func startMonitoring() {
        // Initialize current app
        currentApp = NSWorkspace.shared.frontmostApplication

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleFocusChange(notification)
        }
    }

    func stopMonitoring() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
    }

    private func handleFocusChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        let appName = app.localizedName ?? "Unknown"
        let bundleId = app.bundleIdentifier
        let previousAppName = currentApp?.localizedName

        // Don't log if same app (e.g., window switch within app)
        guard app.processIdentifier != currentApp?.processIdentifier else { return }

        // Check if should block before updating tracking
        let shouldBlock = shouldBlockApp(bundleIdentifier: bundleId)

        // Log the event
        addLogEntry(
            appName: appName,
            bundleIdentifier: bundleId,
            previousAppName: previousAppName,
            wasBlocked: shouldBlock
        )

        if shouldBlock, let prevApp = currentApp {
            // Restore focus to previous app
            print("BLOCKING: \(appName) (\(bundleId ?? "nil")), restoring to \(prevApp.localizedName ?? "Unknown")")
            restoreFocus(to: prevApp, blockedAppName: appName)
        } else {
            // Update tracking
            print("Focus changed to: \(appName) (\(bundleId ?? "nil"))")
            previousApp = currentApp
            currentApp = app
        }
    }

    private func restoreFocus(to app: NSRunningApplication, blockedAppName: String) {
        let restoredAppName = app.localizedName ?? "Unknown"

        // Activate the previous app to restore focus
        app.activate()

        print("Calling onFocusRestored callback...")
        onFocusRestored?(blockedAppName, restoredAppName)
    }

    func shouldBlockApp(bundleIdentifier: String?) -> Bool {
        guard settings.protectionEnabled else { return false }
        return settings.isAppBlocked(bundleIdentifier: bundleIdentifier)
    }

    func addLogEntry(appName: String, bundleIdentifier: String?, previousAppName: String?, wasBlocked: Bool) {
        let event = FocusEvent(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            previousAppName: previousAppName,
            wasBlocked: wasBlocked
        )

        log.insert(event, at: 0)

        // Trim to max entries
        if log.count > maxLogEntries {
            log = Array(log.prefix(maxLogEntries))
        }
    }

    func clearLog() {
        log.removeAll()
    }
}
