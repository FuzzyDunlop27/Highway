// Purpose: 1A auto-staffing: survivors fill worker slots in finished buildings, oldest building first. Notes: docs/features/economy.md
import Foundation

enum Staffing {
    /// Sets `staffed` on every building. Survivors go to finished buildings with `workers` > 0 in
    /// building-id order (oldest first) until everyone is working. Manual jobs replace this in 1C.
    static func assign(_ state: inout GameState, content: GameContent) {
        // Builders on running jobs are borrowed first; the rest work (until 2B, jobs are assigned automatically).
        var available = max(0, state.group.survivors - state.base.jobs.reduce(0) { $0 + $1.builders })
        for i in state.base.buildings.indices {
            let b = state.base.buildings[i]
            let wanted = b.isComplete ? (content.buildingDef(b.defId)?.workers ?? 0) : 0
            let given = min(wanted, available)
            state.base.buildings[i].staffed = given
            available -= given
        }
    }
}
