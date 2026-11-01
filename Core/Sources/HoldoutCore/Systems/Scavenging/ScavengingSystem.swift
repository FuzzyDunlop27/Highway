// Purpose: Scavenging runs: send survivors from a Scavenger Post, bring them home, hold the reward until collected. Notes: docs/features/scavenging-research.md
import Foundation

public enum RunProblem: Error, Equatable, Sendable {
    case unknownBuilding
    /// Not a Scavenger Post, or still being built, or rubble.
    case notAPost
    case unknownRun
    /// This post's level doesn't offer that run yet (`runsUnlocked`).
    case notUnlocked
    /// One run at a time per post.
    case postBusy
    case noFreeSurvivors(needed: Int)
    case notEnoughResources(needed: Cost)
    case nothingToCollect
}

enum ScavengingSystem {
    private static func post(_ id: BuildingID, _ state: GameState, _ content: GameContent)
        -> (index: Int, def: BuildingDef, level: LevelDef)? {
        guard let i = state.base.buildings.firstIndex(where: { $0.id == id }),
              let def = content.buildingDef(state.base.buildings[i].defId), def.runs != nil,
              let level = def.level(state.base.buildings[i].level) else { return nil }
        return (i, def, level)
    }

    static func problem(buildingId: BuildingID, runId: String, state: GameState, content: GameContent) -> RunProblem? {
        guard state.base.building(buildingId) != nil else { return .unknownBuilding }
        guard let p = post(buildingId, state, content), state.base.buildings[p.index].isComplete else { return .notAPost }
        guard let run = p.def.runs?.types.first(where: { $0.id == runId }) else { return .unknownRun }
        if p.level.effects.runsUnlocked?.contains(runId) != true { return .notUnlocked }
        if state.base.runs.contains(where: { $0.buildingId == buildingId }) { return .postBusy }
        if Roster.available(state) < run.survivorsSent { return .noFreeSurvivors(needed: run.survivorsSent) }
        if !state.base.stock.covers(run.cost) { return .notEnoughResources(needed: run.cost) }
        return nil
    }

    static func start(buildingId: BuildingID, runId: String, state: inout GameState,
                      content: GameContent) -> Result<CommandOutcome, CommandError> {
        if let problem = problem(buildingId: buildingId, runId: runId, state: state, content: content) {
            return .failure(.run(problem))
        }
        let run = post(buildingId, state, content)!.def.runs!.types.first { $0.id == runId }!
        state.base.stock.scrap -= run.cost.scrap
        state.base.stock.food -= run.cost.food
        let ticks = max(1, content.ticks(forSeconds: run.durationSeconds))
        state.base.runs.append(ScavengingRun(buildingId: buildingId, typeId: runId, survivors: run.survivorsSent,
                                             ticksLeft: ticks, ticksTotal: ticks))
        Staffing.assign(&state, content: content)
        return .success(.runStarted(cost: run.cost))
    }

    /// Counts runs down. A finished run frees its survivors and adds `reward × runRewardMultiplier` (rounded down)
    /// to the post's held reward.
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard !state.base.runs.isEmpty else { return }
        var finished = false
        for i in state.base.runs.indices { state.base.runs[i].ticksLeft = max(0, state.base.runs[i].ticksLeft - 1) }
        for run in state.base.runs where run.ticksLeft == 0 {
            finished = true
            if let p = post(run.buildingId, state, content),
               let type = p.def.runs?.types.first(where: { $0.id == run.typeId }) {
                let factor = p.level.effects.runRewardMultiplier ?? 1
                let reward = Cost(scrap: Int((Double(type.reward.scrap) * factor).rounded(.down)),
                                  food: Int((Double(type.reward.food) * factor).rounded(.down)))
                state.base.buildings[p.index].heldReward = (state.base.buildings[p.index].heldReward ?? .zero) + reward
            }
            events.append(.runFinished(buildingId: run.buildingId))
        }
        if finished {
            state.base.runs.removeAll { $0.ticksLeft == 0 }
            Staffing.assign(&state, content: content)
        }
    }

    /// Moves what fits from the post's held reward into storage; the rest stays at the post.
    static func collect(buildingId: BuildingID, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard let p = post(buildingId, state, content), state.base.buildings[p.index].isComplete else {
            return .failure(.run(.notAPost))
        }
        let held = state.base.buildings[p.index].heldReward ?? .zero
        guard held != .zero else { return .failure(.run(.nothingToCollect)) }
        var moved = Cost.zero, left = held
        for kind in ResourceKind.allCases {
            let room = max(0, StorageRules.cap(kind, base: state.base, content: content) - state.base.stock[kind])
            moved[kind] = min(held[kind], room)
            left[kind] = held[kind] - moved[kind]
        }
        state.base.stock = state.base.stock + moved
        state.base.buildings[p.index].heldReward = left == .zero ? nil : left
        return .success(.collected(moved))
    }

    /// A post is demolished: its survivors come home and whatever waited there goes to storage (what fits).
    static func postRemoved(_ building: Building, state: inout GameState, content: GameContent) {
        state.base.runs.removeAll { $0.buildingId == building.id }
        state.base.stock = state.base.stock + (building.heldReward ?? .zero)
        StorageRules.clampToCaps(&state.base, content: content)
    }
}
