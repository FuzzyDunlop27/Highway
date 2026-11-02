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
        var steps = SaveMigrations.steps  // the real later steps still run after the pretend v0 → v1 one
        steps[0] = { json in json["state"] = json.removeValue(forKey: "game") }
        let state = try SaveCodec.decode(data, migrations: steps)
        #expect(state == (try TestSupport.loop().state))
        #expect(throws: SaveError.missingMigration(from: 0)) { try SaveCodec.decode(data, migrations: [:]) }
    }

    @Test func version1SaveMigratesToVersion2() throws {
        // Build a v1 save: today's JSON without the 1B fields.
        let loop = try TestSupport.loop()
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        var json = try JSONSerialization.jsonObject(with: SaveCodec.encode(loop.state)) as! [String: Any]
        var state = json["state"] as! [String: Any]
        var bases = state["bases"] as! [[String: Any]]
        bases[0].removeValue(forKey: "zombies")
        bases[0].removeValue(forKey: "horde")
        bases[0]["buildings"] = (bases[0]["buildings"] as! [[String: Any]]).map { b in var b = b; b.removeValue(forKey: "isRubble"); return b }
        state["bases"] = bases
        json["state"] = state
        json["version"] = 1
        let decoded = try SaveCodec.decode(JSONSerialization.data(withJSONObject: json))
        // The half-built farm comes through as a running (already paid) build job.
        #expect(decoded.base.buildings == loop.state.base.buildings)
        #expect(decoded.base.jobs.count == 1 && decoded.base.jobs[0].started && decoded.base.jobs[0].cost == .zero)
        #expect(decoded.base.horde == .initial && decoded.base.zombies.isEmpty)
        #expect(decoded.base.buildings.allSatisfy { !$0.isRubble })
    }

    // MARK: Chunk 2B / 2C migrations (v3 → v4 → v5)

    /// Today's save turned back into what a v3 save looked like: no defenders, training, runs, or the new building fields.
    private func version3Save(of loop: GameLoop) throws -> Data {
        var json = try JSONSerialization.jsonObject(with: SaveCodec.encode(loop.state)) as! [String: Any]
        var state = json["state"] as! [String: Any]
        var bases = state["bases"] as! [[String: Any]]
        for key in ["defenders", "nextDefenderID", "training", "runs", "research"] { bases[0].removeValue(forKey: key) }
        bases[0]["buildings"] = (bases[0]["buildings"] as! [[String: Any]]).map { b in
            var b = b; for key in ["assignedWorkers", "heldReward", "facing"] { b.removeValue(forKey: key) }; return b
        }
        state["bases"] = bases
        json["state"] = state
        json["version"] = 3
        return try JSONSerialization.data(withJSONObject: json)
    }

    @Test func version3SaveMigratesToTheJobsAndResearchVersion() throws {
        let loop = try TestSupport.loop()
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        loop.step(ticks: 300)
        let decoded = try SaveCodec.decode(version3Save(of: loop))
        #expect(decoded == loop.state)  // nothing lost; the new parts start empty and auto-staffing is unchanged
        #expect(decoded.base.defenders.isEmpty && decoded.base.training.isEmpty && decoded.base.runs.isEmpty)
        #expect(decoded.base.nextDefenderID == 1 && decoded.base.research == nil)
        let resumed = try GameLoop(content: loop.content, state: decoded)
        resumed.step(ticks: 600)
        loop.step(ticks: 600)
        #expect(resumed.state == loop.state)
    }

    @Test func version4SaveGainsTheRunsList() throws {
        let loop = try TestSupport.loop()
        var json = try JSONSerialization.jsonObject(with: version3Save(of: loop)) as! [String: Any]
        var state = json["state"] as! [String: Any]
        var bases = state["bases"] as! [[String: Any]]
        bases[0]["defenders"] = [Any](); bases[0]["nextDefenderID"] = 1; bases[0]["training"] = [Any]()
        state["bases"] = bases
        json["state"] = state
        json["version"] = 4
        let decoded = try SaveCodec.decode(JSONSerialization.data(withJSONObject: json))
        #expect(decoded == loop.state)
    }

    // MARK: Ticket CORE-010 migration (v5 → v6)

    /// A v5 save: buildings have no facing. A Shelter there was 2 × 2 at (8, 20).
    @Test func version5SaveFacesSouthAndOldTwoByTwoShrinksInPlace() throws {
        let loop = try TestSupport.loop()
        loop.send(.placeBuilding(defId: "shelter", at: TestSupport.grassSpot))
        loop.step(ticks: 300)
        var json = try JSONSerialization.jsonObject(with: SaveCodec.encode(loop.state)) as! [String: Any]
        var state = json["state"] as! [String: Any]
        var bases = state["bases"] as! [[String: Any]]
        bases[0]["buildings"] = (bases[0]["buildings"] as! [[String: Any]]).map { b in
            var b = b; b.removeValue(forKey: "facing"); return b
        }
        state["bases"] = bases
        json["state"] = state
        json["version"] = 5
        let decoded = try SaveCodec.decode(JSONSerialization.data(withJSONObject: json))
        #expect(decoded == loop.state)
        #expect(decoded.base.buildings.allSatisfy { $0.facing == .south })
        let shelter = try #require(decoded.base.buildings.first { $0.defId == "shelter" })
        #expect(shelter.origin == TestSupport.grassSpot)
        // The old bottom row of its 2 × 2 spot is free ground now.
        let resumed = try GameLoop(content: loop.content, state: decoded)
        #expect(resumed.building(at: GridPoint(x: 8, y: 21)) == nil)
        #expect(resumed.checkPlacement(defId: "wall_wood", at: GridPoint(x: 9, y: 21)).isValid)
    }
}
