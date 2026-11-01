// Purpose: The Barracks training queue: queue, cancel and progress defenders (cost, time, caps from JSON). Notes: docs/features/jobs-defenders.md
import Foundation

public enum TrainingProblem: Error, Equatable, Sendable {
    /// No finished Barracks.
    case needsBarracks
    /// Defenders plus those in training are at the Barracks level's `maxDefenders`.
    case maxDefenders(Int)
    /// The training queue is full (`trainingQueueLength`).
    case queueFull
    case noFreeSurvivor
    case notEnoughResources(needed: Cost)
    case noSuchTraining
}

enum DefenderTraining {
    private static let barracksId = "barracks"

    /// The finished Barracks (if any); training needs it standing.
    static func barracks(_ state: GameState) -> Building? {
        state.base.buildings.first { $0.defId == barracksId && $0.isComplete }
    }

    private static func effects(_ state: GameState, content: GameContent) -> EffectsDef? {
        barracks(state).flatMap { content.buildingDef($0.defId)?.level($0.level)?.effects }
    }

    /// Why a defender can't be queued right now, or nil if `.trainDefender` would be accepted.
    static func problem(_ state: GameState, content: GameContent) -> TrainingProblem? {
        guard let effects = effects(state, content: content), let rule = content.units.units.first(where: { $0.training != nil })?.training
        else { return .needsBarracks }
        if state.base.defenders.count + state.base.training.count >= (effects.maxDefenders ?? 0) {
            return .maxDefenders(effects.maxDefenders ?? 0)
        }
        if state.base.training.count >= (effects.trainingQueueLength ?? 0) { return .queueFull }
        if Roster.available(state) < rule.consumesSurvivors { return .noFreeSurvivor }
        if !state.base.stock.covers(rule.cost) { return .notEnoughResources(needed: rule.cost) }
        return nil
    }

    static func queue(_ state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        if let problem = problem(state, content: content) { return .failure(.training(problem)) }
        let rule = content.units.units.first { $0.training != nil }!.training!
        let multiplier = effects(state, content: content)?.trainTimeMultiplier ?? 1
        let ticks = max(1, content.ticks(forSeconds: rule.trainSeconds * multiplier))
        state.base.stock.scrap -= rule.cost.scrap
        state.base.stock.food -= rule.cost.food
        state.base.training.append(TrainingJob(ticksLeft: ticks, ticksTotal: ticks, paid: rule.cost))
        Staffing.assign(&state, content: content)
        return .success(.trainingQueued(cost: rule.cost))
    }

    /// Waiting entries refund everything; the one in progress refunds `cancelRefundPct`.
    static func cancel(index: Int, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard state.base.training.indices.contains(index) else { return .failure(.training(.noSuchTraining)) }
        let job = state.base.training.remove(at: index)
        let refund = index == 0 ? job.paid.percent(content.buildings.rules.cancelRefundPct) : job.paid
        state.base.stock = state.base.stock + refund
        StorageRules.clampToCaps(&state.base, content: content)
        Staffing.assign(&state, content: content)
        return .success(.trainingCancelled(refund: refund))
    }

    /// The first job counts down while the Barracks is finished and staffed. When it ends, a defender joins at the HQ.
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard !state.base.training.isEmpty else { return }
        guard let barracks = barracks(state), let def = content.buildingDef(barracks.defId), barracks.staffed >= def.workers,
              let unit = content.units.units.first(where: { $0.training != nil }) else { return }
        state.base.training[0].ticksLeft = max(0, state.base.training[0].ticksLeft - 1)
        guard state.base.training[0].ticksLeft == 0 else { return }
        state.base.training.removeFirst()
        let id = state.base.nextDefenderID
        state.base.nextDefenderID += 1
        state.base.defenders.append(Defender(id: id, hp: unit.hp))
        events.append(.defenderReady(id))
    }

    /// The Barracks is gone (demolished): everything still in training is refunded in full.
    static func barracksRemoved(_ state: inout GameState, content: GameContent) {
        guard barracks(state) == nil, !state.base.training.isEmpty else { return }
        for job in state.base.training { state.base.stock = state.base.stock + job.paid }
        state.base.training.removeAll()
        StorageRules.clampToCaps(&state.base, content: content)
    }
}
