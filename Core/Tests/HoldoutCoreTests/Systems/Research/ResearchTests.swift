// Purpose: Tests Workshop research: gates, time, one at a time, effects (metal wall, tower range, farms), Knowledge saved. Notes: docs/features/scavenging-research.md
import Foundation
import Testing
@testable import HoldoutCore

struct ResearchTests {
    private typealias S = JobsTestSupport

    private func item(_ loop: GameLoop, _ id: String) -> ResearchItemDef { loop.content.research.items.first { $0.id == id }! }

    private func shopLoop(hq: Int = 1, survivors: Int = 10, more: [(String, GridPoint)] = []) throws -> GameLoop {
        try S.loop([("workshop", S.workshopSpot)] + more, survivors: survivors, stock: Cost(scrap: 500, food: 500)) {
            $0.base.buildings[0].level = hq
        }
    }

    @Test func researchPaysItsCostAndTakesItsTime() throws {
        let loop = try shopLoop()
        let m = item(loop, "marksmanship")
        #expect(loop.send(.startResearch("marksmanship")) == .success(.researchStarted(cost: m.cost)))
        #expect(loop.state.base.stock == Cost(scrap: 500 - m.cost.scrap, food: 500 - m.cost.food))
        let ticks = S.ticks(m.researchSeconds, loop)  // Workshop L1 speed is 1.0
        loop.step(ticks: ticks - 1)
        #expect(loop.state.group.knowledge.isEmpty)
        loop.step()
        #expect(loop.state.group.knowledge == ["marksmanship"])
        #expect(loop.state.base.research == nil)
        #expect(loop.drainEvents().contains(.researchFinished("marksmanship")))
    }

    @Test func workshopLevelSpeedsResearchUp() throws {
        let loop = try shopLoop()
        let fast = try loop.edited { $0.base.buildings[1].level = 2 }
        fast.send(.startResearch("marksmanship"))
        let speed = fast.content.buildingDef("workshop")!.level(2)!.effects.researchSpeedMultiplier!
        #expect(fast.state.base.research?.ticksTotal == S.ticks(item(fast, "marksmanship").researchSeconds / speed, fast))
    }

    @Test func gates() throws {
        let none = try S.loop()
        #expect(none.send(.startResearch("marksmanship")) == .failure(.research(.needsWorkshop)))
        let loop = try shopLoop()
        #expect(loop.send(.startResearch("nope")) == .failure(.research(.unknownItem)))
        #expect(loop.send(.startResearch("metal_fortification")) == .failure(.research(.needsHqLevel(2))))
        let poor = try loop.edited { $0.base.stock = Cost(scrap: 10, food: 10) }
        #expect(poor.send(.startResearch("agriculture")) == .failure(.research(.notEnoughResources(needed: item(poor, "agriculture").cost))))
        #expect(loop.send(.startResearch("marksmanship")).isSuccess)
        #expect(loop.send(.startResearch("agriculture")) == .failure(.research(.alreadyResearching)))
        let known = try loop.edited { $0.group.knowledge = ["agriculture"]; $0.base.research = nil }
        #expect(known.send(.startResearch("agriculture")) == .failure(.research(.alreadyKnown)))
        let unfinished = try S.loop([("workshop", S.workshopSpot)]) { $0.base.buildings[1].constructionTicksLeft = 9 }
        #expect(unfinished.send(.startResearch("marksmanship")) == .failure(.research(.needsWorkshop)))
    }

    @Test func theWorkshopMustBeStaffedAndPausesWithoutWorkers() throws {
        let nobody = try shopLoop(survivors: 0)
        #expect(nobody.send(.startResearch("marksmanship")) == .failure(.research(.workshopNotStaffed)))
        let loop = try shopLoop()
        loop.send(.startResearch("marksmanship"))
        let shop = S.building(loop, "workshop").id
        loop.send(.setWorkers(id: shop, count: 0))
        loop.step(ticks: 100)
        #expect(loop.state.base.research?.ticksLeft == loop.state.base.research?.ticksTotal)
        loop.send(.setWorkers(id: shop, count: 2))
        loop.step(ticks: 100)
        #expect(loop.state.base.research!.ticksLeft < loop.state.base.research!.ticksTotal)
    }

    @Test func metalFortificationUnlocksMetalWalls() throws {
        let loop = try shopLoop(hq: 2)
        let spot = TestSupport.grassSpot
        #expect(loop.checkPlacement(defId: "wall_metal", at: spot).problem == .needsResearch("metal_fortification"))
        loop.send(.startResearch("metal_fortification"))
        loop.step(ticks: S.ticks(item(loop, "metal_fortification").researchSeconds, loop))
        #expect(loop.checkPlacement(defId: "wall_metal", at: spot).isValid)
    }

    @Test func marksmanshipAddsATileOfRangeToTowers() throws {
        let loop = try shopLoop(more: [("watchtower", S.towerSpot), ("farm", S.farmSpot)])
        let tower = S.building(loop, "watchtower").id
        let base = loop.content.buildingDef("watchtower")!.level(1)!.effects.range!
        #expect(loop.towerRange(id: tower) == base)
        let learned = try loop.edited { $0.group.knowledge = ["marksmanship"] }
        #expect(learned.towerRange(id: tower) == base + 1)
        #expect(learned.towerRange(id: S.building(learned, "farm").id) == nil)
        // A zombie just past the old range now gets shot.
        func shotCount(_ l: GameLoop) throws -> Int {
            let (z, _) = try S.addZombie(l, x: 8.5 + base + 0.5, y: 20.5)
            z.step()
            z.step(ticks: 9)
            return z.drainEvents().filter { if case .shot = $0 { true } else { false } }.count
        }
        #expect(try shotCount(loop) == 0)
        #expect(try shotCount(learned) >= 1)
    }

    @Test func agricultureRaisesFarmOutput() throws {
        func foodPerMinute(_ knowledge: [String]) throws -> Double {
            let loop = try S.loop([("farm", S.farmSpot)]) { $0.group.knowledge = knowledge }
            return loop.resources.foodPerMin
        }
        let plain = try foodPerMinute([])
        let boost = try S.loop().content.research.items.first { $0.id == "agriculture" }!.effect.value!
        #expect(try foodPerMinute(["agriculture"]) == plain * boost)
        // The stock really grows by that much.
        let loop = try S.loop([("farm", S.farmSpot)], stock: Cost(scrap: 0, food: 0)) { $0.group.knowledge = ["agriculture"] }
        loop.step(ticks: S.ticks(120, loop))
        #expect(loop.state.base.stock.food == Int((plain * boost * 2).rounded(.down)))
    }

    @Test func knowledgeSurvivesASaveRoundTrip() throws {
        let loop = try shopLoop()
        loop.send(.startResearch("agriculture"))
        loop.step(ticks: S.ticks(item(loop, "agriculture").researchSeconds, loop))
        let back = try SaveCodec.decode(SaveCodec.encode(loop.state))
        #expect(back.group.knowledge == ["agriculture"])
        #expect(back == loop.state)
        // And mid-research too.
        let mid = try shopLoop()
        mid.send(.startResearch("marksmanship"))
        mid.step(ticks: 200)
        #expect(try SaveCodec.decode(SaveCodec.encode(mid.state)) == mid.state)
    }

    @Test func demolishingTheWorkshopRefundsResearchInProgress() throws {
        let loop = try shopLoop()
        loop.send(.startResearch("marksmanship"))
        loop.send(.demolish(id: S.building(loop, "workshop").id))
        #expect(loop.state.base.research == nil)
        #expect(loop.state.base.stock == Cost(scrap: 500, food: 500))  // paid cost returned; the demolished Workshop itself refunds nothing here
    }
}
