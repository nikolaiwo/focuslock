import XCTest
@testable import FocusLock

final class SettingsStoreTests: XCTestCase {
    var store: SettingsStore!

    override func setUp() {
        super.setUp()
        // Use a unique suite to avoid polluting real UserDefaults
        let defaults = UserDefaults(suiteName: "com.focuslock.tests")!
        defaults.removePersistentDomain(forName: "com.focuslock.tests")
        store = SettingsStore(defaults: defaults)
    }

    func testDefaultProtectionEnabled() {
        XCTAssertTrue(store.protectionEnabled)
    }

    func testDefaultNotificationsEnabled() {
        XCTAssertTrue(store.notificationsEnabled)
    }

    func testDefaultBlockedAppsContainsSecurityAgent() {
        XCTAssertTrue(store.blockedApps.contains { $0.bundleIdentifier == "com.apple.SecurityAgent" })
    }

    func testAddBlockedApp() {
        let initialCount = store.blockedApps.count
        store.addBlockedApp(bundleIdentifier: "com.example.test", displayName: "Test App")
        XCTAssertEqual(store.blockedApps.count, initialCount + 1)
        XCTAssertTrue(store.blockedApps.contains { $0.bundleIdentifier == "com.example.test" })
    }

    func testRemoveBlockedApp() {
        store.addBlockedApp(bundleIdentifier: "com.example.toremove", displayName: "Remove Me")
        let app = store.blockedApps.first { $0.bundleIdentifier == "com.example.toremove" }!
        store.removeBlockedApp(app)
        XCTAssertFalse(store.blockedApps.contains { $0.bundleIdentifier == "com.example.toremove" })
    }

    func testIsAppBlocked() {
        XCTAssertTrue(store.isAppBlocked(bundleIdentifier: "com.apple.SecurityAgent"))
        XCTAssertFalse(store.isAppBlocked(bundleIdentifier: "com.apple.finder"))
    }
}
