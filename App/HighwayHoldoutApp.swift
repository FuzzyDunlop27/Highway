// Purpose: App entry point: creates the GameStore and saves when the app leaves the foreground. Notes: docs/features/hud-ui.md
import SwiftUI

@main
struct HighwayHoldoutApp: App {
    @State private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            GameRootView(store: store)
        }
        .onChange(of: scenePhase) { _, phase in
            store.lifecycle.handle(phase: phase, store: store)
        }
    }
}
