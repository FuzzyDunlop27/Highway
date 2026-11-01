// Purpose: Puts an aiming turret on top of each finished tower (watchtower gunner, MG nest gun) and turns it toward what it shoots. Notes: docs/features/rendering-art.md
import RealityKit
import HoldoutCore

/// A tower's `turretSprite` (buildings.json) is its own model, built like every 2M model (origin at the footprint's
/// ground middle, gun pointing +X, already at platform height), hung under the tower's entity so it fades and shakes
/// with it. Missing model → a labeled box sitting on the tower's box. Each shot turns the turret toward the target at a
/// capped speed; between shots it keeps its last aim, also when the tower's entity is rebuilt (level up).
@MainActor
final class TurretLayer3D {
    private struct Turret {
        let entity: Entity
        /// Muzzle in the turret's own (unturned) space; measured once the real model is in.
        var muzzle: SIMD3<Float>?
        var placeholderMuzzle: SIMD3<Float>
    }
    private var turrets: [BuildingID: Turret] = [:]
    /// Drawn and wanted aim per tower (radians about +Y, 0 = +X/east), kept across rebuilds.
    private var yaw: [BuildingID: Double] = [:], goal: [BuildingID: Double] = [:]

    // Look only.
    private static let turnRadiansPerSecond = 10.0
    /// Placeholder turret box in tiles (long along the gun).
    private static let boxTiles: SIMD3<Float> = [0.7, 0.2, 0.25]
    static let turretName = "turret"
    /// Optional empty in a turret model marking the barrel's tip (tools/blender/recipes_defenses.py).
    static let muzzleName = "muzzle"

    func sync(loop: GameLoop, buildings: BuildingLayer3D, settings: Reality3DDef, registry: ModelRegistry, seconds: Double) {
        var live = Set<BuildingID>()
        for b in loop.state.base.buildings {
            guard let def = loop.content.buildingDef(b.defId), let artId = def.turretSprite else { continue }
            guard b.isComplete, let parent = buildings.entity(for: b.id) else { continue }
            live.insert(b.id)
            if turrets[b.id]?.entity.parent !== parent {
                turrets[b.id]?.entity.removeFromParent()
                let m = Float(settings.metresPerTile)
                let lift = Reality3DSizes.height(category: def.category, settings: settings)
                let size = Self.boxTiles * m
                let entity = registry.entity(artId, size: size, lift: lift)
                entity.name = Self.turretName
                parent.addChild(entity)
                turrets[b.id] = Turret(entity: entity, placeholderMuzzle: [size.x / 2, lift + size.y / 2, 0])
            }
            let current = yaw[b.id] ?? 0
            let next = CharacterMotion3D.turn(current, toward: goal[b.id] ?? current, maxStep: Self.turnRadiansPerSecond * seconds)
            yaw[b.id] = next
            turrets[b.id]?.entity.orientation = simd_quatf(angle: Float(next), axis: [0, 1, 0])
        }
        guard turrets.count != live.count else { return }
        for id in turrets.keys where !live.contains(id) {
            turrets.removeValue(forKey: id)?.entity.removeFromParent()
        }
        yaw = yaw.filter { live.contains($0.key) }
        goal = goal.filter { live.contains($0.key) }
    }

    /// Aims tower `id` at `target` (world metres) and returns where its tracer starts: the muzzle as it will be once
    /// turned (the turret catches up within a frame or two). Nil when the tower has no turret drawn.
    func fire(_ id: BuildingID, at target: SIMD3<Float>) -> SIMD3<Float>? {
        guard var t = turrets[id], let parent = t.entity.parent else { return nil }
        let pivot = parent.position(relativeTo: nil)
        let aim = Double(atan2(-(target.z - pivot.z), target.x - pivot.x))
        goal[id] = aim
        if t.muzzle == nil, t.entity.children.contains(where: { $0.name == ModelRegistry.modelName }) {
            t.muzzle = t.entity.findEntity(named: Self.muzzleName)?.position(relativeTo: t.entity) ?? Self.boundsMuzzle(t.entity)
            turrets[id] = t
        }
        let local = simd_quatf(angle: Float(aim), axis: [0, 1, 0]).act(t.muzzle ?? t.placeholderMuzzle)
        return parent.convert(position: local, to: nil)
    }

    /// No muzzle marker: the front of the model, two-thirds of the way up.
    private static func boundsMuzzle(_ e: Entity) -> SIMD3<Float> {
        let b = e.visualBounds(relativeTo: e)
        return [b.max.x, b.min.y + (b.max.y - b.min.y) * 0.66, 0]
    }
}
