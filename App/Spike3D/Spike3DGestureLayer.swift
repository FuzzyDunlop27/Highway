// Purpose: Spike orbit-camera touches: one-finger pan, pinch zoom, two-finger twist, two-finger vertical drag tilts. Notes: docs/plans/3d-spike-1R-results.md
#if DEBUG
import SwiftUI
import UIKit

struct Spike3DGestureLayer: UIViewRepresentable {
    let world: Spike3DWorld

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let c = context.coordinator
        let pan = UIPanGestureRecognizer(target: c, action: #selector(Coordinator.pan(_:)))
        pan.maximumNumberOfTouches = 1
        let tilt = UIPanGestureRecognizer(target: c, action: #selector(Coordinator.tilt(_:)))
        tilt.minimumNumberOfTouches = 2
        let pinch = UIPinchGestureRecognizer(target: c, action: #selector(Coordinator.pinch(_:)))
        let twist = UIRotationGestureRecognizer(target: c, action: #selector(Coordinator.twist(_:)))
        for g in [pan, tilt, pinch, twist] as [UIGestureRecognizer] {
            g.delegate = c
            view.addGestureRecognizer(g)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { context.coordinator.world = world }

    func makeCoordinator() -> Coordinator { Coordinator(world: world) }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var world: Spike3DWorld

        init(world: Spike3DWorld) { self.world = world }

        @objc func pan(_ g: UIPanGestureRecognizer) {
            guard let view = g.view else { return }
            let d = g.translation(in: view)
            world.orbit.pan(dx: Float(d.x), dy: Float(d.y), viewHeight: Float(view.bounds.height))
            g.setTranslation(.zero, in: view)
            world.applyCamera()
        }

        @objc func tilt(_ g: UIPanGestureRecognizer) {
            guard let view = g.view else { return }
            world.orbit.tilt(dy: Float(g.translation(in: view).y))
            g.setTranslation(.zero, in: view)
            world.applyCamera()
        }

        @objc func pinch(_ g: UIPinchGestureRecognizer) {
            world.orbit.zoom(by: Float(g.scale))
            g.scale = 1
            world.applyCamera()
        }

        @objc func twist(_ g: UIRotationGestureRecognizer) {
            world.orbit.twist(by: -Float(g.rotation))
            g.rotation = 0
            world.applyCamera()
        }

        nonisolated func gestureRecognizer(_ g: UIGestureRecognizer,
                                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}
#endif
