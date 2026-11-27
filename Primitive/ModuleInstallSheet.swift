import SwiftUI

struct ModuleInstallSheet: View {
    let module: ModuleInfo
    let onClearQueue: () -> Void

    @State private var progress = 0
    @State private var isInstalling = false
    @State private var isInstalled = false
    @State private var installError: String?

    private var storageKey: String {
        "primitive.module.installed.\(module.id)"
    }

    var body: some View {
        NavigationStack {
            Group {
                if isInstalled {
                    installedDestination
                } else {
                    installQueue
                }
            }
            .navigationTitle(isInstalled ? module.title : "Install Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClearQueue() }
                        .disabled(isInstalling)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Clear Queue", role: .destructive) {
                onClearQueue()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.bar)
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

    private var installQueue: some View {
        VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Selected package")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 14) {
                    Image(systemName: module.symbol)
                        .font(.title2)
                        .foregroundStyle(.purple)
                        .frame(width: 48, height: 48)
                        .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.title).font(.headline)
                        Text(module.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    if isInstalling {
                        Text("\(progress)%")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                }

                if isInstalling {
                    ProgressView(value: Double(progress), total: 100)
                        .tint(.purple)
                    Text(installationStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 12) {
                Button {
                    beginInstallation()
                } label: {
                    HStack {
                        if isInstalling {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isInstalling ? "Installing…" : "Install")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(isInstalling)
            }

            Spacer()
        }
        .padding(20)
    }

    private var installationStatus: String {
        switch progress {
        case 0..<25: "Preparing package…"
        case 25..<60: "Registering module…"
        case 60..<100: "Verifying installation…"
        default: "Installation complete"
        }
    }

    @ViewBuilder
    private var installedDestination: some View {
        switch module.title {
        case "Gestalt Tweaks":
            GestaltTweaksView()
        case "Passcode Studio", "Passcode Themes":
            PasscodeStudioView()
        default:
            VStack(spacing: 14) {
                Image(systemName: module.symbol)
                    .font(.system(size: 42))
                    .foregroundStyle(.tint)
                Text(module.title).font(.title2.bold())
                Text("The module is now enabled in Primitive. Its feature engine is not available in this build yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
    }

    private func beginInstallation() {
        guard !isInstalling, !isInstalled else { return }
        isInstalling = true
        installError = nil

        Task {
            do {
                // Validate the selected module before registering it.
                guard !module.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ModuleInstallError.invalidModule
                }
                progress = 20
                try await Task.sleep(for: .milliseconds(250))

                // Persist the module's enabled state locally.
                UserDefaults.standard.set(true, forKey: storageKey)
                progress = 60
                try await Task.sleep(for: .milliseconds(250))

                // Read back the stored state to verify registration.
                guard UserDefaults.standard.bool(forKey: storageKey) else {
                    throw ModuleInstallError.registrationFailed
                }
                progress = 100
                try await Task.sleep(for: .milliseconds(200))

                isInstalled = true
                isInstalling = false
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
        case .invalidModule:
            "The selected module is invalid."
        case .registrationFailed:
            "Primitive could not verify the module registration."
        }
    }
}
