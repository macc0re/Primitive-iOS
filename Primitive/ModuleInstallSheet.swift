import SwiftUI

struct ModuleInstallSheet: View {
    @Binding var queue: [ModuleInfo]
    @Binding var installedIDs: Set<String>
    let activeModule: ModuleInfo?
    let uninstallMode: Bool
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
            .navigationTitle(activeModule != nil && queue.isEmpty ? activeModule!.title : (uninstallMode ? "Uninstall Tweaks" : "Install Tweaks"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClose() }.disabled(isInstalling)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
                    Text(uninstallMode ? "Tweaks to uninstall" : "Tweaks to install").font(.headline)
                    ForEach(queue) { module in
                        HStack(spacing: 12) {
                            Image(systemName: module.symbol).foregroundStyle(Color.primitiveBlue)
                                .frame(width: 38, height: 38)
                                .background(Color.primitiveBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
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
                    ProgressView(value: Double(progress), total: 100).tint(Color.primitiveBlue)
                    Text("\(uninstallMode ? "Removing" : "Registering") \(queue[min(currentIndex, queue.count - 1)].title)…")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Button(action: processQueue) {
                    HStack {
                        if isInstalling { ProgressView().tint(.white) }
                        else { Image(systemName: uninstallMode ? "trash" : "arrow.down.circle.fill") }
                        Text(isInstalling ? (uninstallMode ? "Removing…" : "Installing…") : (uninstallMode ? "Uninstall Tweaks (\(queue.count))" : "Install Tweaks (\(queue.count))"))
                    }
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent).tint(uninstallMode ? .red : Color.primitiveBlue).disabled(isInstalling)

                if uninstallMode { Text("This only removes the module from Primitive’s local installed list. It does not uninstall system tweaks or reverse system changes.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading) }

                Button("Clear Queue", role: .destructive) {
                    guard !isInstalling else { return }
                    queue.removeAll()
                    onClose()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(isInstalling)
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

    private func processQueue() {
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
                    if uninstallMode { installedIDs.remove(module.id) } else { installedIDs.insert(module.id) }
                    UserDefaults.standard.set(Array(installedIDs), forKey: installedStorageKey)
                    progress = 65
                    try await Task.sleep(for: .milliseconds(220))
                    let stateMatches = uninstallMode ? !installedIDs.contains(module.id) : installedIDs.contains(module.id)
                    guard stateMatches else { throw ModuleInstallError.registrationFailed }
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
