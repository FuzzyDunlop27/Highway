// Purpose: Tests the economy tick: production, staffing share, caps, housing, survivor arrival. Notes: docs/features/economy.md
import Testing
@testable import HoldoutCore

struct EconomySystemTests {
    /// A game with housing full (no survivor arrivals) so food changes only from production.
    private func fullHousingLoop(survivors: Int = 8, _ adjust: (inout GameState) -> Void = { _ in }) throws -> GameLoop {
        try TestSupport.loop { state in
            state.group.survivors = survivors
            adjust(&state)
        }
    }

    private func perMin(_ id: String, _ kind: ResourceKind, _ loop: GameLoop) -> Int {
        Int(loop.content.buildingDef(id)!.level(1)!.effects.productionPerMin![kind]!)
    }

    @Test func staffedFarmMakesItsFoodPerMinute() throws {
        let loop = try fullHousingLoop()
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        loop.step(ticks: TestSupport.ticks(loop.content.buildingDef("farm")!.level(1)!.buildSeconds, loop))
        let before = loop.state.base.stock.food
        loop.step(ticks: TestSupport.ticks(60, loop))
        #expect(loop.state.base.stock.food - before == perMin("farm", .food, loop))
    }

    @Test func scavengerPostMakesScrap() throws {
        let loop = try fullHousingLoop()
        loop.send(.placeBuilding(defId: "scavenger", at: TestSupport.grassSpot))
        loop.step(ticks: TestSupport.ticks(60, loop))
        let before = loop.state.base.stock.scrap
        loop.step(ticks: TestSupport.ticks(120, loop))
        #expect(loop.state.base.stock.scrap - before == 2 * perMin("scavenger", .scrap, loop))
    }

    @Test func halfStaffedFarmMakesHalf() throws {
        // 2 survivors: the watchtower (older) takes 1, the farm gets 1 of its 2 workers.
        let loop = try fullHousingLoop(survivors: 2) { $0.base.stock.food = 0 }
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        loop.step(ticks: TestSupport.ticks(60, loop))
        let farm = try #require(loop.state.base.buildings.last)
        #expect(farm.staffed == 1)
        // Read the rate, not stock: new survivors keep arriving (and eating food) in this game.
        #expect(loop.resources.foodPerMin == Double(perMin("farm", .food, loop)) / 2)
    }

    @Test func unfinishedFarmMakesNothing() throws {
        let loop = try fullHousingLoop()
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        let before = loop.state.base.stock.food
        loop.step(ticks: TestSupport.ticks(30, loop))
        #expect(loop.state.base.stock.food == before)
        #expect(loop.state.base.buildings.last?.staffed == 0)
    }

    @Test func productionStopsAtStorageCap() throws {
        let loop = try fullHousingLoop { $0.base.stock.food = 495 }
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        loop.step(ticks: TestSupport.ticks(60 + 600, loop))
        let cap = loop.resources.foodCap
        #expect(cap == loop.content.resources.def(.food)!.baseCap)
        #expect(loop.state.base.stock.food == cap)
    }

    @Test func storageRaisesCapsWhenFinished() throws {
        let loop = try TestSupport.loop()
        let baseCap = loop.resources.scrapCap
        loop.send(.placeBuilding(defId: "storage", at: TestSupport.grassSpot))
        #expect(loop.resources.scrapCap == baseCap)
        loop.step(ticks: TestSupport.ticks(loop.content.buildingDef("storage")!.level(1)!.buildSeconds, loop))
        let added = loop.content.buildingDef("storage")!.level(1)!.effects.storageAdded!
        #expect(loop.resources.scrapCap == baseCap + added)
        #expect(loop.resources.foodCap == baseCap + added)
    }

    @Test func shelterRaisesHousing() throws {
        let loop = try TestSupport.loop()
        let before = loop.resources.housing
        loop.send(.placeBuilding(defId: "shelter", at: TestSupport.grassSpot))
        loop.step(ticks: TestSupport.ticks(60, loop))
        #expect(loop.resources.housing == before + loop.content.buildingDef("shelter")!.level(1)!.effects.housing!)
    }

    @Test func survivorArrivesEveryIntervalAndCostsFood() throws {
        let loop = try TestSupport.loop()
        let rule = loop.content.resources.survivorArrival
        let survivors = loop.state.group.survivors
        let food = loop.state.base.stock.food
        loop.step(ticks: TestSupport.ticks(rule.intervalSeconds, loop) - 1)
        #expect(loop.state.group.survivors == survivors)
        loop.step()
        #expect(loop.state.group.survivors == survivors + 1)
        #expect(loop.state.base.stock.food == food - rule.foodCost)
    }

    @Test func noSurvivorArrivesWhenHousingIsFull() throws {
        let loop = try fullHousingLoop()
        loop.step(ticks: TestSupport.ticks(600, loop))
        #expect(loop.state.group.survivors == loop.resources.housing)
    }

    @Test func noSurvivorArrivesWithoutFood() throws {
        let loop = try TestSupport.loop { $0.base.stock.food = 0 }
        let survivors = loop.state.group.survivors
        loop.step(ticks: TestSupport.ticks(300, loop))
        #expect(loop.state.group.survivors == survivors)
    }
}
