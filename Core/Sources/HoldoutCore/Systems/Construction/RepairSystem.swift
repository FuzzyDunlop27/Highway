// Purpose: Repairs damaged buildings and rebuilds rubble (cost and time from buildings.json rules). Notes: docs/features/construction.md
import Foundation

/// `Command.repair(id)`. Buildings keep their level and pay at once. Rubble rebuilds on a construction timer (it
/// isn't working anyway). A damaged building heals at once and keeps working: a timer would switch it off, and a
/// Storage going off drops the cap and deletes stock (D-020). The repair time in rules.repair waits for 1C builders.
enum RepairSystem {
    static func repair(id: BuildingID, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard let index = state.base.buildings.firstIndex(where: { $0.id == id }) else { return .failure(.unknownBuildingID(id)) }
        let building = state.base.buildings[index]
        guard let level = content.buildingDef(building.defId)?.level(building.level),
              let quote = quote(building, level: level, content: content) else { return .failure(.nothingToRepair(id)) }
        guard state.base.stock.covers(quote.cost) else { return .failure(.notEnoughResources(needed: quote.cost)) }
        let ticks = building.isRubble ? content.ticks(forSeconds: quote.seconds) : 0
        state.base.stock.scrap -= quote.cost.scrap
        state.base.stock.food -= quote.cost.food
        state.base.buildings[index].isRubble = false
        state.base.buildings[index].hp = level.hp
        state.base.buildings[index].constructionTicksLeft = ticks
        state.base.buildings[index].constructionTicksTotal = ticks
        state.base.buildings[index].invested = building.invested + quote.cost
        return .success(.repairStarted(cost: quote.cost))
    }

    /// What repairing (or rebuilding) `building` would cost and take, or nil if there is nothing to repair:
    /// full health, or still being built/repaired. For the building panel's Repair / Rebuild button too.
    static func quote(_ building: Building, level: LevelDef, content: GameContent) -> (cost: Cost, seconds: Double)? {
        if building.isRubble {
            // rules.rubble: cost = invested × rebuildCostPct (free starting buildings use their level cost instead);
            // time = buildSeconds × rebuildTimePct.
            let rule = content.buildings.rules.rubble
            let paid = building.invested == .zero ? level.cost : building.invested
            return (paid.percent(rule.rebuildCostPctOfInvested), level.buildSeconds * Double(rule.rebuildTimePctOfInvested) / 100)
        }
        guard building.constructionTicksLeft == 0, building.hp < level.hp, level.hp > 0 else { return nil }
        // rules.repair: cost = levelCost × costPct × missingHpFraction (rounded up, so any damage costs something
        // if the level cost does); time = max(minSeconds, buildSeconds × timePct × missingHpFraction).
        let rule = content.buildings.rules.repair
        let missing = min(level.hp - building.hp, level.hp)
        let divisor = 100 * level.hp
        func part(_ amount: Int) -> Int { (amount * rule.costPctOfLevelCost * missing + divisor - 1) / divisor }
        let cost = Cost(scrap: part(level.cost.scrap), food: part(level.cost.food))
        let fraction = Double(missing) / Double(level.hp)
        let seconds = max(rule.minSeconds, level.buildSeconds * Double(rule.timePctOfBuildTime) / 100 * fraction)
        return (cost, seconds)
    }
}
