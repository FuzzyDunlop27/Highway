// Purpose: Shared test helpers: loads the repo's Content/ folder and makes test games. Notes: docs/features/core-api.md
import Foundation
@testable import HoldoutCore

enum TestSupport {
    /// The repo's `Content/` folder, found from this file's location (DECISIONS D-010).
    static let contentURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // HoldoutCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Core
        .deletingLastPathComponent() // repo root
        .appendingPathComponent("Content")

    static func content() throws -> GameContent { try ContentLoader.load(from: contentURL) }

    /// A fresh game on the Phase 1 map. `adjust` can tweak the state before the loop starts.
    static func loop(seed: UInt64 = 42, _ adjust: (inout GameState) -> Void = { _ in }) throws -> GameLoop {
        let content = try content()
        var state = try GameState.newGame(content: content, mapId: "phase1_exit", seed: seed)
        adjust(&state)
        return try GameLoop(content: content, state: state)
    }

    /// The wall type of the 40-wall (13 × 9) starting barricade (buildings.json startingLayout).
    static let startingWall = "wall_fence"

    /// Open grass, far from roads and the starting town: room for a 2×2.
    static let grassSpot = GridPoint(x: 8, y: 20)
    static let secondGrassSpot = GridPoint(x: 12, y: 20)

    /// Ticks for `seconds` of in-game time.
    static func ticks(_ seconds: Double, _ loop: GameLoop) -> Int { loop.content.ticks(forSeconds: seconds) }
}
