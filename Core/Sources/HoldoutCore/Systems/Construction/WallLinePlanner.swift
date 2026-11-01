// Purpose: Plans a whole wall line from one tile to another (path, which tiles get a wall, total cost) for the wall tool. Notes: docs/features/construction.md
import Foundation

/// What building a line of 1×1 pieces (walls) from `from` to `to` would do. The App shows it before the player hits Build.
public struct LinePlan: Equatable, Sendable {
    /// Every tile on the path, in order (a straight line, or an L with one corner).
    public let tiles: [GridPoint]
    /// Tiles that get a new piece when the player builds.
    public let buildable: [GridPoint]
    /// Tiles that already hold this piece type (skipped, not charged; handy when extending a wall).
    public let alreadyBuilt: [GridPoint]
    /// Tiles skipped because they can't take a piece (highway, wreck, another building, off the map, over the limit).
    public let blocked: [GridPoint]
    /// Total cost of the buildable tiles.
    public let cost: Cost
    /// A reason the line can't be built at all, or a warning (e.g. limit reached partway). Nil when all is well.
    public let problem: PlacementProblem?
    /// Building is allowed: something to build and enough food/scrap for all of it.
    public let canBuild: Bool
}

enum WallLinePlanner {
    /// Tiles from `a` to `b`: straight if they share a row or column, else an L that runs along the longer side first.
    static func path(from a: GridPoint, to b: GridPoint) -> [GridPoint] {
        let corner = abs(b.x - a.x) >= abs(b.y - a.y) ? GridPoint(x: b.x, y: a.y) : GridPoint(x: a.x, y: b.y)
        var tiles = segment(a, corner)
        for t in segment(corner, b) where t != corner { tiles.append(t) }
        return tiles
    }

    private static func segment(_ a: GridPoint, _ b: GridPoint) -> [GridPoint] {
        let dx = (b.x - a.x).signum(), dy = (b.y - a.y).signum()
        let steps = max(abs(b.x - a.x), abs(b.y - a.y))
        return (0...steps).map { GridPoint(x: a.x + dx * $0, y: a.y + dy * $0) }
    }

    static func plan(defId: String, from a: GridPoint, to b: GridPoint, state: GameState, content: GameContent) -> LinePlan {
        let tiles = path(from: a, to: b)
        func blockedPlan(_ problem: PlacementProblem) -> LinePlan {
            LinePlan(tiles: tiles, buildable: [], alreadyBuilt: [], blocked: tiles, cost: .zero, problem: problem, canBuild: false)
        }
        guard let def = content.buildingDef(defId), let level1 = def.level(1),
              let map = content.maps[state.base.mapId] else { return blockedPlan(.unknownBuilding(defId)) }
        guard def.width == 1 && def.height == 1 else { return blockedPlan(.unknownBuilding(defId)) }

        // Requirements that stop the whole line (HQ level, research, prerequisite buildings). Limit and cost are per line.
        var limitReached = false
        switch PlacementRules.ruleProblem(def: def, state: state, content: content) {
        case .limitReached: limitReached = true
        case .notEnoughResources, nil: break
        case let other?: return blockedPlan(other)
        }
        let allowance = limitReached ? 0 : Self.remainingAllowance(def: def, state: state, content: content)
        let queueRoom = BuildQueue.room(state, content: content)

        var buildable: [GridPoint] = [], alreadyBuilt: [GridPoint] = [], blocked: [GridPoint] = []
        var overLimit = false, overQueue = false
        for t in tiles {
            if let existing = state.base.buildings.first(where: { $0.origin == t }), existing.defId == defId {
                alreadyBuilt.append(t)
            } else if PlacementRules.footprintProblem(def: def, origin: t, base: state.base, map: map,
                                                      content: content, ignoring: nil).0 != nil {
                blocked.append(t)
            } else if buildable.count >= allowance {
                blocked.append(t)
                overLimit = true
            } else if buildable.count >= queueRoom {
                blocked.append(t)
                overQueue = true
            } else {
                buildable.append(t)
            }
        }
        let n = buildable.count
        let cost = Cost(scrap: level1.cost.scrap * n, food: level1.cost.food * n)
        let canAfford = state.base.stock.covers(cost)
        var problem: PlacementProblem?
        if overLimit || (limitReached && buildable.isEmpty) {
            problem = .limitReached(max: Self.limit(def: def, state: state))
        }
        if overQueue || (queueRoom == 0 && buildable.isEmpty) { problem = .queueFull }
        if !canAfford { problem = .notEnoughResources(needed: cost) }
        if buildable.isEmpty && problem == nil { problem = alreadyBuilt.isEmpty ? .blockedTerrain : .occupied }
        return LinePlan(tiles: tiles, buildable: buildable, alreadyBuilt: alreadyBuilt, blocked: blocked, cost: cost,
                        problem: problem, canBuild: !buildable.isEmpty && canAfford)
    }

    /// Builds every buildable tile of the plan at once, or nothing (if the plan can't be built).
    static func place(defId: String, from a: GridPoint, to b: GridPoint, state: inout GameState,
                      content: GameContent) -> Result<CommandOutcome, CommandError> {
        let plan = plan(defId: defId, from: a, to: b, state: state, content: content)
        guard plan.canBuild else { return .failure(.placement(plan.problem ?? .blockedTerrain)) }
        var ids: [BuildingID] = []
        for t in plan.buildable {
            guard case .success(.placed(let id)) = ConstructionSystem.place(defId: defId, at: t, state: &state, content: content)
            else { continue }  // can't happen: the plan already checked ground, limit, and the total cost
            ids.append(id)
        }
        return .success(.placedLine(ids))
    }

    static func limit(def: BuildingDef, state: GameState) -> Int {
        def.maxCountByHq[max(0, min(state.base.hqLevel, def.maxCountByHq.count) - 1)]
    }

    private static func remainingAllowance(def: BuildingDef, state: GameState, content: GameContent) -> Int {
        let key = def.sharesCountWith ?? def.id
        let count = state.base.buildings.filter { (content.buildingDef($0.defId)?.sharesCountWith ?? $0.defId) == key }.count
        return max(0, limit(def: def, state: state) - count)
    }
}
