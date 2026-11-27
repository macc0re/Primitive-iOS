import SwiftUI

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
                            .listRowBackground(selection == tab ? Color.purple.opacity(0.14) : Color.clear)
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
        .tint(.purple)
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
                    Image(systemName: module.symbol).font(.system(size: 42)).foregroundStyle(.purple)
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
        case .store: ModuleListView(title: "Primitive Store", subtitle: "Discover compatible customizations.", modules: ModuleInfo.store, installedIDs: installedIDs, isStore: true, onSelect: select, onInfo: { infoModule = $0 }, onUninstall: uninstall)
        case .installed: ModuleListView(title: "Installed", subtitle: "Manage your installed customizations.", modules: ModuleInfo.catalog.filter { installedIDs.contains($0.id) }, installedIDs: installedIDs, isStore: false, onSelect: select, onInfo: { infoModule = $0 }, onUninstall: uninstall)
        case .settings: SettingsView()
        }
    }
}

struct HomeView: View {
    let installedIDs: Set<String>
    let onSelect: (ModuleInfo) -> Void
    private let modules = ModuleInfo.catalog

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
                .buttonStyle(.borderedProminent).controlSize(.small).tint(.purple)
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
                        .buttonStyle(.borderedProminent).controlSize(.small).tint(.purple)
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
    var body: some View {
        Form {
            Section("Primitive") {
                LabeledContent("Version", value: "0.1.0-dev")
                LabeledContent("Build", value: "Foundation")
            }
            Section("Device") {
                LabeledContent("Compatibility", value: "Not checked")
                Text("System modification engines are not included in this foundation build.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("About") { LabeledContent("Developer", value: "Mac.Core") }
        }
        .navigationTitle("Settings")
    }
}
