import Foundation

enum PrimitiveWorseQueryRuntime {
    static let appGroupIdentifier = "group.com.mac.core.primitive"

    static var appGroupContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
    }

    static var appGroupStatus: String {
        guard let containerURL = appGroupContainerURL else {
            return "App Group unavailable — signing entitlement not effective"
        }

        return "App Group available — \(containerURL.lastPathComponent)"
    }

    static var isAppGroupAvailable: Bool {
        appGroupContainerURL != nil
    }
}
