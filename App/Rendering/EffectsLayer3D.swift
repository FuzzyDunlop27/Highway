// Purpose: Plays Core's SimEvents as short 3D effects: tracers, muzzle flash, goo, dust, trap flash, building shake. Notes: docs/features/rendering-art.md
import RealityKit
import HoldoutCore

/// The 3D twin of the old 2D EventPlayer (same effects, same caps). `play` runs before the layers sync, so a zombie that
/// died this frame is still drawn where it fell. Effects age in real seconds and remove themselves.
@MainActor
final class EffectsLayer3D {
    let root = Entity()
    /// Goo splats on the ground (oldest removed first) and everything in the air (extra ones skipped).
    private let decals = Entity(), air = Entity()

    private enum Look { case fade, grow }
    private struct Live {
        let entity: Entity
        var age: Double = 0
        let life: Double
        /// Seconds at full strength before fading (goo stays a while).
        var hold: Double = 0
        var look: Look = .fade
        var trap: BuildingID?
    }
    private var airEffects: [Live] = [], decalEffects: [Live] = []
    private var shaking: [BuildingID: (entity: Entity, base: SIMD3<Float>, age: Double)] = [:]
    private var flashingTraps = Set<BuildingID>()

    // Same caps as 2D, so a day-40 horde can't pile up hundreds of entities.
    private static let maxDecals = 60
    private static let maxAirEffects = 80
    // Look only: seconds and metres.
    private static let tracerSeconds = 0.12
    private static let flashSeconds = 0.08
    private static let gooStaySeconds = 4.0
    private static let gooFadeSeconds = 1.5
    private static let dustSeconds = 0.8
    private static let trapFlashSeconds = 0.25
    private static let shakeSeconds = 0.12
    private static let shakeMetres: Float = 0.05

    init() {
        root.name = "effects"
        root.addChild(decals)
        root.addChild(air)
    }

    func play(_ events: [SimEvent], loop: GameLoop, mapping: WorldMapping3D, buildings: BuildingLayer3D,
              zombies: ZombieLayer3D, defenders: DefenderLayer3D, turrets: TurretLayer3D) {
        for event in events {
            switch event {
            case .shot(let from, let target):
                guard let hit = zombies.hitPoint(target) else { continue }
                let muzzle = turrets.fire(from, at: hit) ?? buildingTop(from, loop: loop, mapping: mapping, buildings: buildings)
                guard let muzzle else { continue }
                addAir(Live(entity: EffectMeshes3D.tracer(from: muzzle, to: hit), life: Self.tracerSeconds))
                addAir(Live(entity: EffectMeshes3D.muzzleFlash(at: muzzle), life: Self.flashSeconds))
            case .defenderShot(let from, let target):
                guard let hit = zombies.hitPoint(target), let muzzle = defenders.muzzle(from) else { continue }
                addAir(Live(entity: EffectMeshes3D.tracer(from: muzzle, to: hit), life: Self.tracerSeconds))
            case .trapHit(let trap, _):
                guard !flashingTraps.contains(trap), let b = loop.state.base.building(trap),
                      let def = loop.content.buildingDef(b.defId) else { continue }
                let c = Reality3DSizes.vector(mapping.footprintCenter(origin: b.origin, width: def.width, height: def.height))
                if addAir(Live(entity: EffectMeshes3D.trapFlash(at: c), life: Self.trapFlashSeconds, trap: trap)) {
                    flashingTraps.insert(trap)
                }
            case .zombieDied(let id, _, let x, let y):
                if decalEffects.count >= Self.maxDecals { decalEffects.removeFirst().entity.removeFromParent() }
                let seed = Float((Double(id) * 0.618).truncatingRemainder(dividingBy: 1))
                let goo = EffectMeshes3D.goo(at: Reality3DSizes.vector(mapping.world(gx: x, gy: y)),
                                             stretch: 0.75 + 0.5 * seed, turn: seed * 6.28)
                decals.addChild(goo)
                decalEffects.append(Live(entity: goo, life: Self.gooStaySeconds + Self.gooFadeSeconds, hold: Self.gooStaySeconds))
            case .buildingDamaged(let id):
                guard shaking[id] == nil, let entity = buildings.entity(for: id) else { continue }
                shaking[id] = (entity, entity.position, 0)
            case .buildingDestroyed(let id):
                guard let b = loop.state.base.building(id), let def = loop.content.buildingDef(b.defId) else { continue }
                let c = Reality3DSizes.vector(mapping.footprintCenter(origin: b.origin, width: def.width, height: def.height))
                let width = Float(Double(max(def.width, def.height)) * mapping.metresPerTile) * 1.2
                addAir(Live(entity: EffectMeshes3D.dust(at: c, width: width), life: Self.dustSeconds, look: .grow))
            default:
                break  // horde start/end/warning are banners, the HUD and HordeWarning3D; spawns need no effect
            }
        }
    }

    /// Ages every effect by `seconds` (real time): fades, grows, shakes, and removes the finished ones.
    func update(seconds: Double) {
        age(&airEffects, seconds)
        age(&decalEffects, seconds)
        for (id, s) in shaking {
            let t = s.age + seconds
            if t >= Self.shakeSeconds {
                s.entity.position = s.base
                shaking[id] = nil
            } else {
                s.entity.position = s.base + [Self.shakeMetres * Float(sin(t / Self.shakeSeconds * 3 * 2 * .pi)), 0, 0]
                shaking[id] = (s.entity, s.base, t)
            }
        }
    }

    private func age(_ list: inout [Live], _ seconds: Double) {
        guard !list.isEmpty else { return }
        var kept: [Live] = []
        kept.reserveCapacity(list.count)
        for var e in list {
            e.age += seconds
            if e.age >= e.life {
                e.entity.removeFromParent()
                if let trap = e.trap { flashingTraps.remove(trap) }
                continue
            }
            let fadeT = e.age <= e.hold ? 0 : (e.age - e.hold) / max(e.life - e.hold, 1e-6)
            e.entity.components.set(OpacityComponent(opacity: Float(1 - fadeT)))
            if e.look == .grow { e.entity.scale = .init(repeating: Float(0.6 + 0.6 * fadeT)) }
            kept.append(e)
        }
        list = kept
    }

    @discardableResult
    private func addAir(_ effect: Live) -> Bool {
        guard airEffects.count < Self.maxAirEffects else { return false }
        if effect.look == .grow { effect.entity.scale = .init(repeating: 0.6) }
        air.addChild(effect.entity)
        airEffects.append(effect)
        return true
    }

    /// A tower with no turret drawn yet (still loading or none): shoot from the middle of its roof.
    private func buildingTop(_ id: BuildingID, loop: GameLoop, mapping: WorldMapping3D, buildings: BuildingLayer3D) -> SIMD3<Float>? {
        guard let b = loop.state.base.building(id), let def = loop.content.buildingDef(b.defId),
              let top = buildings.topHeight(id) else { return nil }
        var c = Reality3DSizes.vector(mapping.footprintCenter(origin: b.origin, width: def.width, height: def.height))
        c.y = top
        return c
    }
}
