// Purpose: Tests GameLoop.suggestSpot: nearest spot where a building fits, turned footprints, moving, nothing fits. Notes: docs/features/construction.md
import Foundation
import Testing
@testable import HoldoutCore

struct SpotFinderTests {
    /// Twice the distance from a footprint's middle to `near`, squared (same yardstick as the spot finder).
    private func distance(_ origin: GridPoint, size: (width: Int, height: Int), near: GridPoint) -> Int {
        let dx = 2 * origin.x + size.width - 1 - 2 * near.x, dy = 2 * origin.y + size.height - 1 - 2 * near.y
        return dx * dx + dy * dy
    }

    /// Checks the answer fits and that no spot within the radius that fits is any closer.
    private func expectNearest(_ loop: GameLoop, defId: String, facing: Facing, near: GridPoint, ignoring: BuildingID? = nil) throws {
        let found = try #require(loop.suggestSpot(defId: defId, facing: facing, near: near, ignoring: ignoring))
        let def = try #require(loop.content.buildingDef(defId))
        let map = loop.map
        let size = def.size(facing: facing)
        let fits = { (o: GridPoint) in
            PlacementRules.footprintProblem(def: def, origin: o, facing: facing, base: loop.state.base, map: map,
                                            content: loop.content, ignoring: ignoring).0 == nil
        }
        #expect(fits(found))
        let best = distance(found, size: size, near: near)
        let r = loop.content.buildings.rules.suggestSpotRadiusTiles + 2
        for y in (near.y - r)...(near.y + r) {
            for x in (near.x - r)...(near.x + r) {
                let o = GridPoint(x: x, y: y)
                if fits(o) { #expect(distance(o, size: size, near: near) >= best, "\(o) is closer than \(found)") }
            }
        }
    }

    @Test func onOpenGroundTheBuildingCoversTheAskedTile() throws {
        let loop = try TestSupport.loop()
        let near = TestSupport.grassSpot
        #expect(loop.suggestSpot(defId: "wall_wood", near: near) == near)
        let shelter = try #require(loop.suggestSpot(defId: "shelter", near: near))
        #expect(loop.content.buildingDef("shelter")!.footprintTiles(at: shelter, facing: .south).contains(near))
        let turned = try #require(loop.suggestSpot(defId: "shelter", facing: .east, near: near))
        #expect(loop.content.buildingDef("shelter")!.footprintTiles(at: turned, facing: .east).contains(near))
    }

    @Test func aBlockedTileGivesTheNearestSpotThatFits() throws {
        let loop = try TestSupport.loop()
        let onHQ = GridPoint(x: 23, y: 19)  // middle of the starting HQ
        for facing in [Facing.south, .east] {
            try expectNearest(loop, defId: "storage", facing: facing, near: onHQ)
        }
        try expectNearest(loop, defId: "farm", facing: .south, near: onHQ)
        try expectNearest(loop, defId: "hq", facing: .south, near: GridPoint(x: 15, y: 2))  // on the highway
    }

    @Test func sameTownGivesTheSameAnswer() throws {
        let a = try TestSupport.loop(), b = try TestSupport.loop()
        #expect(a.suggestSpot(defId: "barracks", near: GridPoint(x: 23, y: 19)) == b.suggestSpot(defId: "barracks", near: GridPoint(x: 23, y: 19)))
    }

    @Test func movingABuildingCanReuseItsOwnSpot() throws {
        let loop = try TestSupport.loop()
        let near = TestSupport.grassSpot
        guard case .success(.placed(let id)) = loop.send(.placeBuilding(defId: "shelter", at: near)) else {
            Issue.record("placement failed"); return
        }
        #expect(loop.suggestSpot(defId: "shelter", near: near) != near)
        #expect(loop.suggestSpot(defId: "shelter", near: near, ignoring: id) == GridPoint(x: near.x - 1, y: near.y) ||
                loop.suggestSpot(defId: "shelter", near: near, ignoring: id) == near)
        try expectNearest(loop, defId: "shelter", facing: .south, near: near, ignoring: id)
    }

    @Test func nothingInReachGivesNil() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("content-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: TestSupport.contentURL, to: dir)
        let url = dir.appendingPathComponent("buildings.json")
        let text = try String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "\"suggestSpotRadiusTiles\": 12", with: "\"suggestSpotRadiusTiles\": 1")
        try Data(text.utf8).write(to: url)
        let content = try ContentLoader.load(from: dir)
        let loop = try GameLoop(content: content, state: GameState.newGame(content: content, mapId: "phase1_exit", seed: 1))
        #expect(loop.suggestSpot(defId: "wall_wood", near: GridPoint(x: 15, y: 2)) == nil)  // middle of the highway
        #expect(loop.suggestSpot(defId: "nope", near: TestSupport.grassSpot) == nil)
    }
}
