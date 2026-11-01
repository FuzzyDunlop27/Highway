// Purpose: Command.setWorkers: the player chooses how many survivors work in a building. Notes: docs/features/jobs-defenders.md
import Foundation

public enum JobsProblem: Error, Equatable, Sendable {
    /// This building has no worker slots (a wall, a shelter...).
    case notAWorkplace
    /// More than the building's slots, or negative.
    case tooManyWorkers(max: Int)
}

enum WorkerAssignment {
    static func set(id: BuildingID, count: Int, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard let i = state.base.buildings.firstIndex(where: { $0.id == id }),
              let def = content.buildingDef(state.base.buildings[i].defId) else { return .failure(.unknownBuildingID(id)) }
        guard def.workers > 0 else { return .failure(.jobs(.notAWorkplace)) }
        guard (0...def.workers).contains(count) else { return .failure(.jobs(.tooManyWorkers(max: def.workers))) }
        state.base.buildings[i].assignedWorkers = count
        Staffing.assign(&state, content: content)
        return .success(.workersSet)
    }
}
