// Purpose: Player actions the App sends into Core, and what comes back. Notes: docs/features/core-api.md
import Foundation

/// Everything the App can ask Core to do. The App never edits `GameState` directly.
public enum Command: Equatable, Sendable {
    /// Pay the level-1 cost and start building `defId` with its top-left tile at `at`.
    case placeBuilding(defId: String, at: GridPoint)
    /// Move a building (finished or not) for free; its new spot must be valid.
    case moveBuilding(id: BuildingID, to: GridPoint)
    /// Remove a building and refund a share of what was paid (buildings.json demolishRefundPct).
    case demolish(id: BuildingID)
    /// Change game speed; must be one of economy.json speedOptions (0 = pause).
    case setSpeed(Int)
}

public enum CommandOutcome: Equatable, Sendable {
    case placed(BuildingID)
    case moved
    case demolished(refund: Cost)
    case speedSet
}

public enum CommandError: Error, Equatable, Sendable {
    /// Placing or moving failed; the problem says why (same value `checkPlacement` returns).
    case placement(PlacementProblem)
    case unknownBuildingID(BuildingID)
    /// This building type can't be demolished (the HQ).
    case cannotDemolish(defId: String)
    case invalidSpeed(Int)
}
