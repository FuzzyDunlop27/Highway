// Purpose: Tests save round-trip, version checks, and the migration hook. Notes: docs/features/save.md
import Foundation
import Testing
@testable import HoldoutCore

struct SaveCodecTests {
    @Test func roundTripKeepsEverything() throws {
        let loop = try TestSupport.loop()
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        loop.send(.placeBuilding(defId: "shelter", at: TestSupport.secondGrassSpot))
        loop.send(.setSpeed(2))
        loop.step(ticks: 1234) // leaves fractional production and a half-built shelter
        let data = try SaveCodec.encode(loop.state)
        #expect(try SaveCodec.decode(data) == loop.state)
    }

    @Test func loadedGameKeepsTickingTheSame() throws {
        let original = try TestSupport.loop()
        original.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        original.step(ticks: 777)
        let reloaded = try GameLoop(content: original.content, state: SaveCodec.decode(SaveCodec.encode(original.state)))
        original.step(ticks: 3000)
        reloaded.step(ticks: 3000)
        #expect(reloaded.state == original.state)
    }

    @Test func saveHasVersionNumber() throws {
        let json = try JSONSerialization.jsonObject(with: SaveCodec.encode(TestSupport.loop().state)) as? [String: Any]
        #expect(json?["version"] as? Int == SaveCodec.currentVersion)
    }

    @Test func newerSaveIsRejected() throws {
        let data = Data("{\"version\": 99, \"state\": {}}".utf8)
        #expect(throws: SaveError.newerVersion(99)) { try SaveCodec.decode(data) }
    }

    @Test func garbageIsNotASave() {
        #expect(throws: SaveError.notASave) { try SaveCodec.decode(Data("hello".utf8)) }
    }

    @Test func migrationHookRunsForOlderSaves() throws {
        // Pretend version 0 stored the game under "game"; a step renames it to "state".
        let current = try JSONSerialization.jsonObject(with: SaveCodec.encode(TestSupport.loop().state)) as! [String: Any]
        let old: [String: Any] = ["version": 0, "game": current["state"]!]
        let data = try JSONSerialization.data(withJSONObject: old)
        let steps: [Int: SaveMigrations.Step] = [0: { json in json["state"] = json.removeValue(forKey: "game") }]
        let state = try SaveCodec.decode(data, migrations: steps)
        #expect(state == (try TestSupport.loop().state))
        #expect(throws: SaveError.missingMigration(from: 0)) { try SaveCodec.decode(data, migrations: [:]) }
    }
}
