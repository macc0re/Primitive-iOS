import SwiftUI
import AirliftFFI

@main
struct PrimitiveApp: App {
    init() {
        al_log_init({ _, message in
            guard let message else { return }
            print("[Airlift] \(String(cString: message))")
        }, nil)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
