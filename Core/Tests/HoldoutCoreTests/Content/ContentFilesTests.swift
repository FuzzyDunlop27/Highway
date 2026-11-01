// Purpose: Every Content/*.json decodes and passes validation; bad data fails loudly. Notes: docs/features/core-api.md
import Foundation
import Testing
@testable import HoldoutCore

struct ContentFilesTests {
    @Test func everyContentFileDecodes() throws {
        let content = try TestSupport.content()
        #expect(content.economy.ticksPerSecond > 0)
        #expect(content.allBuildingDefs.count == content.buildings.buildings.count + content.buildings.defenses.count)
        #expect(!content.units.units.isEmpty)
        #expect(!content.zombies.zombies.isEmpty)
        #expect(!content.hordes.composition.isEmpty)
        #expect(content.research.items.count == 3)
        #expect(content.offline.timeFactor.maxOfflineCreditHours > 0)
        #expect(content.maps["phase1_exit"] != nil)
        #expect(content.presentation.reality3d.metresPerTile > 0)
    }

    @Test func noContentFileIsLeftUnread() throws {
        let known: Set = ["resources.json", "buildings.json", "units.json", "zombies.json",
                          "hordes.json", "research.json", "offline.json", "economy.json",
                          "presentation.json"]
        let files = try FileManager.default.contentsOfDirectory(atPath: TestSupport.contentURL.path)
            .filter { $0.hasSuffix(".json") }
        #expect(Set(files) == known, "A new Content/*.json file needs a Codable def and a line in ContentLoader")
    }

    @Test func phase1MapIsAbout40By30WithHighwayAndSpawnEdges() throws {
        let map = try #require(try TestSupport.content().maps["phase1_exit"])
        #expect(map.width == 40 && map.height == 30)
        #expect(map.tile(at: GridPoint(x: 10, y: 2))?.buildable == false)
        #expect(map.spawnEdges.count == 4)
    }

    @Test func badJSONFailsWithFileName() throws {
        let dir = try copyOfContent()
        try Data("{ \"schemaVersion\": 1 }".utf8).write(to: dir.appendingPathComponent("zombies.json"))
        #expect {
            try ContentLoader.load(from: dir)
        } throws: { error in
            guard case ContentError.badJSON(let file, let detail) = error else { return false }
            return file == "zombies.json" && detail.contains("zombies")
        }
    }

    @Test func crossFileMistakeFailsValidation() throws {
        let dir = try copyOfContent()
        let url = dir.appendingPathComponent("hordes.json")
        let text = try String(contentsOf: url, encoding: .utf8).replacingOccurrences(of: "side_road_south", with: "nowhere")
        try Data(text.utf8).write(to: url)
        #expect(throws: ContentError.self) { try ContentLoader.load(from: dir) }
    }

    @Test func cameraSnapsToFourAnglesAndBadCameraFailsValidation() throws {
        let content = try TestSupport.content()
        #expect(content.presentation.reality3d.camera.snapAngles == 4)  // D-029
        let dir = try copyOfContent()
        let url = dir.appendingPathComponent("presentation.json")
        let text = try String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "\"minPitchDegrees\": 25", with: "\"minPitchDegrees\": 80")
        try Data(text.utf8).write(to: url)
        #expect(throws: ContentError.self) { try ContentLoader.load(from: dir) }
    }

    @Test func missingFileFails() throws {
        let dir = try copyOfContent()
        try FileManager.default.removeItem(at: dir.appendingPathComponent("units.json"))
        #expect(throws: ContentError.missingFile("units.json")) { try ContentLoader.load(from: dir) }
    }

    private func copyOfContent() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("content-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: TestSupport.contentURL, to: dir)
        return dir
    }
}
