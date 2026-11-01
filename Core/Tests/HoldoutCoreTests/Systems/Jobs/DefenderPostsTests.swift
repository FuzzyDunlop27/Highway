// Purpose: Tests garrisons (worker + damage boost), holding a spot, knock-out and return, and zombies hurting defenders. Notes: docs/features/jobs-defenders.md
import Foundation
import Testing
@testable import HoldoutCore

struct DefenderPostsTests {
    private typealias S = JobsTestSupport
    private let unitHp = 120

    private func withDefender(_ buildings: [(String, GridPoint)] = [], survivors: Int = 10,
                              post: Defender.Post = .hq) throws -> GameLoop {
        try S.loop(buildings, survivors: survivors) { $0.base.defenders = [Defender(id: 1, hp: 120, post: post)]; $0.base.nextDefenderID = 2 }
    }

    // MARK: Garrison

    @Test func aGarrisonedDefenderIsTheTowersWorker() throws {
        let loop = try withDefender([("watchtower", S.towerSpot)], survivors: 1)  // the only survivor is the defender
        let tower = S.building(loop, "watchtower").id
        #expect(S.building(loop, "watchtower").staffed == 0)
        #expect(loop.send(.garrison(defender: 1, in: tower)) == .success(.defenderPosted))
        #expect(S.building(loop, "watchtower").staffed == 1)
        #expect(loop.population.working == 0 && loop.population.defenders == 1)
        #expect(loop.send(.recallDefender(1)) == .success(.defenderPosted))
        #expect(S.building(loop, "watchtower").staffed == 0)
    }

    @Test func garrisoningFreesTheCivilianWhoWorkedTheTower() throws {
        let loop = try withDefender([("watchtower", S.towerSpot)], survivors: 3)
        #expect(loop.population.working == 1)
        loop.send(.garrison(defender: 1, in: S.building(loop, "watchtower").id))
        #expect(loop.population.working == 0)
        #expect(loop.population.idle == 2)
    }

    @Test func garrisonedTowerHitsHarderAndFiresWithoutCivilians() throws {
        func damageDealt(garrisoned: Bool) throws -> Double {
            var loop = try withDefender([("watchtower", S.towerSpot)], survivors: 1)
            if garrisoned { loop.send(.garrison(defender: 1, in: S.building(loop, "watchtower").id)) }
            (loop, _) = try S.addZombie(loop, x: 10.5, y: 20.5)
            let before = loop.state.base.zombies[0].hp
            loop.step(ticks: 10)
            return before - loop.state.base.zombies[0].hp
        }
        let plain = try damageDealt(garrisoned: false)
        let boosted = try damageDealt(garrisoned: true)
        let tower = try S.loop().content.buildingDef("watchtower")!.level(1)!.effects
        let multiplier = try S.loop().content.units.units.compactMap(\.garrison).first!.towerDamageMultiplier
        #expect(plain == 0)  // the only survivor is a defender not in the tower: nobody staffs it
        #expect(boosted == (tower.damage ?? 0) * multiplier * (tower.fireRate ?? 1))
    }

    @Test func garrisonRules() throws {
        let loop = try withDefender([("watchtower", S.towerSpot), ("farm", S.farmSpot)])
        let tower = S.building(loop, "watchtower").id, farm = S.building(loop, "farm").id
        #expect(loop.send(.garrison(defender: 1, in: farm)) == .failure(.defender(.notAGarrisonBuilding)))
        #expect(loop.send(.garrison(defender: 9, in: tower)) == .failure(.defender(.unknownDefender)))
        #expect(loop.send(.garrison(defender: 1, in: 999)) == .failure(.defender(.unknownBuilding)))
        #expect(loop.send(.garrison(defender: 1, in: tower)).isSuccess)
        let two = try loop.edited { $0.base.defenders.append(Defender(id: 2, hp: 120)) }
        #expect(two.send(.garrison(defender: 2, in: tower)) == .failure(.defender(.garrisonFull)))
        let unfinished = try loop.edited { state in
            let i = state.base.buildings.firstIndex { $0.id == tower }!
            state.base.buildings[i].constructionTicksLeft = 50
            state.base.defenders[0].post = .hq
        }
        #expect(unfinished.send(.garrison(defender: 1, in: tower)) == .failure(.defender(.buildingNotFinished)))
    }

    @Test func aTowerThatFallsReleasesItsDefender() throws {
        let loop = try withDefender([("watchtower", S.towerSpot)])
        loop.send(.garrison(defender: 1, in: S.building(loop, "watchtower").id))
        let broken = try loop.edited { state in
            let i = state.base.buildings.firstIndex { $0.defId == "watchtower" }!
            state.base.buildings[i].isRubble = true
        }
        broken.step()
        #expect(broken.state.base.defenders[0].post == .hq)
    }

    // MARK: Hold a spot

    @Test func aDefenderHoldingASpotShootsZombiesInRange() throws {
        var loop = try withDefender()
        loop.send(.holdSpot(defender: 1, at: GridPoint(x: 8, y: 20)))
        let unit = loop.content.units.units.first { $0.id == "defender" }!
        (loop, _) = try S.addZombie(loop, x: 10.5, y: 20.5)  // 2 tiles east, walking away from the defender: in range
        let before = loop.state.base.zombies[0].hp
        loop.step(ticks: S.ticks(3, loop))
        let shots = loop.drainEvents().filter { if case .defenderShot = $0 { true } else { false } }.count
        #expect(shots == Int(3 * (unit.fireRate ?? 1)))
        #expect(before - loop.state.base.zombies[0].hp == (unit.damage ?? 0) * Double(shots))
    }

    @Test func aDefenderIgnoresZombiesOutOfRange() throws {
        var loop = try withDefender()
        loop.send(.holdSpot(defender: 1, at: GridPoint(x: 8, y: 20)))
        let range = loop.content.units.units.first { $0.id == "defender" }!.range ?? 0
        (loop, _) = try S.addZombie(loop, x: 8.5 + range + 1, y: 20.5)
        let before = loop.state.base.zombies[0].hp
        loop.step(ticks: 30)
        #expect(loop.state.base.zombies[0].hp == before || loop.state.base.zombies[0].x != 8.5 + range + 1)
        #expect(!loop.drainEvents().contains { if case .defenderShot = $0 { true } else { false } })
    }

    @Test func holdSpotNeedsAMapTile() throws {
        let loop = try withDefender()
        #expect(loop.send(.holdSpot(defender: 1, at: GridPoint(x: -1, y: 3))) == .failure(.defender(.offMap)))
        #expect(loop.send(.holdSpot(defender: 1, at: GridPoint(x: 3, y: 3))) == .success(.defenderPosted))
    }

    @Test func zombiesNextToADefenderKnockItOutThenItReturnsAtFullHealth() throws {
        // Next to the HQ the brute stays put bashing it, right beside the defender.
        var loop = try withDefender(post: .hold(at: GridPoint(x: 21, y: 19)))
        (loop, _) = try S.addZombie(loop, x: 21.5, y: 19.5, id: "brute")
        loop.step(ticks: S.ticks(15, loop))
        #expect(loop.state.base.defenders.count == 1)  // never dies
        #expect(loop.state.base.defenders[0].isKnockedOut)
        #expect(loop.drainEvents().contains(.defenderKnockedOut(1)))
        // Orders are refused while it is out; the zombies leave; after knockedOutSeconds it is back at the HQ, healed.
        #expect(loop.send(.holdSpot(defender: 1, at: GridPoint(x: 3, y: 3))) == .failure(.defender(.knockedOut)))
        let calm = try loop.edited { $0.base.zombies.removeAll() }
        let out = S.ticks(calm.content.units.knockedOutSeconds, calm)
        // It went down about 8 s into the 15 s above, so roughly out - 70 ticks remain.
        calm.step(ticks: out - 120)
        #expect(calm.state.base.defenders[0].isKnockedOut)
        calm.step(ticks: 130)
        #expect(calm.state.base.defenders[0].post == .hq)
        #expect(calm.state.base.defenders[0].hp == unitHp)
    }

    @Test func garrisonedDefendersAreSafeInsideTheirTower() throws {
        var loop = try withDefender([("watchtower", S.towerSpot)])
        loop.send(.garrison(defender: 1, in: S.building(loop, "watchtower").id))
        (loop, _) = try S.addZombie(loop, x: 8.5, y: 20.5, id: "brute")
        loop.step(ticks: S.ticks(30, loop))
        #expect(loop.state.base.defenders[0].hp == unitHp)
    }
}
