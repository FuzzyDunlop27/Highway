// Purpose: 3D map touches: one finger pans (or drags the ghost / draws walls), tap, pinch zoom, twist snaps 90°, two fingers tilt. Notes: docs/features/input.md
import SwiftUI
import UIKit

/// A clear UIKit layer over the RealityView that turns touches into `OrbitCamera3D` moves (all limits live there).
/// Taps and one-finger drags that are about building go to `PlacementTouches3D` first. In the wall tool one finger
/// draws, so two fingers pan the map instead of tilting.
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
        let tap = UITapGestureRecognizer(target: c, action: #selector(Coordinator.tap(_:)))
        for g in [pan, tilt, pinch, twist, tap] as [UIGestureRecognizer] {
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
        private let building = PlacementTouches3D()

        init(world: World3D) { self.world = world }

        func resized(_ size: CGSize) {
            guard size.width > 0, size.height > 0 else { return }
            world.orbit.setViewAspect(size.width / size.height)
            world.applyCamera()
        }

        @objc func tap(_ g: UITapGestureRecognizer) {
            guard let view = g.view else { return }
            building.tap(at: g.location(in: view), in: view, world: world)
        }

        @objc func pan(_ g: UIPanGestureRecognizer) {
            guard let view = g.view, !building.pan(g, world: world) else { return }
            let d = g.translation(in: view)
            world.orbit.pan(dx: d.x, dy: d.y, viewHeight: view.bounds.height)
            g.setTranslation(.zero, in: view)
            world.applyCamera()
        }

        @objc func tilt(_ g: UIPanGestureRecognizer) {
            guard let view = g.view else { return }
            let d = g.translation(in: view)
            if world.store.placement.isDrawingLine {
                world.orbit.pan(dx: d.x, dy: d.y, viewHeight: view.bounds.height)
            } else {
                world.orbit.tilt(dy: d.y)
            }
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
