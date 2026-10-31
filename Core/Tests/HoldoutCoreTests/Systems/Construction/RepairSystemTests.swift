// Purpose: Tests repairing damaged buildings and rebuilding rubble: cost, time, level kept, and errors. Notes: docs/features/construction.md
import Testing
@testable import HoldoutCore

struct RepairSystemTests {
    /// A game with a finished farm (paid for, so `invested` is its level-1 cost) and plenty of resources.
    private func withFarm(_ adjust: (inout Building) -> Void) throws -> (GameLoop, BuildingID) {
        let setup = try TestSupport.loop { $0.group.survivors = 8; $0.base.stock = Cost(scrap: 400, food: 200) }
        guard case .success(.placed(let id)) = setup.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot)) else {
            throw RepairTestError.notPlaced
        }
        setup.step(ticks: TestSupport.ticks(setup.content.buildingDef("farm")!.level(1)!.buildSeconds, setup))
        let loop = try setup.edited { s in
            let i = s.base.buildings.firstIndex { $0.id == id }!
            adjust(&s.base.buildings[i])
        }
        return (loop, id)
    }

    private enum RepairTestError: Error { case notPlaced }

    @Test func damagedBuildingCostsAShareOfItsLevelCostAndTime() throws {
        let (loop, id) = try withFarm { $0.hp = 150 }
        let level = loop.content.buildingDef("farm")!.level(1)!
        let rule = loop.content.buildings.rules.repair
        let missing = Double(level.hp - 150) / Double(level.hp)
        let expected = Cost(scrap: Int((Double(level.cost.scrap * rule.costPctOfLevelCost) / 100 * missing).rounded(.up)),
                            food: Int((Double(level.cost.food * rule.costPctOfLevelCost) / 100 * missing).rounded(.up)))
        let ticks = loop.content.ticks(forSeconds: max(rule.minSeconds,
                                                       level.buildSeconds * Double(rule.timePctOfBuildTime) / 100 * missing))
        let before = loop.state.base.stock
        let invested = loop.state.base.building(id)!.invested
        #expect(loop.send(.repair(id: id)) == .success(.repairStarted(cost: expected)))
        let b = try #require(loop.state.base.building(id))
        #expect(loop.state.base.stock == Cost(scrap: before.scrap - expected.scrap, food: before.food - expected.food))
        #expect(b.hp == level.hp && b.level == 1)
        #expect(b.constructionTicksLeft == ticks && b.constructionTicksTotal == ticks)
        #expect(b.invested == invested + expected)
        loop.step(ticks: ticks)
        #expect(loop.state.base.building(id)?.isComplete == true)
    }

    @Test func tinyDamageUsesTheMinimumTime() throws {
        let (loop, id) = try withFarm { $0.hp -= 1 }
        loop.send(.repair(id: id))
        let min = loop.content.ticks(forSeconds: loop.content.buildings.rules.repair.minSeconds)
        #expect(loop.state.base.building(id)?.constructionTicksLeft == min)
    }

    @Test func rubbleRebuildsFromWhatWasInvested() throws {
        let (loop, id) = try withFarm { $0.hp = 0; $0.isRubble = true; $0.staffed = 0 }
        let level = loop.content.buildingDef("farm")!.level(1)!
        let rule = loop.content.buildings.rules.rubble
        let invested = loop.state.base.building(id)!.invested
        let cost = invested.percent(rule.rebuildCostPctOfInvested)
        #expect(loop.send(.repair(id: id)) == .success(.repairStarted(cost: cost)))
        let b = try #require(loop.state.base.building(id))
        let ticks = loop.content.ticks(forSeconds: level.buildSeconds * Double(rule.rebuildTimePctOfInvested) / 100)
        #expect(!b.isRubble && b.hp == level.hp && b.level == 1)
        #expect(b.constructionTicksLeft == ticks)
        #expect(b.invested == invested + cost)
        loop.step(ticks: ticks + 1)
        #expect(loop.state.base.building(id)?.isComplete == true)
        #expect(loop.state.base.building(id)?.staffed == 2)
    }

    @Test func freeStartingRubbleUsesTheLevelCost() throws {
        let start = try TestSupport.loop()
        let wall = try #require(start.state.base.buildings.first { $0.defId == "wall_wood" })
        let loop = try start.edited { s in
            let i = s.base.buildings.firstIndex { $0.id == wall.id }!
            s.base.buildings[i].hp = 0
            s.base.buildings[i].isRubble = true
        }
        let levelCost = loop.content.buildingDef("wall_wood")!.level(1)!.cost
        let cost = levelCost.percent(loop.content.buildings.rules.rubble.rebuildCostPctOfInvested)
        #expect(loop.send(.repair(id: wall.id)) == .success(.repairStarted(cost: cost)))
    }

    @Test func notEnoughResourcesChangesNothing() throws {
        let (setup, id) = try withFarm { $0.hp = 10 }
        let loop = try setup.edited { $0.base.stock = .zero }
        let before = loop.state
        guard case .failure(.notEnoughResources(let needed)) = loop.send(.repair(id: id)) else {
            Issue.record("expected notEnoughResources"); return
        }
        #expect(needed.scrap > 0)
        #expect(loop.state == before)
    }

    @Test func fullHealthUnfinishedAndUnknownBuildingsCantBeRepaired() throws {
        let (loop, id) = try withFarm { _ in }
        #expect(loop.send(.repair(id: id)) == .failure(.nothingToRepair(id)))
        #expect(loop.send(.repair(id: 9_999)) == .failure(.unknownBuildingID(9_999)))
        guard case .success(.placed(let fresh)) = loop.send(.placeBuilding(defId: "farm", at: TestSupport.secondGrassSpot)) else {
            Issue.record("farm not placed"); return
        }
        #expect(loop.send(.repair(id: fresh)) == .failure(.nothingToRepair(fresh)))
    }
}
