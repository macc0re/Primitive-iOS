import Foundation

enum PrimitiveWorseQueryRuntime {
    static let appGroupIdentifier = "group.com.mac.core.primitive"

    static var appGroupContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
    }

    private static var cachesURL: URL? {
        appGroupContainerURL?.appendingPathComponent("Library/Caches", isDirectory: true)
    }

    /// Read-only inspection. Never creates, removes, or changes App Group files.
    private static var cachesInspection: String {
        guard let cachesURL else {
            return "Caches status unavailable"
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: cachesURL.path,
            isDirectory: &isDirectory
        ) else {
            return "Caches directory does not exist"
        }

        guard isDirectory.boolValue else {
            return "Caches path is not a directory"
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cachesURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return contents.isEmpty
                ? "Caches directory is empty"
                : "Caches contains \(contents.count) item(s) — probe blocked"
        } catch {
            return "Caches inspection failed — probe blocked"
        }
    }

    static var appGroupStatus: String {
        guard let containerURL = appGroupContainerURL else {
            return "App Group unavailable — signing entitlement not effective"
        }

        return "App Group available — \(containerURL.lastPathComponent); \(cachesInspection)"
    }

    static var isAppGroupAvailable: Bool {
        appGroupContainerURL != nil
    }

    /// This is deliberately conservative: the upstream PoC removes Library/Caches.
    /// A non-empty, missing, or unreadable directory must never be passed to it.
    static var isControlledProbePreflightClear: Bool {
        guard let cachesURL else { return false }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: cachesURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              let contents = try? FileManager.default.contentsOfDirectory(
                at: cachesURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
              ) else {
            return false
        }
        return contents.isEmpty
    }
}
