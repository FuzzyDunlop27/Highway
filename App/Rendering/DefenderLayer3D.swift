// Purpose: Keeps one 3D entity per defender: beside the HQ, on its tower, or on its held spot; hidden while knocked out. Notes: docs/features/characters-3d.md
import RealityKit
import HoldoutCore

/// Defenders are labeled boxes until a `unit_defender.usdz` exists (tools/blender/export_characters.py); then they play
/// its idle clip. They face the same way always (no directions yet).
@MainActor
final class DefenderLayer3D {
    let root = Entity()
    private var entities: [DefenderID: Entity] = [:]
    private var animators: [DefenderID: CharacterAnimator3D] = [:]
    /// Look-only: how far (tiles) waiting defenders stand below the HQ, and the gap between them.
    private static let hqRowOffsetTiles = 0.6
    private static let hqRowSpacingTiles = 0.7

    init() { root.name = "defenders" }

    func sync(loop: GameLoop, mapping: WorldMapping3D, settings: Reality3DDef, registry: ModelRegistry, gameSpeed: Double) {
        let defenders = loop.state.base.defenders
        let sprite = loop.content.units.units.first { $0.id == "defender" }?.sprite ?? "unit_defender"
        let box = settings.zombieBoxTiles
        let size = SIMD3<Float>(Float(box.width), Float(box.height), Float(box.width)) * Float(settings.metresPerTile)
        var waiting = 0
        for d in defenders {
            guard let spot = position(of: d, loop: loop, waitingIndex: &waiting) else {
                entities[d.id]?.isEnabled = false
                continue
            }
            let entity: Entity
            if let existing = entities[d.id] {
                entity = existing
            } else {
                entity = registry.entity(sprite, size: size, labelMinWidth: 0.8)
                root.addChild(entity)
                entities[d.id] = entity
            }
            entity.isEnabled = true
            entity.position = Reality3DSizes.vector(mapping.world(gx: spot.x, gy: spot.y))
            animators[d.id, default: CharacterAnimator3D()].update(entity, artId: sprite, clip: .idle, rate: gameSpeed,
                                                                   blendSeconds: settings.characters.clipBlendSeconds,
                                                                   registry: registry)
        }
        let live = Set(defenders.map(\.id))
        for id in entities.keys where !live.contains(id) {
            entities.removeValue(forKey: id)?.removeFromParent()
            animators.removeValue(forKey: id)
        }
    }

    /// Where the defender stands in tile coordinates, or nil when it isn't on the map (knocked out).
    private func position(of d: Defender, loop: GameLoop, waitingIndex: inout Int) -> (x: Double, y: Double)? {
        switch d.post {
        case .knockedOut:
            return nil
        case .hold(let tile):
            return (Double(tile.x) + 0.5, Double(tile.y) + 0.5)
        case .garrison(let id):
            guard let b = loop.state.base.building(id), let def = loop.content.buildingDef(b.defId) else { return nil }
            let c = TargetingSystemCenter.of(b, def: def)
            return (c.x, c.y)
        case .hq:
            guard let hq = loop.state.base.buildings.first(where: { $0.defId == "hq" }),
                  let def = loop.content.buildingDef("hq") else { return nil }
            defer { waitingIndex += 1 }
            return (Double(hq.origin.x) + Double(waitingIndex) * Self.hqRowSpacingTiles + 0.5,
                    Double(hq.origin.y + def.height) + Self.hqRowOffsetTiles)
        }
    }
}

/// Middle of a building's footprint in tiles (Core's targeting helper is internal to Core).
enum TargetingSystemCenter {
    static func of(_ b: Building, def: BuildingDef) -> (x: Double, y: Double) {
        (Double(b.origin.x) + Double(def.width) / 2, Double(b.origin.y) + Double(def.height) / 2)
    }
}
