// Purpose: Commands that post a defender: garrison a tower, hold a spot, or go back to the HQ. Notes: docs/features/jobs-defenders.md
import Foundation

public enum DefenderProblem: Error, Equatable, Sendable {
    case unknownDefender
    /// Knocked-out defenders can't be given orders until they are back.
    case knockedOut
    case unknownBuilding
    /// Garrisons are allowed only in `units.json garrison.allowedIn`.
    case notAGarrisonBuilding
    /// Still being built, or rubble.
    case buildingNotFinished
    /// The tower already holds as many defenders as it has worker slots.
    case garrisonFull
    case offMap
}

enum DefenderPosts {
    private static func index(of id: DefenderID, _ state: GameState) -> Int? { state.base.defenders.firstIndex { $0.id == id } }

    private static func check(_ id: DefenderID, _ state: GameState) -> Result<Int, CommandError> {
        guard let i = index(of: id, state) else { return .failure(.defender(.unknownDefender)) }
        return state.base.defenders[i].isKnockedOut ? .failure(.defender(.knockedOut)) : .success(i)
    }

    static func garrison(_ id: DefenderID, in buildingId: BuildingID, state: inout GameState,
                         content: GameContent) -> Result<CommandOutcome, CommandError> {
        let i: Int
        switch check(id, state) { case .failure(let e): return .failure(e); case .success(let found): i = found }
        guard let b = state.base.building(buildingId), let def = content.buildingDef(b.defId) else {
            return .failure(.defender(.unknownBuilding))
        }
        guard let rule = content.units.units.compactMap(\.garrison).first, rule.allowedIn.contains(def.id) else {
            return .failure(.defender(.notAGarrisonBuilding))
        }
        guard b.isComplete else { return .failure(.defender(.buildingNotFinished)) }
        let already = state.base.defenders.filter { $0.garrisonedIn == buildingId && $0.id != id }.count
        guard already < def.workers else { return .failure(.defender(.garrisonFull)) }
        state.base.defenders[i].post = .garrison(buildingId: buildingId)
        Staffing.assign(&state, content: content)
        return .success(.defenderPosted)
    }

    static func hold(_ id: DefenderID, at tile: GridPoint, state: inout GameState,
                     content: GameContent) -> Result<CommandOutcome, CommandError> {
        let i: Int
        switch check(id, state) { case .failure(let e): return .failure(e); case .success(let found): i = found }
        guard content.maps[state.base.mapId]?.contains(tile) == true else { return .failure(.defender(.offMap)) }
        state.base.defenders[i].post = .hold(at: tile)
        Staffing.assign(&state, content: content)
        return .success(.defenderPosted)
    }

    static func recall(_ id: DefenderID, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        let i: Int
        switch check(id, state) { case .failure(let e): return .failure(e); case .success(let found): i = found }
        state.base.defenders[i].post = .hq
        Staffing.assign(&state, content: content)
        return .success(.defenderPosted)
    }

    /// A garrisoned tower that is no longer standing (rubble or gone) sends its defenders back to the HQ.
    static func releaseFromBrokenTowers(_ state: inout GameState) {
        for i in state.base.defenders.indices {
            guard let towerId = state.base.defenders[i].garrisonedIn else { continue }
            if state.base.building(towerId)?.isComplete != true { state.base.defenders[i].post = .hq }
        }
    }
}
