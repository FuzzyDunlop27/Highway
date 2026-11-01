// Purpose: A read-only summary of resources and caps for the App's HUD. Notes: docs/features/economy.md
import Foundation

public struct ResourceSnapshot: Equatable, Sendable {
    public let food: Int
    public let foodCap: Int
    public let scrap: Int
    public let scrapCap: Int
    public let survivors: Int
    /// Survivor cap from housing.
    public let housing: Int
    /// Survivors with no job: not working, building, away, training or defending.
    public let idleSurvivors: Int
    /// Food and scrap per minute right now (current staffing, ignoring caps).
    public let foodPerMin: Double
    public let scrapPerMin: Double

    static func make(state: GameState, content: GameContent) -> ResourceSnapshot {
        let base = state.base
        var rate: [ResourceKind: Double] = [:]
        for b in base.buildings where b.isComplete {
            guard let def = content.buildingDef(b.defId), let out = def.level(b.level)?.effects.productionPerMin else { continue }
            let share = (def.workers == 0 ? 1 : Double(b.staffed) / Double(def.workers))
                * ResearchEffects.productionMultiplier(defId: b.defId, knowledge: state.group.knowledge, content: content)
            for (kind, perMin) in out { rate[kind, default: 0] += perMin * share }
        }
        return ResourceSnapshot(
            food: base.stock.food, foodCap: StorageRules.cap(.food, base: base, content: content),
            scrap: base.stock.scrap, scrapCap: StorageRules.cap(.scrap, base: base, content: content),
            survivors: state.group.survivors, housing: StorageRules.housing(base: base, content: content),
            idleSurvivors: Roster.snapshot(state).idle,
            foodPerMin: rate[.food] ?? 0, scrapPerMin: rate[.scrap] ?? 0)
    }
}
