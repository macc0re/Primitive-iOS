import SwiftUI

extension Color {
    static let primitiveBlue = Color(red: 0.10, green: 0.55, blue: 1.0)
}

enum PrimitiveTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case store = "Store"
    case installed = "Installed"
    case settings = "Settings"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .home: "square.grid.2x2"
        case .store: "shippingbox"
        case .installed: "checkmark.seal"
        case .settings: "gearshape"
        }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: PrimitiveTab = .home
    @State private var showModuleSheet = false
    @State private var installQueue: [ModuleInfo] = []
    @State private var activeModule: ModuleInfo?
    @State private var uninstallMode = false
    @State private var infoModule: ModuleInfo?
    @State private var installedIDs = Set(UserDefaults.standard.stringArray(forKey: "primitive.installed.module.ids") ?? [])

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List {
                        ForEach(PrimitiveTab.allCases) { tab in
                            Button { selection = tab } label: {
                                Label(tab.rawValue, systemImage: tab.symbol)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(selection == tab ? Color.primitiveBlue.opacity(0.14) : Color.clear)
                        }
                    }
                    .navigationTitle("Primitive")
                    .listStyle(.sidebar)
                } detail: { detail }
            } else {
                TabView(selection: $selection) {
                    ForEach(PrimitiveTab.allCases) { tab in
                        NavigationStack { page(for: tab) }
                            .tabItem { Label(tab.rawValue, systemImage: tab.symbol) }
                            .tag(tab)
                    }
                }
            }
        }
        .tint(Color.primitiveBlue)
        .sheet(isPresented: $showModuleSheet) {
            ModuleInstallSheet(
                queue: $installQueue,
                installedIDs: $installedIDs,
                activeModule: activeModule,
                uninstallMode: uninstallMode,
                onClose: {
                    showModuleSheet = false
                    activeModule = nil
                }
            )
        }
        .sheet(item: $infoModule) { module in
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: module.symbol).font(.system(size: 42)).foregroundStyle(Color.primitiveBlue)
                    Text(module.title).font(.title2.bold())
                    Text(module.detail).foregroundStyle(.secondary)
                    LabeledContent("Package ID", value: module.id)
                    LabeledContent("Status", value: installedIDs.contains(module.id) ? "Installed" : "Not installed")
                    Spacer()
                }
                .padding(24)
                .navigationTitle("Package Info")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    private func queueUninstall(_ module: ModuleInfo) {
        guard installedIDs.contains(module.id) else { return }
        activeModule = nil
        uninstallMode = true
        if !installQueue.contains(where: { $0.id == module.id }) {
            installQueue.append(module)
        }
        showModuleSheet = true
    }

    private func select(_ module: ModuleInfo) {
        if installedIDs.contains(module.id) {
            activeModule = module
            uninstallMode = false
        } else {
            uninstallMode = false
            activeModule = nil
            if !installQueue.contains(where: { $0.id == module.id }) {
                installQueue.append(module)
            }
        }
        showModuleSheet = true
    }

    @ViewBuilder private var detail: some View {
        switch selection {
        case .home: HomeView(installedIDs: installedIDs, onSelect: select)
        case .store: ModuleListView(title: "Primitive Store", subtitle: "Discover compatible customizations.", modules: ModuleInfo.store, installedIDs: installedIDs, onSelect: select, onInfo: { infoModule = $0 }, onUninstall: queueUninstall)
        case .installed: ModuleListView(title: "Installed", subtitle: "Manage your installed customizations.", modules: ModuleInfo.catalog.filter { installedIDs.contains($0.id) }, installedIDs: installedIDs, onSelect: select, onInfo: { infoModule = $0 }, onUninstall: queueUninstall)
        case .settings: SettingsView()
        }
    }

    @ViewBuilder private func page(for tab: PrimitiveTab) -> some View {
        switch tab {
        case .home: HomeView(installedIDs: installedIDs, onSelect: select)
        case .store: ModuleListView(title: "Primitive Store", subtitle: "Discover compatible customizations.", modules: ModuleInfo.store, installedIDs: installedIDs, onSelect: select, onInfo: { infoModule = $0 }, onUninstall: queueUninstall)
        case .installed: ModuleListView(title: "Installed", subtitle: "Manage your installed customizations.", modules: ModuleInfo.catalog.filter { installedIDs.contains($0.id) }, installedIDs: installedIDs, onSelect: select, onInfo: { infoModule = $0 }, onUninstall: queueUninstall)
        case .settings: SettingsView()
        }
    }
}

struct HomeView: View {
    let installedIDs: Set<String>
    let onSelect: (ModuleInfo) -> Void
    private let modules = ModuleInfo.catalog
    @AppStorage("primitive.auto.respring.after.apply") private var autoRespring = true
    @AppStorage("primitive.traditional.skip.setup") private var traditionalSkipSetup = true
    @State private var activeNotice: HomeActionNotice?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRIMITIVE").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                    Text("Make iOS yours.").font(.largeTitle.bold())
                    Text("A unified home for system customization.").font(.subheadline).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label("Your device", systemImage: "iphone").font(.headline)
                    HStack {
                        Label("Compatibility check", systemImage: "checkmark.shield")
                        Spacer()
                        Text("Not checked").foregroundStyle(.secondary)
                    }.font(.subheadline)
                    Text("Device compatibility will appear here when the engine is implemented.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "info").font(.title3.weight(.medium)).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("VERSION 0.1.0-DEV")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text("TWEAK OPTIONS")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(spacing: 8) {
                        homeActionRow(title: "Apply Tweaks", color: Color.blue.opacity(0.22), foreground: .blue, notice: .apply)
                        homeActionRow(title: "Remove All Tweaks", color: Color.red.opacity(0.20), foreground: .red, notice: .remove)
                        homeActionRow(title: "Select Pairing File", color: Color.green.opacity(0.20), foreground: .green, notice: .pairing)
                    }

                    Divider().overlay(Color.white.opacity(0.12))

                    Toggle("Auto respring after apply", isOn: $autoRespring)
                        .font(.body.weight(.medium))
                        .tint(.green)

                    Divider().overlay(Color.white.opacity(0.12))

                    HStack(spacing: 12) {
                        Text("Traditional Skip Setup")
                            .font(.body.weight(.medium))
                        Button {
                            activeNotice = .skipInfo
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Toggle("Traditional Skip Setup", isOn: $traditionalSkipSetup)
                            .labelsHidden()
                            .tint(.green)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))

                Text("Explore modules").font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                    ForEach(modules) { module in
                        ModuleCard(module: module, isInstalled: installedIDs.contains(module.id)) {
                            onSelect(module)
                        }
                    }
                }
            }
            .padding().frame(maxWidth: 900, alignment: .leading).frame(maxWidth: .infinity)
        }
        .navigationTitle("Home")
        .alert(item: $activeNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func homeActionRow(title: String, color: Color, foreground: Color, notice: HomeActionNotice) -> some View {
        HStack(spacing: 12) {
            Button {
                activeNotice = notice
            } label: {
                Text(title)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 62)
                    .foregroundStyle(foreground)
                    .background(color, in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)
            Button {
                activeNotice = notice
            } label: {
                Image(systemName: "info")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 64, height: 62)
                    .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)
        }
    }
}

private enum HomeActionNotice: String, Identifiable {
    case apply, remove, pairing, skipInfo
    var id: String { rawValue }
    var title: String {
        switch self {
        case .apply: "Apply Tweaks"
        case .remove: "Remove All Tweaks"
        case .pairing: "Select Pairing File"
        case .skipInfo: "Traditional Skip Setup"
        }
    }
    var message: String {
        switch self {
        case .apply: "The MobileGestalt engine is not connected yet. This action will be enabled when the engine is implemented."
        case .remove: "Tweak removal is not connected yet. Original-value backups and the restore engine must be implemented first."
        case .pairing: "Pairing-file support is not connected yet. No file has been selected."
        case .skipInfo: "This option stores your preference. Its system behavior will be connected when the exploit engine is integrated."
        }
    }
}

struct ModuleCard: View {
    let module: ModuleInfo
    let isInstalled: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: module.symbol).font(.title2).foregroundStyle(.tint)
                .frame(width: 42, height: 42)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 13))
            Text(module.title).font(.headline)
            Text(module.detail).font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button(action: onSelect) {
                    Label(isInstalled ? "Open" : "Install", systemImage: isInstalled ? "arrow.up.right.square" : "arrow.down.circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent).controlSize(.small).tint(Color.primitiveBlue)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .leading)
        .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ModuleInfo: Identifiable, Hashable {
    let title: String
    let detail: String
    let symbol: String
    var id: String {
        switch title {
        case "Passcode Studio", "Passcode Themes": "passcode-studio"
        case "Live Wallpapers", "Wallpapers": "wallpapers"
        case "Utilities", "Device Manager": title.lowercased().replacingOccurrences(of: " ", with: "-")
        default: title.lowercased().replacingOccurrences(of: " ", with: "-")
        }
    }

    static let catalog = [
        ModuleInfo(title: "Gestalt Tweaks", detail: "MobileGestalt customizations", symbol: "slider.horizontal.3"),
        ModuleInfo(title: "Icon Studio", detail: "Icon collections and tools", symbol: "app.dashed"),
        ModuleInfo(title: "Passcode Studio", detail: "Import and preview .passthm themes", symbol: "circle.grid.3x3"),
        ModuleInfo(title: "Live Wallpapers", detail: "Personal wallpaper library", symbol: "livephoto"),
        ModuleInfo(title: "Device Manager", detail: "Compatibility and backups", symbol: "iphone.gen3")
    ]
    static let store = [
        ModuleInfo(title: "Gestalt Tweaks", detail: "Browse MobileGestalt packages.", symbol: "slider.horizontal.3"),
        ModuleInfo(title: "Icon Studio", detail: "Explore icon packs and assets.", symbol: "app.dashed"),
        ModuleInfo(title: "Passcode Themes", detail: "Import and preview .passthm packages.", symbol: "circle.grid.3x3"),
        ModuleInfo(title: "Wallpapers", detail: "Manage wallpaper collections.", symbol: "livephoto"),
        ModuleInfo(title: "Utilities", detail: "Tools compatible with your device.", symbol: "wrench.and.screwdriver")
    ]
}

struct ModuleListView: View {
    let title: String
    let subtitle: String
    let modules: [ModuleInfo]
    let installedIDs: Set<String>
    let onSelect: (ModuleInfo) -> Void
    let onInfo: (ModuleInfo) -> Void
    let onUninstall: (ModuleInfo) -> Void
    @State private var infoModule: ModuleInfo?

    var body: some View {
        List {
            if modules.isEmpty {
                ContentUnavailableView("No modules installed", systemImage: "shippingbox", description: Text("Modules you install will appear here."))
            } else {
                ForEach(modules) { module in
                    HStack(spacing: 12) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.title).font(.headline)
                                Text(module.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: module.symbol).foregroundStyle(.tint)
                        }
                        Spacer(minLength: 8)
                        Button { onSelect(module) } label: {
                            Text(installedIDs.contains(module.id) ? "Open" : "Install")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent).controlSize(.small).tint(Color.primitiveBlue)
                    }
                    .padding(.vertical, 5)
                    .contextMenu {
                        Button { onInfo(module) } label: {
                            Label("Info", systemImage: "info.circle")
                        }
                        if installedIDs.contains(module.id) {
                            Button(role: .destructive) { onUninstall(module) } label: {
                                Label("Uninstall Tweak", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .safeAreaInset(edge: .top) {
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal).padding(.top, 8)
        }
    }
}

struct SettingsView: View {
    @AppStorage("primitive.exploit.selection") private var selectedExploit = "worse_query"
    private let device = PrimitiveDeviceProfile.current

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Group {
                        if let imageURL = device.imageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .empty, .failure:
                                    Color.clear
                                @unknown default:
                                    Color.clear
                                }
                            }
                        } else {
                            Color.clear
                        }
                    }
                    .frame(
                        width: UIDevice.current.userInterfaceIdiom == .pad ? 190 : 145,
                        height: UIDevice.current.userInterfaceIdiom == .pad ? 210 : 225
                    )
                    .accessibilityLabel(device.marketingName)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(device.marketingName)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(device.identifier)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(device.chip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(device.operatingSystem) (\(device.systemBuild))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Device Information")
            }

            Section("Exploit Settings") {
                Picker("Exploit", selection: $selectedExploit) {
                    Text("bad_query").tag("bad_query")
                    Text("worse_query").tag("worse_query")
                }
                .pickerStyle(.menu)
                Text("worse_query is selected by default. The selected option is saved on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Primitive") {
                LabeledContent("Version", value: "0.1.0-dev")
                LabeledContent("Build", value: "Foundation")
            }

            Section("About") {
                LabeledContent("Developer", value: "Mac.Core")
            }
        }
        .navigationTitle("Settings")
    }
}
