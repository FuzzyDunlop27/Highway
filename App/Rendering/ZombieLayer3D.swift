// Purpose: Keeps one 3D entity per zombie in Core state: adds new ones, moves and turns them every frame, removes the gone. Notes: docs/features/rendering-art.md
import RealityKit
import HoldoutCore

/// The 3D twin of `ZombieLayer`. Zombies are labeled boxes until chunk 3M brings the animated walker; they stand at the
/// spread out a little (crowdOffset) so packs don't stack, and turn to face their heading.
@MainActor
final class ZombieLayer3D {
    let root = Entity()
    private var entities: [ZombieID: Entity] = [:]
    private var sprites: [String: String] = [:]
    /// Look-only: zombie labels may be wider than the thin box so they stay readable.
    private static let labelMinWidth: Float = 0.8
    /// Look-only: how far (tiles) a zombie may be drawn off its Core position, so a horde reads as a crowd.
    private static let crowdSpreadTiles = 0.35

    /// A fixed offset per zombie in -spread/2...spread/2 (golden-ratio hash of the id; same every frame).
    private static func crowdOffset(_ id: ZombieID, salt: Double) -> Double {
        let f = (Double(id) * salt + salt).truncatingRemainder(dividingBy: 1)
        return (f - 0.5) * crowdSpreadTiles
    }

    init() { root.name = "zombies" }

    func sync(loop: GameLoop, mapping: WorldMapping3D, settings: Reality3DDef, registry: ModelRegistry) {
        if sprites.isEmpty {
            sprites = Dictionary(loop.content.zombies.zombies.map { ($0.id, $0.sprite) }, uniquingKeysWith: { first, _ in first })
        }
        let zombies = loop.state.base.zombies
        var seen = Set<ZombieID>(minimumCapacity: zombies.count)
        let box = settings.zombieBoxTiles
        let size = SIMD3<Float>(Float(box.width), Float(box.height), Float(box.width)) * Float(settings.metresPerTile)
        for zombie in zombies {
            seen.insert(zombie.id)
            let entity: Entity
            if let existing = entities[zombie.id] {
                entity = existing
            } else {
                entity = registry.entity(sprites[zombie.defId] ?? zombie.defId, size: size, labelMinWidth: Self.labelMinWidth)
                root.addChild(entity)
                entities[zombie.id] = entity
            }
            let gx = zombie.x + Self.crowdOffset(zombie.id, salt: 0.618)
            let gy = zombie.y + Self.crowdOffset(zombie.id, salt: 0.414)
            entity.position = Reality3DSizes.vector(mapping.world(gx: gx, gy: gy))
            entity.orientation = simd_quatf(angle: Float(WorldMapping3D.yaw(heading: zombie.heading)), axis: [0, 1, 0])
        }
        guard entities.count != seen.count else { return }
        for id in entities.keys where !seen.contains(id) {
            entities.removeValue(forKey: id)?.removeFromParent()
        }
    }
}
