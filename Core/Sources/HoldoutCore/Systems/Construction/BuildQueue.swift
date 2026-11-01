// Purpose: Build slots, the waiting queue and builders: starts, runs, finishes and cancels construction jobs. Notes: docs/features/construction.md
import Foundation

/// Replaces the timer-only build of D-012 (D-033). Slots come from the HQ level, each running job borrows
/// `buildersPerJob` survivors, and a job's cost is paid when it starts, not when it is queued.
enum BuildQueue {
    static func slots(_ base: Base, content: GameContent) -> Int {
        let slots = content.buildings.rules.constructionSlotsByHq
        return slots[max(0, min(base.hqLevel, slots.count) - 1)]
    }

    static func activeCount(_ base: Base) -> Int { base.jobs.filter(\.started).count }
    static func queuedCount(_ base: Base) -> Int { base.jobs.count - activeCount(base) }

    /// Survivors a job could borrow: not already builders, defenders, trainees or on a run (workers step aside).
    static func freeBuilders(_ state: GameState) -> Int { Roster.available(state) }

    /// A job could start this instant, as far as slots and builders go (resources are checked separately).
    static func canStartNow(_ state: GameState, content: GameContent) -> Bool {
        activeCount(state.base) < slots(state.base, content: content)
            && freeBuilders(state) >= content.buildings.rules.buildersPerJob
    }

    /// How many more jobs may be added right now: the ones that start at once plus the free queue places.
    static func room(_ state: GameState, content: GameContent) -> Int {
        let rules = content.buildings.rules
        let startNow = max(0, min(slots(state.base, content: content) - activeCount(state.base),
                                  rules.buildersPerJob == 0 ? Int.max : freeBuilders(state) / rules.buildersPerJob))
        return startNow + max(0, rules.constructionQueueLength - queuedCount(state.base))
    }

    static func hasRoom(_ state: GameState, content: GameContent) -> Bool { room(state, content: content) > 0 }

    /// Adds a waiting job. The caller has checked the ground, the rules, the queue room and that the cost is affordable.
    static func enqueue(_ job: ConstructionJob, _ state: inout GameState) {
        state.base.jobs.append(job)
        mirror(job, into: &state)
    }

    /// Starts waiting jobs, oldest first, while a slot, a free builder and the resources are there.
    /// A job that can't be paid yet is skipped, so a cheap wall isn't stuck behind an expensive upgrade.
    static func startJobs(_ state: inout GameState, content: GameContent) {
        let rules = content.buildings.rules
        guard rules.buildDuringHorde || state.base.horde.active == nil else { return }
        for index in state.base.jobs.indices where !state.base.jobs[index].started {
            guard canStartNow(state, content: content) else { return }
            let job = state.base.jobs[index]
            guard state.base.stock.covers(job.cost),
                  let b = state.base.buildings.firstIndex(where: { $0.id == job.buildingId }) else { continue }
            state.base.stock.scrap -= job.cost.scrap
            state.base.stock.food -= job.cost.food
            state.base.buildings[b].invested = state.base.buildings[b].invested + job.cost
            if job.kind == .rebuild, let level = content.buildingDef(state.base.buildings[b].defId)?.level(job.targetLevel) {
                state.base.buildings[b].isRubble = false
                state.base.buildings[b].hp = level.hp
            }
            state.base.jobs[index].started = true
            state.base.jobs[index].builders = rules.buildersPerJob
        }
    }

    /// One tick: drop jobs whose building is gone or destroyed, count down running jobs, finish them, start more.
    static func tick(_ state: inout GameState, content: GameContent) {
        dropOrphans(&state)
        var finished: [ConstructionJob] = []
        for index in state.base.jobs.indices where state.base.jobs[index].started {
            state.base.jobs[index].ticksLeft = max(0, state.base.jobs[index].ticksLeft - 1)
            mirror(state.base.jobs[index], into: &state)
            if state.base.jobs[index].ticksLeft == 0 { finished.append(state.base.jobs[index]) }
        }
        for job in finished {
            state.base.jobs.removeAll { $0.buildingId == job.buildingId }
            guard job.kind == .upgrade, let b = state.base.buildings.firstIndex(where: { $0.id == job.buildingId }) else { continue }
            state.base.buildings[b].level = job.targetLevel
            state.base.buildings[b].hp = content.buildingDef(state.base.buildings[b].defId)?.level(job.targetLevel)?.hp
                ?? state.base.buildings[b].hp
        }
        startJobs(&state, content: content)
    }

    /// Forgets the job of a building that was demolished (the caller removes the building).
    static func drop(buildingId: BuildingID, _ state: inout GameState) {
        state.base.jobs.removeAll { $0.buildingId == buildingId }
    }

    /// Cancels the job of `buildingId`. Waiting jobs cost nothing; running ones refund `cancelRefundPct` of what they cost.
    static func cancel(buildingId: BuildingID, state: inout GameState,
                       content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard let job = state.base.job(for: buildingId),
              let b = state.base.buildings.firstIndex(where: { $0.id == buildingId }) else { return .failure(.noJob(buildingId)) }
        var refund = Cost.zero
        if job.started {
            refund = job.cost.percent(content.buildings.rules.cancelRefundPct)
            let paid = state.base.buildings[b].invested
            state.base.buildings[b].invested = Cost(scrap: max(0, paid.scrap - job.cost.scrap), food: max(0, paid.food - job.cost.food))
            state.base.stock = state.base.stock + refund
        }
        state.base.jobs.removeAll { $0.buildingId == buildingId }
        switch job.kind {
        case .build:
            state.base.buildings.remove(at: b)
        case .rebuild:
            state.base.buildings[b].isRubble = true
            state.base.buildings[b].hp = 0
            state.base.buildings[b].constructionTicksLeft = 0
            state.base.buildings[b].constructionTicksTotal = 0
        case .upgrade:
            break
        }
        StorageRules.clampToCaps(&state.base, content: content)
        startJobs(&state, content: content)
        Staffing.assign(&state, content: content)
        return .success(.cancelled(refund: refund))
    }

    // MARK: Private

    /// Jobs on a building that no longer exists, or that was destroyed while its job ran, can't go on.
    private static func dropOrphans(_ state: inout GameState) {
        let buildings = Dictionary(uniqueKeysWithValues: state.base.buildings.map { ($0.id, $0) })
        var dropped: [ConstructionJob] = []
        state.base.jobs.removeAll { job in
            guard let b = buildings[job.buildingId] else { return true }
            let dead = b.isRubble && (job.kind != .rebuild || job.started)
            if dead { dropped.append(job) }
            return dead
        }
        for job in dropped {
            guard let i = state.base.buildings.firstIndex(where: { $0.id == job.buildingId }) else { continue }
            state.base.buildings[i].constructionTicksLeft = 0
            state.base.buildings[i].constructionTicksTotal = 0
        }
    }

    /// New buildings and rebuilds show their job's progress on the `Building` too (the App draws a progress bar from it).
    private static func mirror(_ job: ConstructionJob, into state: inout GameState) {
        guard job.kind != .upgrade, let b = state.base.buildings.firstIndex(where: { $0.id == job.buildingId }) else { return }
        state.base.buildings[b].constructionTicksLeft = job.ticksLeft
        state.base.buildings[b].constructionTicksTotal = job.ticksTotal
    }
}
