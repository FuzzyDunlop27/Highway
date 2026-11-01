// Purpose: Defenders in a fight: hold-spot shooting, zombies hurting them, knock-out and return. Notes: docs/features/jobs-defenders.md
import Foundation

enum DefenderCombat {
    /// Tower damage multiplier when a defender is garrisoned inside (units.json garrison.towerDamageMultiplier).
    static func towerDamageMultiplier(_ state: GameState, content: GameContent, towerId: BuildingID) -> Double {
        guard state.base.defenders.contains(where: { $0.garrisonedIn == towerId }),
              let rule = content.units.units.compactMap(\.garrison).first else { return 1 }
        return rule.towerDamageMultiplier
    }

    /// Counts down knock-outs (back at the HQ with full hp when done), lets zombies hurt defenders holding a spot,
    /// and lets those defenders shoot. Garrisoned defenders are safe inside their tower.
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard !state.base.defenders.isEmpty, let unit = content.units.units.first(where: { $0.id == "defender" }) else { return }
        let tps = content.economy.ticksPerSecond
        let zombieDefs = Dictionary(content.zombies.zombies.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for i in state.base.defenders.indices {
            var d = state.base.defenders[i]
            if case .knockedOut(let left) = d.post {
                if left <= 1 {
                    d.post = .hq
                    d.hp = unit.hp
                    events.append(.defenderReady(d.id))
                } else {
                    d.post = .knockedOut(ticksLeft: left - 1)
                }
            } else if case .hold(let tile) = d.post {
                let spot = (x: Double(tile.x) + 0.5, y: Double(tile.y) + 0.5)
                hurt(&d, at: spot, state: state, zombieDefs: zombieDefs, tick: state.tick, tps: tps)
                if d.hp <= 0 {
                    d.hp = 0
                    d.post = .knockedOut(ticksLeft: max(1, content.ticks(forSeconds: content.units.knockedOutSeconds)))
                    events.append(.defenderKnockedOut(d.id))
                } else {
                    shoot(d, at: spot, unit: unit, state: &state, tps: tps, events: &events)
                }
            }
            state.base.defenders[i] = d
        }
    }

    /// Every living zombie within its `attackRange` of the defender deals `damageVsUnitsPerSec`.
    private static func hurt(_ d: inout Defender, at spot: (x: Double, y: Double), state: GameState,
                             zombieDefs: [String: ZombieDef], tick: Int, tps: Int) {
        for z in state.base.zombies where z.hp > 0 {
            guard let def = zombieDefs[z.defId] else { continue }
            let dx = z.x - spot.x, dy = z.y - spot.y
            guard dx * dx + dy * dy <= def.attackRange * def.attackRange else { continue }
            d.hp -= ZombieClock(tick: tick, zombieID: z.id, ticksPerSecond: tps).wholeAmount(perSecond: def.damageVsUnitsPerSec)
        }
    }

    /// Hitscan at the nearest zombie in range (lower id breaks ties), on the same staggered rhythm as towers.
    private static func shoot(_ d: Defender, at spot: (x: Double, y: Double), unit: UnitDef, state: inout GameState,
                              tps: Int, events: inout [SimEvent]) {
        guard let range = unit.range, let damage = unit.damage, let fireRate = unit.fireRate,
              TowerFiring.isShotTick(tick: state.tick, towerID: d.id, fireRate: fireRate, ticksPerSecond: tps) else { return }
        var best: (distSquared: Double, index: Int)?
        for (zi, z) in state.base.zombies.enumerated() where z.hp > 0 {
            let dx = z.x - spot.x, dy = z.y - spot.y
            let dist = dx * dx + dy * dy
            guard dist <= range * range else { continue }
            if let b = best, dist > b.distSquared || (dist == b.distSquared && z.id > state.base.zombies[b.index].id) { continue }
            best = (dist, zi)
        }
        guard let target = best?.index else { return }
        state.base.zombies[target].hp -= damage
        events.append(.defenderShot(from: d.id, at: state.base.zombies[target].id))
    }
}
