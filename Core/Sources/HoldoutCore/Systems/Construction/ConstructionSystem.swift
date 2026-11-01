// Purpose: Place, move, and demolish buildings (the build queue runs the timers). Notes: docs/features/construction.md
import Foundation

enum ConstructionSystem {
    /// Full placement check for a new building at `origin`: ground first, then rules and cost.
    static func checkPlace(defId: String, at origin: GridPoint, state: GameState, content: GameContent) -> PlacementCheck {
        guard let def = content.buildingDef(defId) else { return PlacementCheck(problem: .unknownBuilding(defId), badTiles: []) }
        guard let map = content.maps[state.base.mapId] else { return PlacementCheck(problem: .offMap, badTiles: []) }
        let (ground, bad) = PlacementRules.footprintProblem(def: def, origin: origin, base: state.base, map: map,
                                                            content: content, ignoring: nil)
        let problem = ground ?? PlacementRules.ruleProblem(def: def, state: state, content: content)
        return PlacementCheck(problem: problem, badTiles: bad)
    }

    /// Ground-only check for moving building `id` so its top-left tile is `origin`.
    static func checkMove(id: BuildingID, to origin: GridPoint, state: GameState, content: GameContent) -> PlacementCheck? {
        guard let building = state.base.building(id), let def = content.buildingDef(building.defId),
              let map = content.maps[state.base.mapId] else { return nil }
        let (problem, bad) = PlacementRules.footprintProblem(def: def, origin: origin, base: state.base, map: map,
                                                             content: content, ignoring: id)
        return PlacementCheck(problem: problem, badTiles: bad)
    }

    static func place(defId: String, at origin: GridPoint, state: inout GameState,
                      content: GameContent) -> Result<CommandOutcome, CommandError> {
        let check = checkPlace(defId: defId, at: origin, state: state, content: content)
        if let problem = check.problem { return .failure(.placement(problem)) }
        guard let def = content.buildingDef(defId), let level1 = def.level(1) else {
            return .failure(.placement(.unknownBuilding(defId)))
        }
        let ticks = content.ticks(forSeconds: level1.buildSeconds)
        let id = state.base.nextBuildingID
        state.base.nextBuildingID += 1
        // The cost is paid when the job starts (BuildQueue), so `invested` begins at zero.
        state.base.buildings.append(Building(id: id, defId: defId, level: 1, origin: origin, hp: level1.hp,
                                             constructionTicksLeft: ticks, constructionTicksTotal: ticks,
                                             invested: .zero))
        BuildQueue.enqueue(ConstructionJob(buildingId: id, kind: .build, targetLevel: 1, cost: level1.cost,
                                           ticksLeft: ticks, ticksTotal: ticks), &state)
        return .success(.placed(id))
    }

    static func move(id: BuildingID, to origin: GridPoint, state: inout GameState,
                     content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard let check = checkMove(id: id, to: origin, state: state, content: content),
              let index = state.base.buildings.firstIndex(where: { $0.id == id }) else {
            return .failure(.unknownBuildingID(id))
        }
        if let problem = check.problem { return .failure(.placement(problem)) }
        state.base.buildings[index].origin = origin
        return .success(.moved)
    }

    /// Removes a building and refunds `demolishRefundPct` of what was paid, clamped to storage caps.
    static func demolish(id: BuildingID, state: inout GameState, content: GameContent) -> Result<CommandOutcome, CommandError> {
        guard let index = state.base.buildings.firstIndex(where: { $0.id == id }) else {
            return .failure(.unknownBuildingID(id))
        }
        let building = state.base.buildings[index]
        if building.defId == "hq" { return .failure(.cannotDemolish(defId: building.defId)) }
        let refund = building.invested.percent(content.buildings.rules.demolishRefundPct)
        state.base.buildings.remove(at: index)
        BuildQueue.drop(buildingId: id, &state)
        state.base.stock = state.base.stock + refund
        ScavengingSystem.postRemoved(building, state: &state, content: content)
        DefenderTraining.barracksRemoved(&state, content: content)
        ResearchSystem.workshopRemoved(&state, content: content)
        DefenderPosts.releaseFromBrokenTowers(&state)
        StorageRules.clampToCaps(&state.base, content: content)
        Staffing.assign(&state, content: content)
        return .success(.demolished(refund: refund))
    }
}
