// Purpose: What the job panels show (who works where, queues, runs, research), changing only when the screen would. Notes: docs/features/hud-ui.md
import Foundation
import HoldoutCore

/// A copy of the parts of Core's state the panels draw. Timers are whole seconds and progress is rounded to a percent,
/// so `GameStore` only republishes it when something visible changed (not ten times a second for nothing).
struct JobsSnapshot: Equatable {
    struct Timer: Equatable {
        let secondsLeft: Int
        let progress: Double

        init(ticksLeft: Int, progress: Double, ticksPerSecond: Int) {
            secondsLeft = (ticksLeft + ticksPerSecond - 1) / max(ticksPerSecond, 1)
            self.progress = (progress * 100).rounded() / 100
        }
    }

    struct Run: Equatable {
        let buildingId: BuildingID
        let typeId: String
        let timer: Timer
    }

    struct Research: Equatable {
        let itemId: String
        let timer: Timer
    }

    /// The selected building's construction or upgrade job, if it has one.
    struct SelectedJob: Equatable {
        let kind: ConstructionJob.Kind
        let targetLevel: Int
        let started: Bool
        let progress: Double
    }

    let population: PopulationSnapshot
    let queue: BuildQueueStatus
    let defenders: [Defender]
    let training: [Timer]
    let runs: [Run]
    let research: Research?
    let knowledge: [String]
    let selectedJob: SelectedJob?

    static func make(loop: GameLoop, selected: BuildingID?) -> JobsSnapshot {
        let base = loop.state.base
        let tps = loop.content.economy.ticksPerSecond
        let job = selected.flatMap { base.job(for: $0) }
        return JobsSnapshot(
            population: loop.population, queue: loop.buildQueue, defenders: base.defenders,
            training: base.training.map { Timer(ticksLeft: $0.ticksLeft, progress: $0.progress, ticksPerSecond: tps) },
            runs: base.runs.map {
                Run(buildingId: $0.buildingId, typeId: $0.typeId,
                    timer: Timer(ticksLeft: $0.ticksLeft, progress: $0.progress, ticksPerSecond: tps))
            },
            research: base.research.map {
                Research(itemId: $0.itemId, timer: Timer(ticksLeft: $0.ticksLeft, progress: $0.progress, ticksPerSecond: tps))
            },
            knowledge: loop.state.group.knowledge,
            selectedJob: job.map { SelectedJob(kind: $0.kind, targetLevel: $0.targetLevel, started: $0.started,
                                               progress: ($0.progress * 100).rounded() / 100) })
    }
}
