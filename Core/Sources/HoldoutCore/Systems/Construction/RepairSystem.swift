// Purpose: Repairs damaged buildings and rebuilds rubble (cost and time from buildings.json rules). Notes: docs/features/construction.md
import Foundation

/// STUB (1B contract) — the hordes agent fills this in.
enum RepairSystem {
    static func repair(id: BuildingID, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard state.base.building(id) != nil else { return .failure(.unknownBuildingID(id)) }
        return .failure(.nothingToRepair(id))
    }
}
