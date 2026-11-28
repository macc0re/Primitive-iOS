import Foundation

enum PairingRecordStore {
    private static let directoryName = "PairingRecords"

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(directoryName, isDirectory: true)
    }

    static func storedFileURL() -> URL? {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else { return nil }
        return files.first
    }

    static func storedFileName() -> String? {
        storedFileURL()?.lastPathComponent
    }

    /// Stores a property-list pairing record with complete file protection.
    /// The same method can be called by a future pairing backend after authorization.
    @discardableResult
    static func save(_ data: Data, originalName: String) throws -> URL {
        var format = PropertyListSerialization.PropertyListFormat.xml
        let object = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        )
        guard object is [String: Any] else {
            throw PairingRecordError.invalidFormat
        }

        let manager = FileManager.default
        try manager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )

        let fileExtension = URL(fileURLWithPath: originalName).pathExtension
        let safeExtension = fileExtension.isEmpty ? "mobiledevicepairing" : fileExtension
        let destination = directoryURL.appendingPathComponent("device-pairing.\(safeExtension)")

        if let existingFiles = try? manager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) {
            for file in existingFiles where file != destination {
                try? manager.removeItem(at: file)
            }
        }

        try data.write(to: destination, options: [.atomic, .completeFileProtection])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var protectedURL = destination
        try? protectedURL.setResourceValues(values)
        return destination
    }

    enum PairingRecordError: LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            "The selected file is not a valid pairing property list."
        }
    }
}
