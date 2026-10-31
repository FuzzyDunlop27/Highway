// Purpose: After combat each tick: remove dead zombies (loot), turn 0-hp buildings to rubble, HQ fall, horde end. Notes: docs/features/hordes.md
import Foundation

/// Runs every tick after movement and towers. Order: dead zombies → destroyed buildings (HQ fall) → horde held.
enum HordeResolution {
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        removeDeadZombies(&state, content: content, events: &events)
        let hqFell = resolveDestroyedBuildings(&state, events: &events)
        if hqFell { HordeOutcome.hqFall(&state, content: content, events: &events) }
        if let active = state.base.horde.active, active.spawnQueue.isEmpty, state.base.zombies.isEmpty {
            HordeOutcome.held(&state, content: content, events: &events)
        }
    }

    /// Zombies at 0 hp or less drop zombies.json `loot` × the horde's loot multiplier (rounded down, clamped to caps).
    static func removeDeadZombies(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard state.base.zombies.contains(where: { $0.hp <= 0 }) else { return }
        let multiplier = state.base.horde.active?.lootMultiplier ?? 1
        var loot = Cost.zero
        for z in state.base.zombies where z.hp <= 0 {
            if let def = content.zombies.zombies.first(where: { $0.id == z.defId }) {
                loot = loot + Cost(scrap: Int((Double(def.loot.scrap) * multiplier).rounded(.down)),
                                   food: Int((Double(def.loot.food) * multiplier).rounded(.down)))
            }
            state.base.horde.active?.killed += 1
            events.append(.zombieDied(z.id, defId: z.defId, x: z.x, y: z.y))
        }
        state.base.zombies.removeAll { $0.hp <= 0 }
        state.base.stock = state.base.stock + loot
        StorageRules.clampToCaps(&state.base, content: content)
    }

    /// Non-HQ buildings at 0 hp become rubble (unstaffed, blocks and does nothing until rebuilt).
    /// Returns true if the HQ is at 0 hp (the caller runs the HQ fall).
    static func resolveDestroyedBuildings(_ state: inout GameState, events: inout [SimEvent]) -> Bool {
        var hqFell = false
        for i in state.base.buildings.indices {
            let b = state.base.buildings[i]
            guard b.hp <= 0, !b.isRubble else { continue }
            if b.defId == "hq" { hqFell = true; continue }
            state.base.buildings[i].hp = 0
            state.base.buildings[i].isRubble = true
            state.base.buildings[i].staffed = 0
            for z in state.base.zombies.indices where state.base.zombies[z].attacking == b.id {
                state.base.zombies[z].attacking = nil
            }
            events.append(.buildingDestroyed(b.id))
        }
        return hqFell
    }
}
