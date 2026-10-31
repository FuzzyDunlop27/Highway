// Purpose: Decides whether a building can go on a spot (footprint, limits, HQ level, prerequisites, cost). Notes: docs/features/construction.md
import Foundation

/// Why a spot or a building can't be used. `badTiles` in `PlacementCheck` shows which tiles are wrong.
public enum PlacementProblem: Error, Equatable, Sendable {
    case unknownBuilding(String)
    /// Part of the footprint is off the map.
    case offMap
    /// Part of the footprint is on unbuildable ground (highway) or a decoration.
    case blockedTerrain
    /// Part of the footprint overlaps another building.
    case occupied
    /// The base already has the most of this type allowed at its HQ level.
    case limitReached(max: Int)
    case needsHqLevel(Int)
    case needsBuilding(String, level: Int)
    case needsResearch(String)
    case notEnoughResources(needed: Cost)
}

/// The answer to "can I put this here?" — used for the App's ghost preview.
public struct PlacementCheck: Equatable, Sendable {
    /// The first problem found, or nil when placement would succeed.
    public let problem: PlacementProblem?
    /// Footprint tiles that are off the map, blocked, or occupied (draw these red).
    public let badTiles: [GridPoint]

    public var isValid: Bool { problem == nil }
}

enum PlacementRules {
    /// Checks only the ground: on the map, buildable, no decoration, no other building (except `ignoring`).
    static func footprintProblem(def: BuildingDef, origin: GridPoint, base: Base, map: MapDef,
                                 content: GameContent, ignoring: BuildingID?) -> (PlacementProblem?, [GridPoint]) {
        let tiles = origin.footprintTiles(width: def.width, height: def.height)
        let decorations = map.decorationTiles
        var occupiedTiles = Set<GridPoint>()
        for b in base.buildings where b.id != ignoring {
            guard let other = content.buildingDef(b.defId) else { continue }
            occupiedTiles.formUnion(b.origin.footprintTiles(width: other.width, height: other.height))
        }
        var problem: PlacementProblem?
        var bad: [GridPoint] = []
        for t in tiles {
            let found: PlacementProblem?
            if !map.contains(t) { found = .offMap }
            else if map.tile(at: t)?.buildable != true || decorations.contains(t) { found = .blockedTerrain }
            else if occupiedTiles.contains(t) { found = .occupied }
            else { found = nil }
            if let found {
                bad.append(t)
                if problem == nil { problem = found }
            }
        }
        return (problem, bad)
    }

    /// Checks the rules for building a new one (limit, HQ level, prerequisites, cost); ignores the ground.
    static func ruleProblem(def: BuildingDef, state: GameState, content: GameContent) -> PlacementProblem? {
        let base = state.base
        guard let level1 = def.level(1) else { return .unknownBuilding(def.id) }
        let hqLevel = base.hqLevel
        if hqLevel < level1.requiredHq { return .needsHqLevel(level1.requiredHq) }
        let limitIndex = max(0, min(hqLevel, def.maxCountByHq.count) - 1)
        let limit = def.maxCountByHq[limitIndex]
        let countKey = def.sharesCountWith ?? def.id
        let count = base.buildings.filter { b in
            let key = content.buildingDef(b.defId)?.sharesCountWith ?? b.defId
            return key == countKey
        }.count
        if count >= limit { return .limitReached(max: limit) }
        if let req = def.requires {
            if let needed = req.building {
                let level = req.level ?? 1
                let has = base.buildings.contains { $0.defId == needed && $0.isComplete && $0.level >= level }
                if !has { return .needsBuilding(needed, level: level) }
            }
            if let research = req.research, !state.group.knowledge.contains(research) {
                return .needsResearch(research)
            }
        }
        if !base.stock.covers(level1.cost) { return .notEnoughResources(needed: level1.cost) }
        return nil
    }
}
