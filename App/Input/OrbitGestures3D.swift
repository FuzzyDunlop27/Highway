// Purpose: 3D camera touches: one finger pans, pinch zooms toward the fingers, two-finger twist snaps 90°, two-finger drag tilts. Notes: docs/features/input.md
import SwiftUI
import UIKit

/// A clear UIKit layer over the RealityView that turns touches into `OrbitCamera3D` moves (all limits live there).
/// Taps do nothing yet: selecting and placing in 3D is chunk 3R.
struct OrbitGestures3D: UIViewRepresentable {
    let world: World3D

    func makeUIView(context: Context) -> Surface {
        let view = Surface()
        view.backgroundColor = .clear
        let c = context.coordinator
        view.onResize = { [weak c] size in c?.resized(size) }
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

    func updateUIView(_ uiView: Surface, context: Context) { context.coordinator.world = world }

    func makeCoordinator() -> Coordinator { Coordinator(world: world) }

    /// Reports its size so the camera knows the screen shape (zoom-out limit, finger → ground math).
    final class Surface: UIView {
        var onResize: ((CGSize) -> Void)?
        override func layoutSubviews() {
            super.layoutSubviews()
            onResize?(bounds.size)
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var world: World3D

        init(world: World3D) { self.world = world }

        func resized(_ size: CGSize) {
            guard size.width > 0, size.height > 0 else { return }
            world.orbit.setViewAspect(size.width / size.height)
            world.applyCamera()
        }

        @objc func pan(_ g: UIPanGestureRecognizer) {
            guard let view = g.view else { return }
            let d = g.translation(in: view)
            world.orbit.pan(dx: d.x, dy: d.y, viewHeight: view.bounds.height)
            g.setTranslation(.zero, in: view)
            world.applyCamera()
        }

        @objc func tilt(_ g: UIPanGestureRecognizer) {
            guard let view = g.view else { return }
            world.orbit.tilt(dy: g.translation(in: view).y)
            g.setTranslation(.zero, in: view)
            world.applyCamera()
        }

        @objc func pinch(_ g: UIPinchGestureRecognizer) {
            guard let view = g.view, g.state == .changed || g.state == .began else { return }
            let p = g.location(in: view)
            let ground = world.orbit.groundPoint(screenX: p.x, screenY: p.y,
                                                 viewWidth: view.bounds.width, viewHeight: view.bounds.height)
            world.orbit.zoom(by: g.scale, toward: ground)
            g.scale = 1
            world.applyCamera()
        }

        /// UIKit's rotation is positive clockwise; past the threshold the camera swings one snap angle (D-029).
        @objc func twist(_ g: UIRotationGestureRecognizer) {
            switch g.state {
            case .began, .changed:
                world.orbit.twist(by: g.rotation)
                g.rotation = 0
            default:
                world.orbit.endTwist()
            }
        }

        nonisolated func gestureRecognizer(_ g: UIGestureRecognizer,
                                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}
