// Purpose: Tests which zombie a tower picks: nearest-to-HQ vs nearest, range, ties, dead zombies. Notes: docs/features/combat.md
import Testing
@testable import HoldoutCore

struct TargetingSystemTests {
    private let content: GameContent
    init() throws { content = try TestSupport.content() }

    private func def(_ id: String) throws -> BuildingDef { try #require(content.buildingDef(id)) }
    private func range(_ id: String, level: Int = 1) throws -> Double {
        try #require(def(id).level(level)?.effects.range)
    }

    /// A 1×1 tower at (10, 10): its middle is (10.5, 10.5).
    private let spot = GridPoint(x: 10, y: 10)
    private func zombie(_ id: Int, dx: Double, dy: Double = 0, hp: Double = 100) -> Zombie {
        Zombie(id: id, defId: "walker", x: 10.5 + dx, y: 10.5 + dy, hp: hp)
    }

    private func pick(_ defId: String, _ zombies: [Zombie], distanceToHQ: (GridPoint) -> Double = { _ in 0 }) throws -> ZombieID? {
        let d = try def(defId)
        let tower = CombatFixtures.tower(id: 1, def: d, at: spot)
        return TargetingSystem.target(for: tower, def: d, range: try range(defId), zombies: zombies, distanceToHQ: distanceToHQ)
    }

    @Test func nearestToHQPicksLowestPathDistanceEvenIfFartherFromTower() throws {
        #expect(try def("watchtower").targeting == "single_nearest_to_hq")
        let near = zombie(1, dx: 1)   // 1 tile from the tower
        let far = zombie(2, dx: 4)    // 4 tiles from the tower, but closer to the HQ by path
        let pathDistance: (GridPoint) -> Double = { $0 == far.tile ? 3 : 20 }
        #expect(try pick("watchtower", [near, far], distanceToHQ: pathDistance) == 2)
    }

    @Test func nearestPicksPhysicallyClosestAndIgnoresPathDistance() throws {
        #expect(try def("mg_nest").targeting == "single_nearest")
        let closer = zombie(9, dx: 0, dy: 1)
        let farther = zombie(4, dx: 2)
        let pathDistance: (GridPoint) -> Double = { $0 == farther.tile ? 0 : 50 }
        #expect(try pick("mg_nest", [farther, closer], distanceToHQ: pathDistance) == 9)
    }

    @Test(arguments: ["watchtower", "mg_nest"])
    func rangeIsRespected(defId: String) throws {
        let r = try range(defId)
        #expect(try pick(defId, [zombie(1, dx: r + 0.05)]) == nil)
        #expect(try pick(defId, [zombie(1, dx: 0, dy: -r)]) == 1)      // exactly at range counts
        #expect(try pick(defId, [zombie(1, dx: r * 0.6, dy: r * 0.6)]) == 1) // diagonal, √0.72·r < r
    }

    @Test(arguments: ["watchtower", "mg_nest"])
    func deadZombiesAreSkipped(defId: String) throws {
        let dead = zombie(1, dx: 0.5, hp: 0)
        let alive = zombie(2, dx: 1.5)
        #expect(try pick(defId, [dead, alive]) == 2)
        #expect(try pick(defId, [dead]) == nil)
    }

    @Test(arguments: ["watchtower", "mg_nest"])
    func tiesGoToLowerZombieID(defId: String) throws {
        #expect(try pick(defId, [zombie(7, dx: 1), zombie(3, dx: 1), zombie(5, dx: 1)]) == 3)
    }

    @Test func unknownOrMissingTargetingBehavesLikeNearest() {
        #expect(TargetingMode("single_nearest_to_hq") == .nearestToHQ)
        #expect(TargetingMode("single_nearest") == .nearest)
        #expect(TargetingMode("splash_everything") == .nearest)
        #expect(TargetingMode(nil) == .nearest)
    }

    @Test func rangeIsMeasuredFromTheMiddleOfTheFootprint() throws {
        let hq = try def("hq")
        let c = TargetingSystem.center(of: CombatFixtures.tower(id: 1, def: hq, at: spot), def: hq)
        #expect(c.x == 10 + Double(hq.width) / 2)
        #expect(c.y == 10 + Double(hq.height) / 2)
    }
}
