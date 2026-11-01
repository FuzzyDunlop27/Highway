// Purpose: The two ways to show the 1R spike scene: RealityView virtual camera (iOS 18+) and ARView non-AR (iOS 17). Notes: docs/plans/3d-spike-1R-results.md
#if DEBUG
import RealityKit
import SwiftUI
import UIKit

/// Keeps the per-frame subscription alive for as long as the host view lives.
@MainActor
final class Spike3DFrameHook {
    var subscription: Any?  // EventSubscription (RealityView) or Cancellable (ARView); held, never read
}

/// iOS 18+: SwiftUI `RealityView` with `.virtual` camera, driven by the scene's PerspectiveCamera entity.
@available(iOS 18.0, *)
struct Spike3DRealityHost: View {
    let world: Spike3DWorld
    @State private var hook = Spike3DFrameHook()

    var body: some View {
        RealityView { content in
            content.camera = .virtual
            content.add(world.root)
            let world = world
            hook.subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                let dt = event.deltaTime
                MainActor.assumeIsolated { world.update(dt: dt) }
            }
        }
    }
}

/// iOS 17 route: UIKit `ARView` in non-AR mode. `cap` uses ARView's only frame-rate knob (an underscored property).
struct Spike3DARHost: UIViewRepresentable {
    let world: Spike3DWorld
    let capTo: Float?

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(red: 0.42, green: 0.36, blue: 0.30, alpha: 1))
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(world.root)
        view.scene.addAnchor(anchor)
        let world = world
        context.coordinator.subscription = view.scene.subscribe(to: SceneEvents.Update.self) { event in
            let dt = event.deltaTime
            MainActor.assumeIsolated { world.update(dt: dt) }
        }
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        view.__preferredFrameRate = capTo ?? 0
        view.__enableAutomaticFrameRate = capTo == nil
    }

    func makeCoordinator() -> Spike3DFrameHook { Spike3DFrameHook() }
}
#endif
