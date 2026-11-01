// Purpose: Gives survivors their worker slots: the player's chosen counts, oldest building first. Notes: docs/features/economy.md
import Foundation

enum Staffing {
    /// Sets `staffed` on every building. Each finished building wants its `assignedWorkers` (all of `workers` unless
    /// the player lowered it), less any garrisoned defenders, who count as workers themselves. Civilians come from
    /// the work pool (survivors minus defenders, trainees, runners and builders) in building-id order (oldest first).
    static func assign(_ state: inout GameState, content: GameContent) {
        var available = Roster.available(state)
        let garrison = Roster.garrisonCounts(state.base)
        for i in state.base.buildings.indices {
            let b = state.base.buildings[i]
            guard b.isComplete, let def = content.buildingDef(b.defId) else {
                state.base.buildings[i].staffed = 0
                continue
            }
            let posted = min(garrison[b.id] ?? 0, def.workers)
            let wanted = max(0, min(b.assignedWorkers ?? def.workers, def.workers) - posted)
            let given = min(wanted, available)
            state.base.buildings[i].staffed = given + posted
            available -= given
        }
    }
}
