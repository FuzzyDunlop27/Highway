// Purpose: How a horde ends: held (completion bonus) or HQ fell (resource loss, HQ restored), then day + 1. Notes: docs/features/hordes.md
import Foundation

enum HordeOutcome {
    /// Every zombie spawned and died: pay hordes.json `completionBonus` (base + perDay × day, × loot multiplier),
    /// clamped to caps. The event reports what was actually added.
    static func held(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard let active = state.base.horde.active else { return }
        let rule = content.hordes.completionBonus
        let day = state.base.horde.day
        let full = Cost(scrap: Int((Double(rule.scrapBase + rule.scrapPerDay * day) * active.lootMultiplier).rounded(.down)),
                        food: Int((Double(rule.foodBase + rule.foodPerDay * day) * active.lootMultiplier).rounded(.down)))
        let before = state.base.stock
        state.base.stock = state.base.stock + full
        StorageRules.clampToCaps(&state.base, content: content)
        let added = Cost(scrap: state.base.stock.scrap - before.scrap, food: state.base.stock.food - before.food)
        end(&state, content: content)
        events.append(.hordeEnded(.held(bonus: added)))
    }

    /// The HQ reached 0 hp (economy.json `hqFall`, D-007): each `affects` resource loses `resourceLossPct` %
    /// (rounded down), the HQ comes back at `hqRestoreHpPct` % of its level's max hp, and (if `endsHorde`)
    /// every zombie leaves and the horde ends. Survivors are never lost.
    static func hqFall(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        let rule = content.economy.hqFall
        var lost = Cost.zero
        for kind in rule.affects {
            lost[kind] = state.base.stock[kind] * rule.resourceLossPct / 100
            state.base.stock[kind] -= lost[kind]
        }
        if let i = state.base.buildings.firstIndex(where: { $0.defId == "hq" }) {
            let b = state.base.buildings[i]
            let maxHp = content.buildingDef(b.defId)?.level(b.level)?.hp ?? 1
            state.base.buildings[i].hp = max(1, maxHp * rule.hqRestoreHpPct / 100)
        }
        if rule.endsHorde {
            state.base.zombies.removeAll()
            end(&state, content: content)
        }
        events.append(.hordeEnded(.hqFell(lost: lost)))
    }

    /// Clears the active horde. A regular horde advances the day and lets HordeSystem schedule the next one
    /// (intervalSeconds from now); a bonus horde (1D) leaves the clock alone unless bonusHorde.advancesDay.
    static func end(_ state: inout GameState, content: GameContent) {
        guard let active = state.base.horde.active else { return }
        state.base.horde.active = nil
        if !active.isBonus || content.hordes.bonusHorde.advancesDay {
            state.base.horde.day += 1
            state.base.horde.ticksUntilNext = nil
        }
    }
}
