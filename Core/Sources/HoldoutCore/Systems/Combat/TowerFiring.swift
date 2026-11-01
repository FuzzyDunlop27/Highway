// Purpose: Staffed towers fire at their target at their fire rate (hitscan damage). Notes: docs/features/combat.md
import Foundation

enum TowerFiring {
    /// Path weight of the field used to rank zombies by "closest to the HQ": the plain field
    /// (no extra wall avoidance), not a tuning number. Zombie types' own weights live in zombies.json.
    static let hqDistanceFieldWeight = 1.0

    /// Every finished, staffed tower whose turn it is this tick shoots one zombie in range.
    /// Damage is applied at once (hitscan); hp may go below 0 and HordeResolution removes the dead.
    static func tick(_ state: inout GameState, content: GameContent, fields: FlowFieldCache, events: inout [SimEvent]) {
        guard !state.base.zombies.isEmpty else { return }
        var field: FlowField?   // fetched once, only if a nearest-to-HQ tower shoots this tick
        for i in state.base.buildings.indices {
            let tower = state.base.buildings[i]
            guard let def = content.buildingDef(tower.defId),
                  let effects = def.level(tower.level)?.effects,
                  let baseRange = effects.range, let damage = effects.damage, let fireRate = effects.fireRate,
                  canFire(tower, def: def),
                  isShotTick(tick: state.tick, towerID: tower.id, fireRate: fireRate,
                             ticksPerSecond: content.economy.ticksPerSecond) else { continue }
            let range = baseRange + ResearchEffects.towerRangeBonus(defId: def.id, knowledge: state.group.knowledge, content: content)
            if field == nil, TargetingMode(def.targeting) == .nearestToHQ {
                field = fields.field(weight: hqDistanceFieldWeight, state: state, content: content)
            }
            let targetID = TargetingSystem.target(for: tower, def: def, range: range, zombies: state.base.zombies) { tile in
                field?.distance(at: tile) ?? .infinity
            }
            guard let targetID, let z = state.base.zombies.firstIndex(where: { $0.id == targetID }) else { continue }
            let boosted = damage * DefenderCombat.towerDamageMultiplier(state, content: content, towerId: tower.id)
            state.base.zombies[z].hp -= boosted
            events.append(.shot(from: tower.id, at: targetID))
        }
    }

    /// A tower works only when finished (not building, not rubble) and fully staffed.
    /// A garrisoned defender counts as the worker (Staffing adds it to `staffed`).
    static func canFire(_ tower: Building, def: BuildingDef) -> Bool {
        tower.isComplete && tower.staffed >= def.workers
    }

    /// Ticks between shots: ticksPerSecond / fireRate, rounded, at least 1.
    static func ticksPerShot(fireRate: Double, ticksPerSecond: Int) -> Int {
        max(1, Int((Double(ticksPerSecond) / fireRate).rounded()))
    }

    /// Whether the tower shoots this tick. Derived from the tick and the tower id (no saved
    /// cooldown), so towers are staggered, deterministic, and unaffected by save/load (combat.md).
    static func isShotTick(tick: Int, towerID: BuildingID, fireRate: Double, ticksPerSecond: Int) -> Bool {
        guard fireRate > 0 else { return false }
        return (tick + towerID) % ticksPerShot(fireRate: fireRate, ticksPerSecond: ticksPerSecond) == 0
    }
}
