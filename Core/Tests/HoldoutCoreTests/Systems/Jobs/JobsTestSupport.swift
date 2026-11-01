// Purpose: Test helpers for jobs, defenders, scavenging and research: a quiet town with chosen buildings. Notes: docs/features/jobs-defenders.md
import Foundation
@testable import HoldoutCore

enum JobsTestSupport {
    /// HQ plus the listed finished buildings, no walls or towers, a horde clock set far away. Staffing is up to date.
    static func loop(_ buildings: [(String, GridPoint)] = [], survivors: Int = 10, stock: Cost = Cost(scrap: 500, food: 500),
                     adjust: (inout GameState) -> Void = { _ in }) throws -> GameLoop {
        let content = try TestSupport.content()
        var state = try CombatTestSupport.hqOnlyState(content: content)
        for (defId, origin) in buildings {
            CombatTestSupport.addBuilding(defId, at: origin, state: &state, content: content)
        }
        state.group.survivors = survivors
        state.base.stock = stock
        state.base.horde.ticksUntilNext = 1_000_000
        adjust(&state)
        let loop = try GameLoop(content: content, state: state)
        loop.step()
        return loop
    }

    static let barracksSpot = GridPoint(x: 8, y: 22)
    static let workshopSpot = GridPoint(x: 12, y: 22)
    static let postSpot = GridPoint(x: 16, y: 22)
    static let farmSpot = GridPoint(x: 8, y: 26)
    static let towerSpot = GridPoint(x: 8, y: 20)

    static func building(_ loop: GameLoop, _ defId: String) -> Building { loop.state.base.buildings.first { $0.defId == defId }! }

    /// Ticks for `seconds` of in-game time.
    static func ticks(_ seconds: Double, _ loop: GameLoop) -> Int { loop.content.ticks(forSeconds: seconds) }

    /// Adds a zombie (very tough so it survives) at tile centre (x, y).
    @discardableResult
    static func addZombie(_ loop: GameLoop, x: Double, y: Double, id defId: String = "walker") throws -> (GameLoop, ZombieID) {
        var zid = 0
        let copy = try loop.edited { state in
            zid = CombatTestSupport.addZombie(defId, x: x, y: y, state: &state, content: loop.content)
            state.base.zombies[state.base.zombies.count - 1].hp = 1e9
        }
        return (copy, zid)
    }
}
