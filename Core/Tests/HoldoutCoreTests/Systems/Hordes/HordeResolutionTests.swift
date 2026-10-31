// Purpose: Tests zombie deaths (loot, caps, kills), the held-horde bonus and next day, the HQ fall, and rubble. Notes: docs/features/hordes.md
import Testing
@testable import HoldoutCore

struct HordeResolutionTests {
    /// A game with a horde attacking and every zombie spawned (housing full so survivors don't eat food).
    private func midHorde(_ adjust: (inout GameState) -> Void = { _ in }) throws -> GameLoop {
        let loop = try TestSupport.loop { $0.group.survivors = 8; adjust(&$0) }
        loop.send(.debugStartHorde)
        loop.step(ticks: TestSupport.ticks(loop.content.hordes.spawnIntervalSeconds, loop) * 20)
        _ = loop.drainEvents()
        return loop
    }

    private func zombieDef(_ id: String, _ loop: GameLoop) -> ZombieDef { loop.content.zombies.zombies.first { $0.id == id }! }

    @Test func deadZombiesDropLootAndCountAsKilled() throws {
        let start = try midHorde()
        let victim = try #require(start.state.base.zombies.first)
        let before = start.state.base.stock
        let loop = try start.edited { $0.base.zombies[0].hp = 0 }
        loop.step()
        let loot = zombieDef(victim.defId, loop).loot
        #expect(loop.state.base.stock == before + loot)
        #expect(loop.state.base.horde.active?.killed == 1)
        #expect(!loop.state.base.zombies.contains { $0.id == victim.id })
        #expect(loop.drainEvents().contains(.zombieDied(victim.id, defId: victim.defId, x: victim.x, y: victim.y)))
    }

    @Test func lootIsClampedToTheStorageCap() throws {
        let start = try midHorde()
        let cap = start.resources.scrapCap
        let loop = try start.edited { s in
            s.base.stock.scrap = cap - 1
            for i in s.base.zombies.indices { s.base.zombies[i].hp = -5 }
        }
        loop.step()
        #expect(loop.state.base.stock.scrap == cap)
    }

    @Test func heldHordePaysTheBonusAdvancesTheDayAndReschedules() throws {
        let start = try midHorde { $0.base.stock = .zero }
        let loop = try start.edited { s in for i in s.base.zombies.indices { s.base.zombies[i].hp = 0 } }
        let killedLoot = loop.state.base.zombies.reduce(Cost.zero) { $0 + zombieDef($1.defId, loop).loot }
        loop.step()
        let rule = loop.content.hordes.completionBonus
        let bonus = Cost(scrap: rule.scrapBase + rule.scrapPerDay, food: rule.foodBase + rule.foodPerDay)
        #expect(loop.drainEvents().contains(.hordeEnded(.held(bonus: bonus))))
        #expect(loop.state.base.stock == killedLoot + bonus)
        #expect(loop.state.base.horde.active == nil)
        #expect(loop.state.base.horde.day == 2)

        let interval = TestSupport.ticks(loop.content.hordes.schedule.intervalSeconds, loop)
        loop.step(ticks: interval - 1)
        #expect(loop.state.base.horde.active == nil)
        loop.step()
        #expect(loop.drainEvents().contains { if case .hordeStarted(day: 2, edges: _, isBonus: _) = $0 { true } else { false } })
    }

    @Test func hqFallLosesAShareRestoresTheHqAndEndsTheHorde() throws {
        let start = try midHorde()
        let fall = start.content.economy.hqFall
        let loop = try start.edited { s in
            s.base.stock = Cost(scrap: 203, food: 101)
            let hq = s.base.buildings.firstIndex { $0.defId == "hq" }!
            s.base.buildings[hq].hp = -40
        }
        loop.step()
        let lost = Cost(scrap: 203 * fall.resourceLossPct / 100, food: 101 * fall.resourceLossPct / 100)
        #expect(loop.drainEvents().contains(.hordeEnded(.hqFell(lost: lost))))
        #expect(loop.state.base.stock == Cost(scrap: 203 - lost.scrap, food: 101 - lost.food))
        let hq = try #require(loop.state.base.buildings.first { $0.defId == "hq" })
        #expect(hq.hp == loop.content.buildingDef("hq")!.level(1)!.hp * fall.hqRestoreHpPct / 100)
        #expect(!hq.isRubble && hq.isComplete)
        #expect(loop.state.base.zombies.isEmpty)
        #expect(loop.state.base.horde.active == nil)
        #expect(loop.state.base.horde.day == 2)
    }

    @Test func zeroHpBuildingsBecomeRubbleThatStopsWorking() throws {
        let loop = try TestSupport.loop { $0.group.survivors = 8; $0.base.stock = Cost(scrap: 400, food: 0) }
        guard case .success(.placed(let farmID)) = loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot)) else {
            Issue.record("farm not placed"); return
        }
        loop.step(ticks: TestSupport.ticks(loop.content.buildingDef("farm")!.level(1)!.buildSeconds, loop))
        let wallID = try #require(loop.state.base.buildings.first { $0.defId == "wall_wood" }).id
        let broken = try loop.edited { s in
            for i in s.base.buildings.indices where [farmID, wallID].contains(s.base.buildings[i].id) { s.base.buildings[i].hp = 0 }
        }
        broken.step()
        let events = broken.drainEvents()
        for id in [farmID, wallID] {
            let b = try #require(broken.state.base.building(id))
            #expect(b.isRubble && !b.isComplete && b.staffed == 0)
            #expect(events.contains(.buildingDestroyed(id)))
        }
        let food = broken.state.base.stock.food
        broken.step(ticks: TestSupport.ticks(120, broken))
        #expect(broken.state.base.stock.food == food)
        #expect(broken.state.base.building(farmID)?.staffed == 0)
    }
}
