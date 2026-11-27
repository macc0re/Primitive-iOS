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
    @State private var selection: PrimitiveTab? = .home

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List(PrimitiveTab.allCases, selection: $selection) { tab in
                        Label(tab.rawValue, systemImage: tab.symbol)
                            .tag(tab as PrimitiveTab?)
                    }
                    .navigationTitle("Primitive")
                    .listStyle(.sidebar)
                } detail: {
                    detail
                }
            } else {
                TabView {
                    ForEach(PrimitiveTab.allCases) { tab in
                        NavigationStack {
                            page(for: tab)
                        }
                        .tabItem {
                            Label(tab.rawValue, systemImage: tab.symbol)
                        }
                    }
                }
            }
        }
        .tint(.purple)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .home {
        case .home: HomeView()
        case .store: ModuleListView(title: "Primitive Store", subtitle: "Discover compatible customizations.", modules: ModuleInfo.store)
        case .installed: ModuleListView(title: "Installed", subtitle: "Manage your installed customizations.", modules: ModuleInfo.installed)
        case .settings: SettingsView()
        }
    }

    @ViewBuilder
    private func page(for tab: PrimitiveTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .store: ModuleListView(title: "Primitive Store", subtitle: "Discover compatible customizations.", modules: ModuleInfo.store)
        case .installed: ModuleListView(title: "Installed", subtitle: "Manage your installed customizations.", modules: ModuleInfo.installed)
        case .settings: SettingsView()
        }
    }
}

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRIMITIVE").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                    Text("Make iOS yours.").font(.largeTitle.bold())
                    Text("A unified home for system customization.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Your device", systemImage: "iphone")
                        .font(.headline)
                    HStack {
                        Label("Compatibility check", systemImage: "checkmark.shield")
                        Spacer()
                        Text("Not checked").foregroundStyle(.secondary)
                    }.font(.subheadline)
                    Text("Device compatibility will appear here when the engine is implemented.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))

                Text("Explore modules").font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                    NavigationLink {
                        GestaltTweaksView()
                    } label: {
                        ModuleCard(title: "Gestalt Tweaks", detail: "MobileGestalt customizations", symbol: "slider.horizontal.3")
                    }
                    .buttonStyle(.plain)
                    ModuleCard(title: "Icon Studio", detail: "Icon collections and tools", symbol: "app.dashed")
                    NavigationLink {
                        PasscodeStudioView()
                    } label: {
                        ModuleCard(title: "Passcode Studio", detail: "Import and preview .passthm themes", symbol: "circle.grid.3x3")
                    }
                    .buttonStyle(.plain)
                    ModuleCard(title: "Live Wallpapers", detail: "Personal wallpaper library", symbol: "livephoto")
                    ModuleCard(title: "Device Manager", detail: "Compatibility and backups", symbol: "iphone.gen3")
                }
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Home")
    }
}

struct ModuleCard: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 42, height: 42)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 13))
            Text(title).font(.headline)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ModuleInfo: Identifiable {
    let title: String
    let detail: String
    let symbol: String
    var id: String { title }

    static let store = [
        ModuleInfo(title: "Gestalt Tweaks", detail: "Browse MobileGestalt packages.", symbol: "slider.horizontal.3"),
        ModuleInfo(title: "Icon Studio", detail: "Explore icon packs and assets.", symbol: "app.dashed"),
        ModuleInfo(title: "Passcode Themes", detail: "Import and preview .passthm packages.", symbol: "circle.grid.3x3"),
        ModuleInfo(title: "Wallpapers", detail: "Manage wallpaper collections.", symbol: "livephoto"),
        ModuleInfo(title: "Utilities", detail: "Tools compatible with your device.", symbol: "wrench.and.screwdriver")
    ]
    static let installed = [
        ModuleInfo(title: "No packages yet", detail: "Installed customizations will appear here.", symbol: "shippingbox")
    ]
}

struct ModuleListView: View {
    let title: String
    let subtitle: String
    let modules: [ModuleInfo]

    var body: some View {
        List(modules) { module in
            moduleRow(for: module)
        }
        .navigationTitle(title)
        .safeAreaInset(edge: .top) {
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal).padding(.top, 8)
        }
    }

    @ViewBuilder
    private func moduleRow(for module: ModuleInfo) -> some View {
        if module.title == "Passcode Themes" {
            NavigationLink {
                PasscodeStudioView()
            } label: {
                moduleLabel(module)
            }
        } else if module.title == "Gestalt Tweaks" {
            NavigationLink {
                GestaltTweaksView()
            } label: {
                moduleLabel(module)
            }
        } else {
            moduleLabel(module)
        }
    }

    private func moduleLabel(_ module: ModuleInfo) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title).font(.headline)
                Text(module.detail).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: module.symbol).foregroundStyle(.tint)
        }
        .padding(.vertical, 5)
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
            Section("About") {
                LabeledContent("Developer", value: "Mac.Core")
            }
        }
        .navigationTitle("Settings")
    }
}
