// Purpose: The 13 × 9 starting fence ring on both maps (closed, room inside) and that days 1–5 hordes still hit it. Notes: docs/features/construction.md
import Foundation
import Testing
@testable import HoldoutCore

struct StartingCompoundTests {
    @Test(arguments: ["phase1_chicago", "phase1_exit"])
    func fenceIsAClosedThirteenByNineRingWithRoomInside(mapId: String) throws {
        let content = try TestSupport.content()
        let state = try GameState.newGame(content: content, mapId: mapId, seed: 1)
        let map = try #require(content.maps[mapId])
        let walls = Set(state.base.buildings.filter { $0.defId == TestSupport.startingWall }.map(\.origin))
        let xs = walls.map(\.x), ys = walls.map(\.y)
        let minX = try #require(xs.min()), maxX = try #require(xs.max()), minY = try #require(ys.min()), maxY = try #require(ys.max())
        #expect(maxX - minX + 1 == 13 && maxY - minY + 1 == 9)
        var ring = Set<GridPoint>()
        for x in minX...maxX { ring.insert(GridPoint(x: x, y: minY)); ring.insert(GridPoint(x: x, y: maxY)) }
        for y in minY...maxY { ring.insert(GridPoint(x: minX, y: y)); ring.insert(GridPoint(x: maxX, y: y)) }
        #expect(walls == ring)
        // HQ and watchtower inside; the rest of the 11 × 7 inside is free buildable ground.
        let loop = try GameLoop(content: content, state: state)
        var free = 0
        for y in (minY + 1)..<maxY {
            for x in (minX + 1)..<maxX {
                let t = GridPoint(x: x, y: y)
                if loop.building(at: t) == nil, map.tile(at: t)?.buildable == true, !map.decorationTiles.contains(t) { free += 1 }
            }
        }
        #expect(free == 11 * 7 - 9 - 1)
        let hq = try #require(state.base.buildings.first { $0.defId == "hq" })
        #expect(hq.origin.x > minX && hq.origin.x + 2 < maxX && hq.origin.y > minY && hq.origin.y + 2 < maxY)
        // Room for at least six 2 × 1 buildings inside the fence (placed one after another by the spot finder).
        let fill = try GameLoop(content: content, state: state)
        fill.send(.debugAddResources(Cost(scrap: 2000, food: 2000)))
        var placedInside = 0
        for defId in ["shelter", "shelter", "scavenger", "scavenger", "workshop", "barracks"] {
            guard let spot = fill.suggestSpot(defId: defId, near: GridPoint(x: hq.origin.x + 1, y: hq.origin.y + 1)),
                  spot.x > minX, spot.x + 1 < maxX, spot.y > minY, spot.y < maxY,
                  case .success = fill.send(.placeBuilding(defId: defId, at: spot)) else { continue }
            placedInside += 1
        }
        #expect(placedInside == 6)
    }

    /// Balance check (balance.md): with the bigger, sturdier fence and nothing else built, days 1–5 still damage it.
    @Test(arguments: ["phase1_chicago", "phase1_exit"])
    func earlyHordesStillDamageTheFence(mapId: String) throws {
        let content = try TestSupport.content()
        for day in 1...5 {
            var state = try GameState.newGame(content: content, mapId: mapId, seed: UInt64(day))
            state.base.horde.day = day
            let loop = try GameLoop(content: content, state: state)
            let full = loop.content.buildingDef(TestSupport.startingWall)!.level(1)!.hp
            loop.send(.debugStartHorde)
            for _ in 0..<600 where loop.state.base.horde.active != nil { loop.step(ticks: 10) }
            let fence = loop.state.base.buildings.filter { $0.defId == TestSupport.startingWall }
            let lost = fence.reduce(0) { $0 + (full - $1.hp) } + (40 - fence.count) * full
            #expect(lost > 0, "day \(day) on \(mapId) never touched the fence")
        }
    }
}
