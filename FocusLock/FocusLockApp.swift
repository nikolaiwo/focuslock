import SwiftUI

@main
struct FocusLockApp: App {
    var body: some Scene {
        MenuBarExtra("FocusLock", systemImage: "lock.fill") {
            Text("FocusLock is running")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
