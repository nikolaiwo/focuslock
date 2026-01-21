import SwiftUI

struct LogWindowView: View {
    @ObservedObject var monitor: FocusMonitor
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Focus Log")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    monitor.clearLog()
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            // Log entries
            if monitor.log.isEmpty {
                Spacer()
                Text("No focus changes recorded yet")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List(monitor.log) { event in
                    LogEntryRow(event: event, settings: settings)
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct LogEntryRow: View {
    let event: FocusEvent
    @ObservedObject var settings: SettingsStore

    private var isAlreadyBlocked: Bool {
        guard let bundleId = event.bundleIdentifier else { return false }
        return settings.isAppBlocked(bundleIdentifier: bundleId)
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.formattedTime)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(event.appName)
                        .fontWeight(.medium)

                    if event.wasBlocked {
                        Text("blocked")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }

                if let previous = event.previousAppName {
                    Text("← \(previous)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Add to blocklist button (hidden for already blocked or protected apps)
            if let bundleId = event.bundleIdentifier,
               !isAlreadyBlocked,
               settings.canBlockApp(bundleIdentifier: bundleId) {
                Button {
                    settings.addBlockedApp(bundleIdentifier: bundleId, displayName: event.appName)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
                .help("Add to blocklist")
            }
        }
        .padding(.vertical, 4)
    }
}
