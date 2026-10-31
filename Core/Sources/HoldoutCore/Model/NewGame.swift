// Purpose: Builds a fresh GameState from content (starting resources and starting layout). Notes: docs/features/core-api.md
import Foundation

public enum NewGameError: Error, Equatable, CustomStringConvertible {
    case unknownMap(String)
    case badStartingPosition(buildingId: String, at: GridPoint)

    public var description: String {
        switch self {
        case .unknownMap(let id): "No map with id '\(id)' in Content/maps/"
        case .badStartingPosition(let id, let p): "Starting '\(id)' at (\(p.x),\(p.y)) is blocked or off the map"
        }
    }
}

extension GameState {
    /// A fresh game on `mapId`: starting food/scrap/survivors from resources.json and the
    /// finished starting layout from buildings.json at the map's startingPositions.
    public static func newGame(content: GameContent, mapId: String, seed: UInt64) throws -> GameState {
        guard let map = content.maps[mapId] else { throw NewGameError.unknownMap(mapId) }
        let res = content.resources
        var base = Base(mapId: mapId, stock: Cost(scrap: res.def(.scrap)?.starting ?? 0, food: res.def(.food)?.starting ?? 0))
        for entry in content.buildings.startingLayout {
            guard let def = content.buildingDef(entry.id), let level = def.level(entry.level) else { continue }
            for spot in map.startingPositions where spot.id == entry.id {
                let origin = GridPoint(x: spot.x, y: spot.y)
                let (problem, _) = PlacementRules.footprintProblem(def: def, origin: origin, base: base, map: map,
                                                                    content: content, ignoring: nil)
                if problem != nil { throw NewGameError.badStartingPosition(buildingId: entry.id, at: origin) }
                // Starting buildings are free, so `invested` is zero (no refund, no town value).
                base.buildings.append(Building(id: base.nextBuildingID, defId: def.id, level: entry.level, origin: origin,
                                               hp: level.hp, constructionTicksLeft: 0, constructionTicksTotal: 0, invested: .zero))
                base.nextBuildingID += 1
            }
        }
        let survivors = res.resources.first { $0.id == "survivors" }?.starting ?? 0
        var state = GameState(tick: 0, speed: 1, random: SeededRandom(seed: seed), group: Group(survivors: survivors),
                              bases: [base], activeBaseIndex: 0)
        Staffing.assign(&state, content: content)
        return state
    }
}
