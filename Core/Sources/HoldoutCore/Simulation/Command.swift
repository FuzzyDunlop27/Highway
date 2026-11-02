// Purpose: Player actions the App sends into Core, and what comes back. Notes: docs/features/core-api.md
import Foundation

/// Everything the App can ask Core to do. The App never edits `GameState` directly.
public enum Command: Equatable, Sendable {
    /// Pay the level-1 cost and start building `defId` with its top-left tile at `at`, front pointing `facing`
    /// (east/west turn the footprint; buildings that aren't `rotatable` always face south).
    case placeBuilding(defId: String, at: GridPoint, facing: Facing = .south)
    /// Build a whole line of 1×1 pieces (walls) from one tile to another at once: straight, or an L with one corner.
    /// Tiles that are blocked or already hold this piece are skipped. All or nothing on cost (see `GameLoop.planLine`).
    case placeLine(defId: String, from: GridPoint, to: GridPoint)
    /// Move a building (finished or not) for free; its new spot must be valid. `facing` turns it too (nil = keep it).
    case moveBuilding(id: BuildingID, to: GridPoint, facing: Facing? = nil)
    /// Remove a building and refund a share of what was paid (buildings.json demolishRefundPct).
    case demolish(id: BuildingID)
    /// Change game speed; must be one of economy.json speedOptions (0 = pause).
    case setSpeed(Int)
    /// Repair a damaged building or rebuild rubble (buildings.json rules.repair / rules.rubble cost and time).
    case repair(id: BuildingID)
    /// Start upgrading a finished building to its next level (queued like any construction job; cost paid when it starts).
    case upgrade(id: BuildingID)
    /// Cancel a building's waiting or running job: a new building, an upgrade, or a rubble rebuild.
    case cancelJob(buildingId: BuildingID)
    /// Choose how many survivors work in a building (0 up to its worker slots). Unassigned people stay idle.
    case setWorkers(id: BuildingID, count: Int)
    /// Queue one defender at the Barracks: costs `units.json training.cost` and one survivor.
    case trainDefender
    /// Cancel the training at `index` in `Base.training` (0 = in progress). Refund per the `cancelRefundPct` rule.
    case cancelTraining(index: Int)
    /// Put a defender inside a tower (`units.json garrison.allowedIn`): it counts as the tower's worker and boosts it.
    case garrison(defender: DefenderID, in: BuildingID)
    /// Send a defender to stand on a tile and shoot zombies in range.
    case holdSpot(defender: DefenderID, at: GridPoint)
    /// Bring a defender back to wait at the HQ.
    case recallDefender(DefenderID)
    /// Send survivors from a Scavenger Post on a run (`runId` from the post's `runs.types`).
    case startRun(buildingId: BuildingID, runId: String)
    /// Take the rewards waiting at a Scavenger Post into storage (what doesn't fit stays there).
    case collectRun(buildingId: BuildingID)
    /// Start researching an item at the Workshop (`research.json`).
    case startResearch(String)
    /// Testing only (the App shows these in DEBUG builds): start the next horde now.
    case debugStartHorde
    /// Testing only: add food/scrap (clamped to caps).
    case debugAddResources(Cost)
    /// Testing only: remove every zombie (counts as killed, no loot).
    case debugKillAllZombies
}

public enum CommandOutcome: Equatable, Sendable {
    case placed(BuildingID)
    case placedLine([BuildingID])
    case moved
    case demolished(refund: Cost)
    case speedSet
    case repairStarted(cost: Cost)
    case upgradeQueued(cost: Cost)
    /// The job was cancelled; `refund` is zero for a job that hadn't started.
    case cancelled(refund: Cost)
    case workersSet
    case trainingQueued(cost: Cost)
    case trainingCancelled(refund: Cost)
    case defenderPosted
    case runStarted(cost: Cost)
    /// What actually moved into storage.
    case collected(Cost)
    case researchStarted(cost: Cost)
    case debugDone
}

public enum CommandError: Error, Equatable, Sendable {
    /// Placing or moving failed; the problem says why (same value `checkPlacement` returns).
    case placement(PlacementProblem)
    case unknownBuildingID(BuildingID)
    /// This building type can't be demolished (the HQ).
    case cannotDemolish(defId: String)
    case invalidSpeed(Int)
    /// The building is at full health and not rubble.
    case nothingToRepair(BuildingID)
    case notEnoughResources(needed: Cost)
    case upgrade(UpgradeProblem)
    /// Nothing waiting or running for this building.
    case noJob(BuildingID)
    /// The build queue has no room for another job.
    case queueFull
    case jobs(JobsProblem)
    case training(TrainingProblem)
    case defender(DefenderProblem)
    case run(RunProblem)
    case research(ResearchProblem)
}
