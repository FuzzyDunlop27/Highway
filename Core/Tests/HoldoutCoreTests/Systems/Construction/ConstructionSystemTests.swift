// Purpose: Tests placing (cost, build time), moving, and demolishing (refund, HQ rule). Notes: docs/features/construction.md
import Testing
@testable import HoldoutCore

struct ConstructionSystemTests {
    @Test func placingPaysCostAndBuildsOverBuildSeconds() throws {
        let loop = try TestSupport.loop()
        let level = loop.content.buildingDef("farm")!.level(1)!
        let stock = loop.state.base.stock
        let result = loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        guard case .success(.placed(let id)) = result else { Issue.record("placement failed: \(result)"); return }
        #expect(loop.state.base.stock.scrap == stock.scrap - level.cost.scrap)
        #expect(loop.state.base.stock.food == stock.food - level.cost.food)
        #expect(loop.state.base.building(id)?.isComplete == false)
        loop.step(ticks: TestSupport.ticks(level.buildSeconds, loop) - 1)
        #expect(loop.state.base.building(id)?.isComplete == false)
        loop.step()
        #expect(loop.state.base.building(id)?.isComplete == true)
    }

    @Test func failedPlacementChangesNothing() throws {
        let loop = try TestSupport.loop()
        let before = loop.state
        #expect(loop.send(.placeBuilding(defId: "farm", at: GridPoint(x: 15, y: 2))) == .failure(.placement(.blockedTerrain)))
        #expect(loop.state == before)
    }

    @Test func moveToValidSpotAndRejectInvalidOne() throws {
        let loop = try TestSupport.loop()
        guard case .success(.placed(let id)) = loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot)) else {
            Issue.record("placement failed"); return
        }
        // Moving by one tile overlaps its own old spot; that's allowed.
        #expect(loop.send(.moveBuilding(id: id, to: GridPoint(x: 9, y: 20))) == .success(.moved))
        #expect(loop.state.base.building(id)?.origin == GridPoint(x: 9, y: 20))
        #expect(loop.send(.moveBuilding(id: id, to: GridPoint(x: 22, y: 18))) == .failure(.placement(.occupied)))
        #expect(loop.send(.moveBuilding(id: 999, to: TestSupport.grassSpot)) == .failure(.unknownBuildingID(999)))
    }

    @Test func demolishRefundsShareOfCost() throws {
        let loop = try TestSupport.loop()
        let cost = loop.content.buildingDef("farm")!.level(1)!.cost
        guard case .success(.placed(let id)) = loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot)) else {
            Issue.record("placement failed"); return
        }
        let stock = loop.state.base.stock
        let refund = cost.percent(loop.content.buildings.rules.demolishRefundPct)
        #expect(loop.send(.demolish(id: id)) == .success(.demolished(refund: refund)))
        #expect(loop.state.base.building(id) == nil)
        #expect(loop.state.base.stock == stock + refund)
        #expect(loop.checkPlacement(defId: "farm", at: TestSupport.grassSpot).isValid)
    }

    @Test func startingBuildingsRefundNothingAndHqCantBeDemolished() throws {
        let loop = try TestSupport.loop()
        let hq = try #require(loop.state.base.buildings.first { $0.defId == "hq" })
        #expect(loop.send(.demolish(id: hq.id)) == .failure(.cannotDemolish(defId: "hq")))
        let wall = try #require(loop.state.base.buildings.first { $0.defId == "wall_wood" })
        #expect(loop.send(.demolish(id: wall.id)) == .success(.demolished(refund: .zero)))
    }

    @Test func newGameHasStartingLayout() throws {
        let loop = try TestSupport.loop()
        for entry in loop.content.buildings.startingLayout {
            #expect(loop.state.base.buildings.filter { $0.defId == entry.id && $0.isComplete }.count == entry.count)
        }
        #expect(loop.state.base.hqLevel == 1)
        #expect(loop.building(at: GridPoint(x: 23, y: 19))?.defId == "hq")
    }
}
