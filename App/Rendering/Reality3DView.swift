// Purpose: SwiftUI host for the game map: RealityView with a virtual camera plus the camera touch layer. Notes: docs/features/rendering-art.md
import RealityKit
import SwiftUI

/// The map, drawn in real 3D (D-027; the 2D SpriteKit views were retired in D-030). Reads GameStore; never changes
/// game state. Minimum iOS is 18 (D-028), so this is RealityView only.
struct Reality3DView: View {
    let store: GameStore
    let ticker: GameTicker
    @State private var world: World3D?
    @State private var hook = FrameHook()

    /// Keeps the per-frame subscription alive as long as the view lives.
    @MainActor final class FrameHook {
        var subscription: EventSubscription?
    }

    var body: some View {
        ZStack {
            Color(UIColor.hex(store.content?.presentation.outsideMapColor ?? "#000000")).ignoresSafeArea()
            if let world {
                RealityView { content in
                    content.camera = .virtual
                    content.add(world.root)
                    hook.subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                        let dt = event.deltaTime
                        MainActor.assumeIsolated { world.update(dt: dt) }
                    }
                }
                .ignoresSafeArea()
                OrbitGestures3D(world: world).ignoresSafeArea()
            }
        }
        .onAppear {
            ticker.discardEvents()
            if world == nil { world = World3D(store: store, ticker: ticker) }
        }
    }
}
