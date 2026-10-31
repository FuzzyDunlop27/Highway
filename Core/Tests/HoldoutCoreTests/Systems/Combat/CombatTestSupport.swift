// Purpose: Test helpers for pathing and zombie movement: clear the town, add walls/traps/zombies, run ticks. Notes: docs/features/pathing.md
import Foundation
@testable import HoldoutCore

enum CombatTestSupport {
    /// The HQ's top-left tile on the Phase 1 map (its 3×3 footprint covers x 22...24, y 18...20).
    static let hqOrigin = GridPoint(x: 22, y: 18)

    /// A fresh Phase 1 game with only the HQ left standing (no starting walls or watchtower).
    static func hqOnlyState(content: GameContent, seed: UInt64 = 42) throws -> GameState {
        var state = try GameState.newGame(content: content, mapId: "phase1_exit", seed: seed)
        state.base.buildings.removeAll { $0.defId != "hq" }
        return state
    }

    /// Adds a finished building at `origin` (full hp unless `hp` is given) and returns its id.
    @discardableResult
    static func addBuilding(_ defId: String, at origin: GridPoint, hp: Int? = nil, rubble: Bool = false,
                            state: inout GameState, content: GameContent) -> BuildingID {
        let def = content.buildingDef(defId)!
        let id = state.base.nextBuildingID
        state.base.buildings.append(Building(id: id, defId: defId, level: 1, origin: origin, hp: hp ?? def.level(1)!.hp,
                                             constructionTicksLeft: 0, constructionTicksTotal: 0, invested: .zero,
                                             isRubble: rubble))
        state.base.nextBuildingID += 1
        return id
    }

    /// Rings the HQ with 1×1 `defId` walls (the 16 tiles around its 3×3 footprint). Returns tile → id.
    @discardableResult
    static func ringHQ(with defId: String, state: inout GameState, content: GameContent) -> [GridPoint: BuildingID] {
        var ids: [GridPoint: BuildingID] = [:]
        for y in (hqOrigin.y - 1)...(hqOrigin.y + 3) {
            for x in (hqOrigin.x - 1)...(hqOrigin.x + 3) where x == hqOrigin.x - 1 || x == hqOrigin.x + 3
                || y == hqOrigin.y - 1 || y == hqOrigin.y + 3 {
                let p = GridPoint(x: x, y: y)
                ids[p] = addBuilding(defId, at: p, state: &state, content: content)
            }
        }
        return ids
    }

    /// Adds a zombie with full hp at (x, y) in tiles and returns its id.
    @discardableResult
    static func addZombie(_ defId: String, x: Double, y: Double, state: inout GameState, content: GameContent) -> ZombieID {
        let def = content.zombies.zombies.first { $0.id == defId }!
        let id = state.base.horde.nextZombieID
        state.base.zombies.append(Zombie(id: id, defId: defId, x: x, y: y, hp: Double(def.hp)))
        state.base.horde.nextZombieID += 1
        return id
    }

    static func zombieDef(_ id: String, _ content: GameContent) -> ZombieDef {
        content.zombies.zombies.first { $0.id == id }!
    }

    /// Runs only ZombieMovement for `ticks` ticks (no towers, no clean-up), advancing the clock. Returns the events.
    @discardableResult
    static func runMovement(_ state: inout GameState, ticks: Int, content: GameContent,
                            fields: FlowFieldCache = FlowFieldCache()) -> [SimEvent] {
        var events: [SimEvent] = []
        for _ in 0..<ticks {
            ZombieMovement.tick(&state, content: content, fields: fields, events: &events)
            state.tick += 1
        }
        return events
    }

    /// The tiles a zombie on `start` would walk through (start included), following nextStep until it stops.
    static func path(from start: GridPoint, field: FlowField, limit: Int = 500) -> [GridPoint] {
        var tiles = [start]
        while tiles.count < limit, let next = field.nextStep(from: tiles.last!) { tiles.append(next) }
        return tiles
    }
}
