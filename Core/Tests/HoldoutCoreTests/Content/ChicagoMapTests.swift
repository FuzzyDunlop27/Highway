// Purpose: The Chicago neighborhood map (phase1_chicago): starts a game, every horde edge reaches the town, decoration facing. Notes: docs/features/construction.md
import Foundation
import Testing
@testable import HoldoutCore

struct ChicagoMapTests {
    private let mapId = "phase1_chicago"

    @Test func newGameStartsBehindTheBarricadeRing() throws {
        let content = try TestSupport.content()
        let state = try GameState.newGame(content: content, mapId: mapId, seed: 1)
        let walls = state.base.buildings.filter { $0.defId == TestSupport.startingWall }
        #expect(walls.count == 28)
        #expect(state.base.buildings.contains { $0.defId == "hq" && $0.origin == GridPoint(x: 15, y: 16) })
        #expect(state.base.buildings.contains { $0.defId == "watchtower" })
    }

    @Test func everySpawnEdgeCanReachTheHQ() throws {
        let content = try TestSupport.content()
        let state = try GameState.newGame(content: content, mapId: mapId, seed: 1)
        let map = try #require(content.maps[mapId])
        for zombie in content.zombies.zombies {
            let field = FlowField(state: state, content: content, weight: zombie.pathCostWeight)
            for edge in map.spawnEdges {
                for tile in GridPoint(x: edge.x, y: edge.y).footprintTiles(width: edge.w, height: edge.h) {
                    #expect(field.distance(at: tile).isFinite, "\(zombie.id) can't reach the HQ from \(edge.id) \(tile)")
                }
            }
        }
    }

    @Test func zombieFromTheArterialBreaksIntoTheTown() throws {
        let content = try TestSupport.content()
        var state = try GameState.newGame(content: content, mapId: mapId, seed: 1)
        CombatTestSupport.addZombie("walker", x: 0.5, y: 6.5, state: &state, content: content)
        CombatTestSupport.runMovement(&state, ticks: content.ticks(forSeconds: 120), content: content)
        #expect(state.base.zombies[0].attacking != nil)
    }

    @Test func decorationsCanFaceAnyWayAndBadFacingFailsValidation() throws {
        let map = try #require(try TestSupport.content().maps[mapId])
        let turns = Set(map.decorations.map(\.quarterTurns))
        #expect(turns.isSuperset(of: [0, 1, 2, 3]))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("content-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: TestSupport.contentURL, to: dir)
        let url = dir.appendingPathComponent("maps/phase1_chicago.json")
        let text = try String(contentsOf: url, encoding: .utf8).replacingOccurrences(of: "\"faces\": \"west\"", with: "\"faces\": \"up\"")
        try Data(text.utf8).write(to: url)
        #expect(throws: ContentError.self) { try ContentLoader.load(from: dir) }
    }
}
