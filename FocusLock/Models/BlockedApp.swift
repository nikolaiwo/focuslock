import Foundation

struct BlockedApp: Codable, Identifiable, Equatable {
    let id: UUID
    let bundleIdentifier: String
    let displayName: String

    init(id: UUID = UUID(), bundleIdentifier: String, displayName: String) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}
