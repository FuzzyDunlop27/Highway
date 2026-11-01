// Purpose: While placing/moving, fades buildings standing between the camera and the ghost; restores them after. Notes: docs/features/input.md
import RealityKit
import HoldoutCore

/// Presentation only: nothing in Core changes. Works from any camera angle because it casts rays from the camera to
/// points on the ghost (Core `RayPicking3D.occluders`). No fading in the wall tool (walls are low).
@MainActor
final class OccluderFader3D {
    /// Look-only: how see-through a building in front of the ghost becomes.
    static let fadedOpacity: Float = 0.3
    /// Look-only: aim the rays a little inside the ghost so a building merely beside it doesn't count.
    private static let ghostInset = 0.12

    /// Faded entities and the opacity each had before (nil = none), to put back exactly.
    private var faded: [BuildingID: (entity: Entity, before: OpacityComponent?)] = [:]

    func sync(ghost: Box3D?, eye: WorldMapping3D.Point3, buildings: BuildingLayer3D, mapping: WorldMapping3D) {
        var now = Set<BuildingID>()
        if let ghost {
            let inner = ghost.inset(Self.ghostInset)
            now = RayPicking3D.occluders(eye: eye, targets: inner.corners + [inner.center], boxes: buildings.pickBoxes(mapping: mapping))
        }
        for (id, entry) in faded where !now.contains(id) {
            restore(entry)
            faded[id] = nil
        }
        for id in now {
            guard let entity = buildings.entity(for: id) else { continue }
            if let old = faded[id] {
                if old.entity === entity { continue }
                faded[id] = nil  // the building was rebuilt (finished, damaged…): its new entity starts unfaded
            }
            let before = entity.components[OpacityComponent.self]
            entity.components.set(OpacityComponent(opacity: min(Self.fadedOpacity, before?.opacity ?? 1)))
            faded[id] = (entity, before)
        }
    }

    private func restore(_ entry: (entity: Entity, before: OpacityComponent?)) {
        if let before = entry.before {
            entry.entity.components.set(before)
        } else {
            entry.entity.components.remove(OpacityComponent.self)
        }
    }
}
