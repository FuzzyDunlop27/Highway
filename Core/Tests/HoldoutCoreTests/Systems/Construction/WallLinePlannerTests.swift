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
        // Cost is paid as each job starts (D-033): slots allow only some at once, the rest wait in the queue.
        let started = loop.state.base.jobs.filter { $0.started }.count
        #expect(started == loop.buildQueue.slots && loop.buildQueue.queued == ids.count - started)
        let each = loop.content.buildingDef(wall)!.level(1)!.cost
        #expect(loop.state.base.stock.scrap == stock.scrap - each.scrap * started)
        loop.step(ticks: 60 * loop.content.economy.ticksPerSecond * 4)
        #expect(loop.state.base.jobs.isEmpty && ids.allSatisfy { loop.state.base.building($0)?.isComplete == true })
    }

    @Test func lineStopsWhenTheQueueIsFull() throws {
        let loop = try TestSupport.loop { $0.base.stock.scrap = 500 }
        let room = loop.buildQueue.slots + loop.buildQueue.queueLength
        let plan = loop.planLine(defId: wall, from: GridPoint(x: 0, y: 26), to: GridPoint(x: 39, y: 26))
        #expect(plan.buildable.count == room)
        #expect(plan.problem == .queueFull)
        #expect(plan.canBuild)
    }

    @Test func lineStopsAtTheLimit() throws {
        // Five extra walls leave 7 below the limit, fewer than the queue room (8), so the limit is what stops the line.
        let loop = try TestSupport.loop {
            $0.base.stock.scrap = 500
            for x in 0..<5 {
                $0.base.buildings.append(Building(id: 900 + x, defId: "wall_wood", level: 1, origin: GridPoint(x: x, y: 29),
                                                  hp: 1, constructionTicksLeft: 0, constructionTicksTotal: 0, invested: .zero))
            }
        }
        let def = loop.content.buildingDef(wall)!
        let left = WallLinePlanner.limit(def: def, state: loop.state) - loop.state.base.buildings.filter { $0.defId == wall }.count
        let plan = loop.planLine(defId: wall, from: GridPoint(x: 0, y: 26), to: GridPoint(x: 39, y: 26))
        #expect(plan.buildable.count == left)
        #expect(plan.problem == .limitReached(max: WallLinePlanner.limit(def: def, state: loop.state)))
        #expect(plan.canBuild)
    }
}
