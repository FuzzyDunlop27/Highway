// Purpose: 3D map touches for building: tap to select/place, drag the ghost (lifted above the finger), draw a wall line. Notes: docs/features/input.md
import UIKit
import HoldoutCore

/// Turns a finger into a ray from the camera (Core `OrbitCamera3D.ray`): the ground tile it reaches and the building
/// box it hits first (a tall roof in front wins, like the old isometric rule). Every change goes through GameStore /
/// PlacementController; this never touches game state itself.
@MainActor
final class PlacementTouches3D {
    /// Look-only: while dragging, the ghost sits this many screen points above the finger so the finger never hides it.
    static let dragLiftPoints: CGFloat = 56

    private var isDraggingGhost = false
    private var lineDragStart: GridPoint?

    // MARK: What is under the finger

    private func ray(_ point: CGPoint, in view: UIView, world: World3D) -> Ray3D? {
        world.orbit.ray(screenX: point.x, screenY: point.y, viewWidth: view.bounds.width, viewHeight: view.bounds.height)
    }

    /// The tile under a screen point (may be off the map; callers and PlacementController clamp), nil for sky.
    func groundTile(_ point: CGPoint, in view: UIView, world: World3D) -> GridPoint? {
        guard let hit = ray(point, in: view, world: world)?.groundHit else { return nil }
        return world.mapping.tile(x: hit.x, z: hit.z)
    }

    /// The building whose box the finger's ray hits first.
    func building(_ point: CGPoint, in view: UIView, world: World3D) -> BuildingID? {
        guard let ray = ray(point, in: view, world: world) else { return nil }
        return RayPicking3D.nearest(ray, boxes: world.buildings.pickBoxes(mapping: world.mapping))
    }

    // MARK: Gestures

    /// Tap: select the building under the finger (roof first), move the ghost, or plan a one-wall line.
    func tap(at point: CGPoint, in view: UIView, world: World3D) {
        let store = world.store
        let hit = store.placement.isPositioning || store.placement.isDrawingLine ? nil : building(point, in: view, world: world)
        guard let tile = groundTile(point, in: view, world: world) ?? hit.flatMap({ store.loop?.state.base.building($0)?.origin })
        else { return }
        store.tapped(tile: tile, drawnBuilding: hit)
    }

    /// One-finger drag. Returns true when it moved the ghost or drew a wall line; false means "pan the camera".
    func pan(_ g: UIPanGestureRecognizer, world: World3D) -> Bool {
        guard let view = g.view, let loop = world.store.loop else { return false }
        let placement = world.store.placement
        let location = g.location(in: view)
        let t = g.translation(in: view)
        let start = CGPoint(x: location.x - t.x, y: location.y - t.y)
        if placement.isDrawingLine {
            switch g.state {
            case .began:
                lineDragStart = groundTile(start, in: view, world: world)
                fallthrough
            case .changed:
                if let s = lineDragStart, let e = groundTile(location, in: view, world: world) {
                    placement.setLine(from: s, to: e, loop: loop)
                }
            default:
                lineDragStart = nil
            }
            return true
        }
        switch g.state {
        case .began:
            isDraggingGhost = placement.isPositioning && startsOnGhost(start, in: view, world: world, loop: loop)
            fallthrough
        case .changed:
            guard isDraggingGhost else { return false }
            let lifted = CGPoint(x: location.x, y: location.y - Self.dragLiftPoints)
            if let tile = groundTile(lifted, in: view, world: world) { placement.moveGhost(centeredOn: tile, loop: loop) }
            return true
        default:
            defer { isDraggingGhost = false }
            return isDraggingGhost
        }
    }

    /// A drag moves the ghost if it starts on the ghost's tiles or on the ghost itself (its box above the ground).
    private func startsOnGhost(_ point: CGPoint, in view: UIView, world: World3D, loop: GameLoop) -> Bool {
        if let tile = groundTile(point, in: view, world: world), world.store.placement.ghostCovers(tile, loop: loop) { return true }
        guard let box = world.placement.ghostBox, let ray = ray(point, in: view, world: world) else { return false }
        return RayPicking3D.hitDistance(ray, box) != nil
    }
}
