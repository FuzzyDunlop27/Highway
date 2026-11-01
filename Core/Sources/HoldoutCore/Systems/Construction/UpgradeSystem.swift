// Purpose: Upgrades: checks and queues a finished building's next level (cost, HQ gate, time from buildings.json). Notes: docs/features/construction.md
import Foundation

/// Why a building can't be upgraded right now.
public enum UpgradeProblem: Error, Equatable, Sendable {
    case unknownBuilding
    /// Already at its top level.
    case maxLevel
    /// Still being built, or rubble.
    case notFinished
    /// It already has a job (an upgrade queued or running).
    case alreadyWorking
    case needsHqLevel(Int)
    case queueFull
    case notEnoughResources(needed: Cost)
}

enum UpgradeSystem {
    /// The next level's definition, if the building can have one.
    static func nextLevel(of b: Building, content: GameContent) -> LevelDef? {
        content.buildingDef(b.defId)?.level(b.level + 1)
    }

    static func problem(id: BuildingID, state: GameState, content: GameContent) -> UpgradeProblem? {
        guard let b = state.base.building(id), content.buildingDef(b.defId) != nil else { return .unknownBuilding }
        guard let next = nextLevel(of: b, content: content) else { return .maxLevel }
        if !b.isComplete { return .notFinished }
        if state.base.job(for: id) != nil { return .alreadyWorking }
        if state.base.hqLevel < next.requiredHq { return .needsHqLevel(next.requiredHq) }
        if !BuildQueue.hasRoom(state, content: content) { return .queueFull }
        if !state.base.stock.covers(next.cost) { return .notEnoughResources(needed: next.cost) }
        return nil
    }

    static func upgrade(id: BuildingID, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        if let problem = problem(id: id, state: state, content: content) {
            if problem == .unknownBuilding { return .failure(.unknownBuildingID(id)) }
            return .failure(.upgrade(problem))
        }
        let b = state.base.building(id)!
        let next = nextLevel(of: b, content: content)!
        let ticks = content.ticks(forSeconds: next.buildSeconds)
        BuildQueue.enqueue(ConstructionJob(buildingId: id, kind: .upgrade, targetLevel: next.level, cost: next.cost,
                                           ticksLeft: ticks, ticksTotal: ticks), &state)
        return .success(.upgradeQueued(cost: next.cost))
    }
}
