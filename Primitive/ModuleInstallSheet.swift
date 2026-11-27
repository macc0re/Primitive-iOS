import SwiftUI

struct ModuleInstallSheet: View {
    @Binding var queue: [ModuleInfo]
    @Binding var installedIDs: Set<String>
    let activeModule: ModuleInfo?
    let onClose: () -> Void

    @State private var progress = 0
    @State private var isInstalling = false
    @State private var currentIndex = 0
    @State private var installError: String?

    private let installedStorageKey = "primitive.installed.module.ids"

    var body: some View {
        NavigationStack {
            Group {
                if let module = activeModule, queue.isEmpty {
                    moduleDestination(module)
                } else {
                    queueView
                }
            }
            .navigationTitle(activeModule != nil && queue.isEmpty ? activeModule!.title : "Install Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClose() }.disabled(isInstalling)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .safeAreaInset(edge: .bottom) {
            if !queue.isEmpty {
                Button("Clear Queue", role: .destructive) {
                    guard !isInstalling else { return }
                    queue.removeAll()
                    onClose()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(.bar)
            }
        }
        .alert("Installation failed", isPresented: Binding(
            get: { installError != nil },
            set: { if !$0 { installError = nil } }
        )) {
            Button("OK", role: .cancel) { installError = nil }
        } message: {
            Text(installError ?? "Unknown error")
        }
    }

    private var queueView: some View {
        VStack(spacing: 16) {
            if queue.isEmpty {
                ContentUnavailableView("Queue is empty", systemImage: "tray", description: Text("Choose a module from Home or Store to add it here."))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Packages in this queue").font(.headline)
                    ForEach(queue) { module in
                        HStack(spacing: 12) {
                            Image(systemName: module.symbol).foregroundStyle(.purple)
                                .frame(width: 38, height: 38)
                                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(module.title).font(.subheadline.weight(.semibold))
                                Text(module.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isInstalling && queue.firstIndex(of: module) == currentIndex {
                                Text("\(progress)%").font(.caption.monospacedDigit().weight(.semibold))
                            } else if installedIDs.contains(module.id) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            } else {
                                Image(systemName: "clock").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))

                if isInstalling {
                    ProgressView(value: Double(progress), total: 100).tint(.purple)
                    Text("Registering \(queue[min(currentIndex, queue.count - 1)].title)…")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Button(action: installQueue) {
                    HStack {
                        if isInstalling { ProgressView().tint(.white) }
                        else { Image(systemName: "arrow.down.circle.fill") }
                        Text(isInstalling ? "Installing…" : "Install All (\(queue.count))")
                    }
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent).tint(.purple).disabled(isInstalling)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
    }

    @ViewBuilder private func moduleDestination(_ module: ModuleInfo) -> some View {
        switch module.id {
        case "gestalt-tweaks": GestaltTweaksView()
        case "passcode-studio": PasscodeStudioView()
        default:
            VStack(spacing: 14) {
                Image(systemName: module.symbol).font(.system(size: 42)).foregroundStyle(.tint)
                Text(module.title).font(.title2.bold())
                Text("This module is registered in Primitive. Its feature engine is not available in this build yet.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(28)
        }
    }

    private func installQueue() {
        guard !isInstalling, !queue.isEmpty else { return }
        isInstalling = true
        installError = nil
        currentIndex = 0
        progress = 0

        Task { @MainActor in
            do {
                let pending = queue
                for (index, module) in pending.enumerated() {
                    currentIndex = index
                    guard !module.id.isEmpty else { throw ModuleInstallError.invalidModule }
                    progress = 20
                    try await Task.sleep(for: .milliseconds(220))
                    installedIDs.insert(module.id)
                    UserDefaults.standard.set(Array(installedIDs), forKey: installedStorageKey)
                    progress = 65
                    try await Task.sleep(for: .milliseconds(220))
                    guard installedIDs.contains(module.id) else { throw ModuleInstallError.registrationFailed }
                    progress = 100
                    try await Task.sleep(for: .milliseconds(180))
                }
                queue.removeAll()
                isInstalling = false
                onClose()
            } catch {
                isInstalling = false
                installError = error.localizedDescription
            }
        }
    }
}

private enum ModuleInstallError: LocalizedError {
    case invalidModule
    case registrationFailed
    var errorDescription: String? {
        switch self {
        case .invalidModule: "The selected module is invalid."
        case .registrationFailed: "Primitive could not verify the module registration."
        }
    }
}
