import XCTest
@testable import FocusLock

final class FocusMonitorTests: XCTestCase {
    var monitor: FocusMonitor!
    var settings: SettingsStore!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "com.focuslock.tests.monitor")!
        defaults.removePersistentDomain(forName: "com.focuslock.tests.monitor")
        settings = SettingsStore(defaults: defaults)
        monitor = FocusMonitor(settings: settings)
    }

    override func tearDown() {
        monitor.stopMonitoring()
        super.tearDown()
    }

    func testInitialLogIsEmpty() {
        XCTAssertTrue(monitor.log.isEmpty)
    }

    func testLogLimitedTo100Entries() {
        // Simulate adding 110 events
        for i in 0..<110 {
            monitor.addLogEntry(
                appName: "App\(i)",
                bundleIdentifier: "com.test.app\(i)",
                previousAppName: nil,
                wasBlocked: false
            )
        }
        XCTAssertEqual(monitor.log.count, 100)
        // Most recent should be last added
        XCTAssertEqual(monitor.log.first?.appName, "App109")
    }

    func testClearLog() {
        monitor.addLogEntry(appName: "Test", bundleIdentifier: "com.test", previousAppName: nil, wasBlocked: false)
        XCTAssertFalse(monitor.log.isEmpty)
        monitor.clearLog()
        XCTAssertTrue(monitor.log.isEmpty)
    }

    func testShouldBlockApp() {
        XCTAssertTrue(monitor.shouldBlockApp(bundleIdentifier: "com.apple.SecurityAgent"))
        XCTAssertFalse(monitor.shouldBlockApp(bundleIdentifier: "com.apple.finder"))
    }

    func testShouldNotBlockWhenProtectionDisabled() {
        settings.protectionEnabled = false
        XCTAssertFalse(monitor.shouldBlockApp(bundleIdentifier: "com.apple.SecurityAgent"))
    }
}
