// Purpose: Wall tool: line path shape, skipped tiles, total cost, limit, and building the whole line at once. Notes: docs/features/construction.md
import Testing
@testable import HoldoutCore

struct WallLinePlannerTests {
    private let wall = "wall_wood"
    /// Open grass far from the starting walls (see TestSupport.grassSpot).
    private let a = GridPoint(x: 4, y: 20)

    @Test func straightAndLShapedPaths() {
        #expect(WallLinePlanner.path(from: a, to: GridPoint(x: 8, y: 20)).count == 5)
        #expect(WallLinePlanner.path(from: GridPoint(x: 8, y: 20), to: a).first == GridPoint(x: 8, y: 20))
        let l = WallLinePlanner.path(from: a, to: GridPoint(x: 8, y: 22))  // longer along x: corner at (8,20)
        #expect(l.count == 7 && l.contains(GridPoint(x: 8, y: 20)) && Set(l).count == l.count)
        #expect(WallLinePlanner.path(from: a, to: a) == [a])
    }

    @Test func planCountsCostOfBuildableTilesOnly() throws {
        let loop = try TestSupport.loop()
        let unit = loop.content.buildingDef(wall)!.level(1)!.cost
        let plan = loop.planLine(defId: wall, from: a, to: GridPoint(x: 9, y: 20))
        #expect(plan.buildable.count == 6 && plan.blocked.isEmpty && plan.canBuild)
        #expect(plan.cost == Cost(scrap: unit.scrap * 6, food: unit.food * 6))
    }

    @Test func blockedAndExistingTilesAreSkipped() throws {
        let loop = try TestSupport.loop()
        loop.send(.placeBuilding(defId: wall, at: GridPoint(x: 6, y: 20)))
        loop.send(.placeBuilding(defId: "farm", at: GridPoint(x: 8, y: 19)))  // covers (8,20)
        let plan = loop.planLine(defId: wall, from: a, to: GridPoint(x: 10, y: 20))
        #expect(plan.alreadyBuilt == [GridPoint(x: 6, y: 20)])
        #expect(Set(plan.blocked) == [GridPoint(x: 8, y: 20), GridPoint(x: 9, y: 20)])
        #expect(plan.buildable.count == 4)
    }

    @Test func notEnoughForTheWholeLineBuildsNothing() throws {
        let loop = try TestSupport.loop { $0.base.stock.scrap = 25 }  // 2 wood walls' worth
        let before = loop.state
        let plan = loop.planLine(defId: wall, from: a, to: GridPoint(x: 9, y: 20))
        #expect(!plan.canBuild)
        if case .notEnoughResources = plan.problem {} else { Issue.record("expected notEnoughResources") }
        #expect(loop.send(.placeLine(defId: wall, from: a, to: GridPoint(x: 9, y: 20))) != .success(.placedLine([])))
        #expect(loop.state == before)
    }

    @Test func buildingTheLinePlacesEveryPieceAndChargesTheTotal() throws {
        let loop = try TestSupport.loop()
        let plan = loop.planLine(defId: wall, from: a, to: GridPoint(x: 6, y: 23))
        let stock = loop.state.base.stock
        guard case .success(.placedLine(let ids)) = loop.send(.placeLine(defId: wall, from: a, to: GridPoint(x: 6, y: 23))) else {
            Issue.record("line not placed"); return
        }
        #expect(ids.count == plan.buildable.count)
        #expect(Set(ids.compactMap { loop.state.base.building($0)?.origin }) == Set(plan.buildable))
        #expect(loop.state.base.stock == Cost(scrap: stock.scrap - plan.cost.scrap, food: stock.food - plan.cost.food))
    }

    @Test func lineStopsAtTheLimit() throws {
        let loop = try TestSupport.loop { $0.base.stock.scrap = 500 }
        let def = loop.content.buildingDef(wall)!
        let left = WallLinePlanner.limit(def: def, state: loop.state) - loop.state.base.buildings.filter { $0.defId == wall }.count
        let plan = loop.planLine(defId: wall, from: GridPoint(x: 0, y: 26), to: GridPoint(x: 39, y: 26))
        #expect(plan.buildable.count == left)
        #expect(plan.problem == .limitReached(max: WallLinePlanner.limit(def: def, state: loop.state)))
        #expect(plan.canBuild)
    }
}
