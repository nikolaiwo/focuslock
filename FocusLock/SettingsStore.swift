import Foundation
import SwiftUI

final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults

    // Apps that cannot be blocked
    static let protectedBundleIds = ["com.focuslock.app"]

    @Published var protectionEnabled: Bool {
        didSet { defaults.set(protectionEnabled, forKey: "protectionEnabled") }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    @Published var blockedApps: [BlockedApp] {
        didSet { saveBlockedApps() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load settings with defaults
        self.protectionEnabled = defaults.object(forKey: "protectionEnabled") as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true

        // Load blocked apps or use defaults
        if let data = defaults.data(forKey: "blockedApps"),
           let apps = try? JSONDecoder().decode([BlockedApp].self, from: data) {
            self.blockedApps = apps
        } else {
            self.blockedApps = [
                BlockedApp(bundleIdentifier: "com.apple.SecurityAgent", displayName: "SecurityAgent")
            ]
        }
    }

    private func saveBlockedApps() {
        if let data = try? JSONEncoder().encode(blockedApps) {
            defaults.set(data, forKey: "blockedApps")
        }
    }

    func canBlockApp(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return !Self.protectedBundleIds.contains(bundleIdentifier)
    }

    func addBlockedApp(bundleIdentifier: String, displayName: String) {
        guard !isAppBlocked(bundleIdentifier: bundleIdentifier) else { return }
        guard canBlockApp(bundleIdentifier: bundleIdentifier) else { return }
        blockedApps.append(BlockedApp(bundleIdentifier: bundleIdentifier, displayName: displayName))
    }

    func removeBlockedApp(_ app: BlockedApp) {
        blockedApps.removeAll { $0.id == app.id }
    }

    func isAppBlocked(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return blockedApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }
}
