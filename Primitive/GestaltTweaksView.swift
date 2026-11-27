import SwiftUI

struct GestaltTweak: Identifiable {
    let title: String
    let detail: String
    let category: String
    let note: String
    var id: String { title }

    static let catalog: [GestaltTweak] = [
        // Display and interface
        .init(title: "Dynamic Island", detail: "Expose Dynamic Island interface on supported notch devices.", category: "Pantalla e interfaz", note: "Experimental · Requires compatible system components"),
        .init(title: "Always-On Display", detail: "Expose Always-On Display settings.", category: "Pantalla e interfaz", note: "Device-dependent · Requires compatible display hardware"),
        .init(title: "AOD Vibrancy", detail: "Adjust Always-On Display visual vibrancy.", category: "Pantalla e interfaz", note: "Experimental · AOD support required"),
        .init(title: "AOD High Luminance", detail: "Expose higher-luminance Always-On Display behavior.", category: "Pantalla e interfaz", note: "Experimental · Hardware-dependent"),
        .init(title: "AOD Flipbook", detail: "Enable experimental flipbook-style AOD behavior.", category: "Pantalla e interfaz", note: "Experimental · Compatibility unverified"),
        .init(title: "Liquid Glass", detail: "Expose system visual-effect variants.", category: "Pantalla e interfaz", note: "Version-dependent · Does not guarantee lower power use"),
        .init(title: "HDR Photos", detail: "Enable HDR photo display capabilities where supported.", category: "Pantalla e interfaz", note: "Hardware and OS-dependent"),
        .init(title: "Wallpaper Parallax", detail: "Expose perspective and parallax wallpaper effects.", category: "Pantalla e interfaz", note: "Version-dependent"),
        .init(title: "PWM / DisplayPort Options", detail: "Expose experimental display and external-display flags.", category: "Pantalla e interfaz", note: "Experimental · Hardware-dependent"),
        .init(title: "Display Resolution Scaling", detail: "Change available display-scaling profiles.", category: "Pantalla e interfaz", note: "High risk of layout issues · Device-specific"),

        // Apple Intelligence and Siri
        .init(title: "Apple Intelligence", detail: "Expose Apple Intelligence eligibility flags.", category: "Apple Intelligence y Siri", note: "Does not add unsupported memory, neural hardware, language models or region availability"),
        .init(title: "Photos Clean Up", detail: "Expose the Clean Up editing feature.", category: "Apple Intelligence y Siri", note: "Requires Apple Intelligence components"),
        .init(title: "Audio Intelligence", detail: "Expose supported audio intelligence features.", category: "Apple Intelligence y Siri", note: "Version and hardware-dependent"),
        .init(title: "Personal Translator", detail: "Expose translation-related system features.", category: "Apple Intelligence y Siri", note: "Language and OS-dependent"),
        .init(title: "Handwriting Synthesis", detail: "Expose handwriting recognition and synthesis options.", category: "Apple Intelligence y Siri", note: "App and OS-dependent"),
        .init(title: "On-device Siri Processing", detail: "Expose on-device Siri processing options.", category: "Apple Intelligence y Siri", note: "Requires supported Siri assets and hardware"),
        .init(title: "RegionCode / RegionInfo", detail: "Inspect and edit regional capability identifiers.", category: "Apple Intelligence y Siri", note: "Changing region identifiers does not guarantee feature eligibility"),
        .init(title: "Hey Siri", detail: "Expose always-listening Siri configuration.", category: "Apple Intelligence y Siri", note: "Microphone, language and hardware-dependent"),

        // Hardware and controls
        .init(title: "Action Button", detail: "Expose Action Button configuration UI.", category: "Hardware y controles", note: "May expose settings without adding a physical button"),
        .init(title: "Camera Control", detail: "Expose Camera Control interface options.", category: "Hardware y controles", note: "No physical control is created"),
        .init(title: "Charge Limit", detail: "Expose battery charge-limit settings.", category: "Hardware y controles", note: "Battery controller and OS-dependent"),
        .init(title: "Tap to Wake", detail: "Expose Tap to Wake capability flags.", category: "Hardware y controles", note: "Requires compatible touch/display hardware"),
        .init(title: "Audio Mix", detail: "Expose Audio Mix options.", category: "Hardware y controles", note: "App, microphone and OS-dependent"),
        .init(title: "FaceTime Spatial Audio", detail: "Expose spatial audio options in FaceTime.", category: "Hardware y controles", note: "Requires compatible audio hardware"),
        .init(title: "Boot Chime", detail: "Expose startup and shutdown sound options.", category: "Hardware y controles", note: "Version and device-dependent"),
        .init(title: "Collision SOS", detail: "Expose crash-detection capability flags.", category: "Hardware y controles", note: "Must not be treated as a replacement for certified crash-detection hardware"),
        .init(title: "Camera Shutter Sound", detail: "Inspect camera shutter sound policy flags.", category: "Hardware y controles", note: "Region and legal restrictions apply; availability is not guaranteed"),

        // iPadOS and Apple Watch
        .init(title: "Stage Manager", detail: "Expose Stage Manager and windowing options.", category: "iPadOS y Apple Watch", note: "Requires compatible memory, display and graphics capabilities"),
        .init(title: "iPad App Compatibility", detail: "Inspect iPad interface and compatibility flags.", category: "iPadOS y Apple Watch", note: "Does not guarantee that iPad-only apps can run on iPhone"),
        .init(title: "Apple Pencil Options", detail: "Expose Apple Pencil configuration capabilities.", category: "iPadOS y Apple Watch", note: "Requires compatible digitizer and Pencil hardware"),
        .init(title: "Hermès Watch Faces", detail: "Inspect Apple Watch face availability presets.", category: "iPadOS y Apple Watch", note: "Model, pairing and entitlement-dependent"),
        .init(title: "Ultra Watch Faces", detail: "Inspect Apple Watch Ultra face availability presets.", category: "iPadOS y Apple Watch", note: "Display and model-dependent"),
        .init(title: "Apple Watch Siri AI", detail: "Inspect Siri capability flags for Apple Watch.", category: "iPadOS y Apple Watch", note: "Watch model, OS and paired-device dependent"),

        // Advanced
        .init(title: "Device Model Name", detail: "Change the model label shown in system information.", category: "Ajustes avanzados", note: "Cosmetic identifier · May affect app compatibility checks"),
        .init(title: "Storage View", detail: "Expose internal storage diagnostics views.", category: "Ajustes avanzados", note: "Internal UI may be unavailable in public builds"),
        .init(title: "Security Research Device Indicators", detail: "Inspect internal security-research UI flags.", category: "Ajustes avanzados", note: "Does not grant security-research device privileges"),

        // Related tools, not MobileGestalt tweaks
        .init(title: "Dialer Themes", detail: "Explore dialer theme capabilities associated with Erosion-style tools.", category: "Herramientas relacionadas", note: "Not a MobileGestalt setting · Separate implementation required"),
        .init(title: "PosterBoard Wallpapers", detail: "Explore dynamic wallpaper capabilities associated with Erosion-style tools.", category: "Herramientas relacionadas", note: "Not a MobileGestalt setting · Separate PosterBoard implementation required"),
        .init(title: "Supervision Utilities", detail: "Explore supervision-related device management tools.", category: "Herramientas relacionadas", note: "Not a MobileGestalt setting · Requires separate implementation")
    ]

    static let categories = [
        "Pantalla e interfaz",
        "Apple Intelligence y Siri",
        "Hardware y controles",
        "iPadOS y Apple Watch",
        "Ajustes avanzados",
        "Herramientas relacionadas"
    ]
}

struct GestaltTweaksView: View {
    @State private var searchText = ""

    private var filteredCatalog: [GestaltTweak] {
        guard !searchText.isEmpty else { return GestaltTweak.catalog }
        return GestaltTweak.catalog.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.detail.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                Label("Catálogo de MobileGestalt", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Text("Explora los indicadores y funciones recopilados. Esta versión es informativa: todavía no aplica cambios al sistema.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(GestaltTweak.categories, id: \.self) { category in
                let items = filteredCatalog.filter { $0.category == category }
                if !items.isEmpty {
                    Section(category) {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(item.title).font(.body.weight(.medium))
                                    Spacer(minLength: 8)
                                    Text("En investigación")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.note)
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Buscar modificación")
        .navigationTitle("Gestalt Tweaks")
    }
}
