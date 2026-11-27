import SwiftUI
import UIKit
import UniformTypeIdentifiers
import ZIPFoundation

struct PasscodeTheme: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let archiveURL: URL
    let assetCount: Int
    let digitImages: [String: Data]

    var configuredDigits: Int {
        digitImages.keys.filter { $0.count == 1 && $0.first?.isNumber == true }.count
    }

    var missingDigits: [String] {
        (0...9).map(String.init).filter { digitImages[$0] == nil }
    }
}

final class PasscodeThemeLibrary: ObservableObject {
    @Published private(set) var themes: [PasscodeTheme] = []

    private let fileManager = FileManager.default

    init() {
        reload()
    }

    func reload() {
        guard let folder = try? themeFolder() else { return }
        let files = (try? fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        themes = files
            .filter { ["passthm", "zip"].contains($0.pathExtension.lowercased()) }
            .compactMap { try? inspectTheme(at: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func importTheme(from sourceURL: URL) throws {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let folder = try themeFolder()
        let originalName = sourceURL.lastPathComponent
        let safeName = "\\(UUID().uuidString.prefix(8))-\\(originalName)"
        let destination = folder.appendingPathComponent(safeName)

        try fileManager.copyItem(at: sourceURL, to: destination)

        do {
            let theme = try inspectTheme(at: destination)
            guard theme.assetCount > 0 else {
                throw PasscodeThemeError.noImages
            }
            themes.removeAll { $0.fileName == theme.fileName }
            themes.append(theme)
            themes.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            try? fileManager.removeItem(at: destination)
            throw error
        }
    }

    func remove(_ theme: PasscodeTheme) {
        try? fileManager.removeItem(at: theme.archiveURL)
        themes.removeAll { $0.id == theme.id }
    }

    private func themeFolder() throws -> URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("PasscodeThemes", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        return folder
    }

    private func inspectTheme(at url: URL) throws -> PasscodeTheme {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw PasscodeThemeError.invalidArchive
        }

        var digitImages: [String: Data] = [:]
        var imageCount = 0
        var totalUncompressed: UInt64 = 0

        for entry in archive {
            guard entry.type == .file else { continue }
            let path = entry.path
            let lowerPath = path.lowercased()

            guard !lowerPath.hasPrefix("__macosx/"),
                  !URL(fileURLWithPath: path).lastPathComponent.hasPrefix("."),
                  ["png", "jpg", "jpeg"].contains(URL(fileURLWithPath: path).pathExtension.lowercased()),
                  entry.uncompressedSize <= 12 * 1024 * 1024 else {
                continue
            }

            totalUncompressed += entry.uncompressedSize
            guard totalUncompressed <= 80 * 1024 * 1024 else {
                throw PasscodeThemeError.archiveTooLarge
            }

            var imageData = Data()
            _ = try archive.extract(entry) { chunk in
                imageData.append(chunk)
            }

            guard UIImage(data: imageData) != nil else { continue }
            imageCount += 1

            if let digit = Self.digit(in: URL(fileURLWithPath: path).lastPathComponent),
               digitImages[digit] == nil {
                digitImages[digit] = imageData
            }
        }

        return PasscodeTheme(
            name: url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: #"^[A-Fa-f0-9]{8}-"#, with: "", options: .regularExpression),
            fileName: url.lastPathComponent,
            archiveURL: url,
            assetCount: imageCount,
            digitImages: digitImages
        )
    }

    private static func digit(in fileName: String) -> String? {
        var stem = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        stem = stem.replacingOccurrences(
            of: #"--?white(?:-bold)?$"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        let pattern = #"^(?:[A-Za-z]+-)?([0-9*#])(?:-|$)"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(
                in: stem,
                range: NSRange(stem.startIndex..., in: stem)
              ),
              let range = Range(match.range(at: 1), in: stem) else {
            return nil
        }
        return String(stem[range])
    }
}

enum PasscodeThemeError: LocalizedError {
    case invalidArchive
    case noImages
    case archiveTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidArchive:
            "The selected file is not a readable .passthm archive."
        case .noImages:
            "No usable passcode artwork was found in this archive."
        case .archiveTooLarge:
            "The theme archive is too large to inspect safely."
        }
    }
}

struct PasscodeStudioView: View {
    @StateObject private var library = PasscodeThemeLibrary()
    @State private var showingImporter = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private let themeType = UTType(filenameExtension: "passthm", conformingTo: .archive) ?? .archive

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("PASSCODE STUDIO")
                        .font(.caption.weight(.bold))
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                    Text("Customize your keypad.")
                        .font(.largeTitle.bold())
                    Text("Import and inspect Cowabunga or Nugget .passthm themes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showingImporter = true
                } label: {
                    Label("Import .passthm Theme", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("This build only imports and previews themes. Applying changes to iOS is not available yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                HStack {
                    Text("Your themes").font(.title2.bold())
                    Spacer()
                    Text("\(library.themes.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if library.themes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)
                        Text("No themes imported")
                            .font(.headline)
                        Text("Choose a .passthm file to see its artwork here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 42)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
                } else {
                    ForEach(library.themes) { theme in
                        PasscodeThemeCard(theme: theme) {
                            library.remove(theme)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Passcode Studio")
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [themeType, .zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try library.importTheme(from: url)
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .alert("Unable to import theme", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct PasscodeThemeCard: View {
    let theme: PasscodeTheme
    let onDelete: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name).font(.headline)
                    Text("\(theme.assetCount) image assets · \(theme.configuredDigits)/10 digits recognized")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove Theme", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"], id: \.self) { digit in
                    PasscodeKeyPreview(digit: digit, imageData: theme.digitImages[digit])
                }
            }
            .frame(maxWidth: 310)
            .frame(maxWidth: .infinity)

            if !theme.missingDigits.isEmpty {
                Text("No artwork recognized for: \(theme.missingDigits.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(theme.fileName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct PasscodeKeyPreview: View {
    let digit: String
    let imageData: Data?

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 68, height: 68)
                    .clipShape(Circle())
            }
            Text(digit)
                .font(.title2.weight(.medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.75), radius: 3, x: 0, y: 1)
        }
        .frame(width: 68, height: 68)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }
}
