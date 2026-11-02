// Purpose: Tests the look-only survivor stroll routes (open tiles, radius, seeded). Notes: docs/features/characters-3d.md
import Testing
@testable import HoldoutCore

struct SurvivorWander3DTests {
    private func setup() throws -> (GameState, GameContent) {
        let loop = try TestSupport.loop(seed: 7)
        return (loop.state, loop.content)
    }

    @Test func buildingsAreNotWalkable() throws {
        let (state, content) = try setup()
        let grid = SurvivorWalkGrid(state: state, content: content)
        let hq = try #require(state.base.buildings.first { $0.defId == "hq" })
        #expect(!grid.isOpen(hq.origin))
        let near = try #require(grid.nearestOpen(to: hq.origin))
        #expect(grid.isOpen(near))
    }

    @Test func routeStepsAreOpenAdjacentAndInRadius() throws {
        let (state, content) = try setup()
        let grid = SurvivorWalkGrid(state: state, content: content)
        let hq = try #require(state.base.buildings.first { $0.defId == "hq" })
        let start = try #require(grid.nearestOpen(to: hq.origin))
        var random = SeededRandom(seed: 1)
        for _ in 0..<20 {
            let path = SurvivorWander3D.route(grid: grid, from: start, around: hq.origin, radius: 6, random: &random)
            #expect(!path.isEmpty)
            var previous = start
            for p in path {
                #expect(grid.isOpen(p))
                #expect(abs(p.x - previous.x) + abs(p.y - previous.y) == 1)
                previous = p
            }
            let end = try #require(path.last)
            #expect(max(abs(end.x - hq.origin.x), abs(end.y - hq.origin.y)) <= 6)
        }
    }

    @Test func sameSeedSameRoute() throws {
        let (state, content) = try setup()
        let grid = SurvivorWalkGrid(state: state, content: content)
        let hq = try #require(state.base.buildings.first { $0.defId == "hq" })
        let start = try #require(grid.nearestOpen(to: hq.origin))
        var a = SeededRandom(seed: 42), b = SeededRandom(seed: 42)
        #expect(SurvivorWander3D.route(grid: grid, from: start, around: hq.origin, radius: 8, random: &a)
                == SurvivorWander3D.route(grid: grid, from: start, around: hq.origin, radius: 8, random: &b))
    }

    @Test func blockedStartGivesNoRoute() throws {
        let (state, content) = try setup()
        let grid = SurvivorWalkGrid(state: state, content: content)
        let hq = try #require(state.base.buildings.first { $0.defId == "hq" })
        var random = SeededRandom(seed: 3)
        #expect(SurvivorWander3D.route(grid: grid, from: hq.origin, around: hq.origin, radius: 8, random: &random).isEmpty)
    }
}
