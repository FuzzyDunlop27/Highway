// Purpose: Keeps one animated 3D zombie per zombie in Core state: glides, turns, walks/attacks/stands, removes the gone. Notes: docs/features/characters-3d.md
import RealityKit
import HoldoutCore

/// Zombies are the animated walker model (3M; runner/brute = scaled, tinted walker via presentation.json variants), or
/// labeled boxes when the model is missing. They stand spread out a little (crowdOffset) so packs don't stack, glide
/// between Core's ticks and turn smoothly (CharacterMotion3D), and the walk cycle runs at drawn speed ÷ stride.
@MainActor
final class ZombieLayer3D {
    let root = Entity()
    private struct Drawn {
        let entity: Entity
        let artId: String
        var motion: CharacterMotion3D
        var animator = CharacterAnimator3D()
    }
    private var drawn: [ZombieID: Drawn] = [:]
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

    /// `seconds` = real time since the last frame; `gameSpeed` = 0 (paused), 1 or 2.
    func sync(loop: GameLoop, mapping: WorldMapping3D, settings: Reality3DDef, registry: ModelRegistry,
              seconds: Double, gameSpeed: Double) {
        if sprites.isEmpty {
            sprites = Dictionary(loop.content.zombies.zombies.map { ($0.id, $0.sprite) }, uniquingKeysWith: { first, _ in first })
        }
        let c = settings.characters
        let zombies = loop.state.base.zombies
        var seen = Set<ZombieID>(minimumCapacity: zombies.count)
        let box = settings.zombieBoxTiles
        let size = SIMD3<Float>(Float(box.width), Float(box.height), Float(box.width)) * Float(settings.metresPerTile)
        for zombie in zombies {
            seen.insert(zombie.id)
            let gx = zombie.x + Self.crowdOffset(zombie.id, salt: 0.618)
            let gy = zombie.y + Self.crowdOffset(zombie.id, salt: 0.414)
            var d: Drawn
            if let existing = drawn[zombie.id] {
                d = existing
                d.motion.update(toX: gx, y: gy, heading: zombie.heading, seconds: seconds, settings: c)
            } else {
                let artId = sprites[zombie.defId] ?? zombie.defId
                let entity = registry.entity(artId, size: size, labelMinWidth: Self.labelMinWidth)
                root.addChild(entity)
                d = Drawn(entity: entity, artId: artId, motion: CharacterMotion3D(x: gx, y: gy, heading: zombie.heading, settings: c))
            }
            d.entity.position = Reality3DSizes.vector(mapping.world(gx: d.motion.x, gy: d.motion.y))
            d.entity.orientation = simd_quatf(angle: Float(WorldMapping3D.yaw(heading: d.motion.heading)), axis: [0, 1, 0])
            let clip = d.motion.clip(attacking: zombie.attacking != nil)
            d.animator.update(d.entity, artId: d.artId, clip: clip, rate: rate(clip, d, gameSpeed: gameSpeed, c, registry),
                              phase: Self.crowdOffset(zombie.id, salt: 0.732) / Self.crowdSpreadTiles + 0.5, blendSeconds: c.clipBlendSeconds, registry: registry)
            drawn[zombie.id] = d
        }
        guard drawn.count != seen.count else { return }
        for id in drawn.keys where !seen.contains(id) {
            drawn.removeValue(forKey: id)?.entity.removeFromParent()
        }
    }

    /// Walk: one loop per stride at the drawn speed (no foot sliding). Attack/idle: as authored, times the game speed.
    private func rate(_ clip: CharacterClip3D, _ d: Drawn, gameSpeed: Double, _ c: Characters3DDef,
                      _ registry: ModelRegistry) -> Double {
        guard clip == .walk, let stride = registry.strideTiles(d.artId),
              let cycle = registry.clipSeconds(d.artId, .walk) else { return gameSpeed }
        return CharacterMotion3D.walkRate(speedTiles: d.motion.speed, strideTiles: stride, cycleSeconds: cycle,
                                          maxRate: c.maxWalkRate)
    }
}
