// Purpose: Who is where: working, building, away, defending or idle. Every survivor is in exactly one place. Notes: docs/features/jobs-defenders.md
import Foundation

/// A read-only picture of the group for the HUD. The parts add up to `total`.
public struct PopulationSnapshot: Equatable, Sendable {
    public let total: Int
    /// Civilians staffing buildings.
    public let working: Int
    /// Borrowed by running construction jobs.
    public let building: Int
    /// On scavenging runs.
    public let away: Int
    /// Trained defenders (any post, knocked out too).
    public let defenders: Int
    /// Being trained into defenders.
    public let training: Int
    public let idle: Int
}

enum Roster {
    /// Survivors kept out of the work pool: defenders, trainees and runs. They have first call on people.
    static func committed(_ base: Base) -> Int {
        base.defenders.count + base.training.count + base.runs.reduce(0) { $0 + $1.survivors }
    }

    static func borrowedAsBuilders(_ base: Base) -> Int { base.jobs.reduce(0) { $0 + $1.builders } }

    /// Survivors free for builders or workers: everyone minus the defenders, trainees and runners.
    static func workPool(_ state: GameState) -> Int {
        max(0, state.group.survivors - committed(state.base))
    }

    /// Survivors a new command (a run, a trainee) may take right now. Workers step aside for it, just as they do
    /// for builders, so nobody has to un-assign people by hand first.
    static func available(_ state: GameState) -> Int {
        max(0, workPool(state) - borrowedAsBuilders(state.base))
    }

    /// How many defenders are garrisoned in each building.
    static func garrisonCounts(_ base: Base) -> [BuildingID: Int] {
        var counts: [BuildingID: Int] = [:]
        for d in base.defenders { if let id = d.garrisonedIn { counts[id, default: 0] += 1 } }
        return counts
    }

    static func snapshot(_ state: GameState) -> PopulationSnapshot {
        let base = state.base
        let garrison = garrisonCounts(base)
        let working = base.buildings.reduce(0) { $0 + max(0, $1.staffed - (garrison[$1.id] ?? 0)) }
        let building = borrowedAsBuilders(base)
        let away = base.runs.reduce(0) { $0 + $1.survivors }
        let idle = max(0, state.group.survivors - working - building - away - base.defenders.count - base.training.count)
        return PopulationSnapshot(total: state.group.survivors, working: working, building: building, away: away,
                                  defenders: base.defenders.count, training: base.training.count, idle: idle)
    }
}
