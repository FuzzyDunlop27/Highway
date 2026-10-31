// Purpose: Tests "is this spot valid?": map edges, highway, decorations, overlap, limits, prerequisites, cost. Notes: docs/features/construction.md
import Testing
@testable import HoldoutCore

struct PlacementRulesTests {
    @Test func openGrassIsValid() throws {
        let check = try TestSupport.loop().checkPlacement(defId: "farm", at: TestSupport.grassSpot)
        #expect(check.isValid)
        #expect(check.badTiles.isEmpty)
    }

    @Test func offTheMapIsInvalidAndReportsTiles() throws {
        let check = try TestSupport.loop().checkPlacement(defId: "farm", at: GridPoint(x: 39, y: 29))
        #expect(check.problem == .offMap)
        #expect(check.badTiles.count == 3)
    }

    @Test func highwayIsNotBuildable() throws {
        let check = try TestSupport.loop().checkPlacement(defId: "wall_wood", at: GridPoint(x: 15, y: 2))
        #expect(check.problem == .blockedTerrain)
    }

    @Test func rampsAndSideRoadsAreBuildable() throws {
        let loop = try TestSupport.loop()
        #expect(loop.checkPlacement(defId: "wall_wood", at: GridPoint(x: 5, y: 8)).isValid)
        #expect(loop.checkPlacement(defId: "wall_wood", at: GridPoint(x: 19, y: 26)).isValid)
    }

    @Test func decorationBlocksBuilding() throws {
        // A dead tree stands at (9, 25).
        let check = try TestSupport.loop().checkPlacement(defId: "farm", at: GridPoint(x: 8, y: 24))
        #expect(check.problem == .blockedTerrain)
        #expect(check.badTiles == [GridPoint(x: 9, y: 25)])
    }

    @Test func overlappingAnotherBuildingIsInvalid() throws {
        // The HQ covers (22...24, 18...20).
        let check = try TestSupport.loop().checkPlacement(defId: "farm", at: GridPoint(x: 21, y: 17))
        #expect(check.problem == .occupied)
        #expect(check.badTiles == [GridPoint(x: 22, y: 18)])
    }

    @Test func limitPerHqLevelIsEnforced() throws {
        let loop = try TestSupport.loop()
        let max = loop.content.buildingDef("farm")!.maxCountByHq[0]
        for i in 0..<max {
            #expect(loop.send(.placeBuilding(defId: "farm", at: GridPoint(x: 8 + 3 * i, y: 20))).isSuccess)
        }
        #expect(loop.checkPlacement(defId: "farm", at: GridPoint(x: 8, y: 7)).problem == .limitReached(max: max))
    }

    @Test func secondHqIsNotAllowed() throws {
        let check = try TestSupport.loop { $0.base.stock = Cost(scrap: 500, food: 500) }
            .checkPlacement(defId: "hq", at: GridPoint(x: 8, y: 20))
        #expect(check.problem == .limitReached(max: 1))
    }

    @Test func notEnoughResourcesIsInvalid() throws {
        let loop = try TestSupport.loop { $0.base.stock = .zero }
        let cost = loop.content.buildingDef("farm")!.level(1)!.cost
        #expect(loop.checkPlacement(defId: "farm", at: TestSupport.grassSpot).problem == .notEnoughResources(needed: cost))
    }

    @Test func spikesNeedAFinishedWorkshop() throws {
        let check = try TestSupport.loop().checkPlacement(defId: "spikes", at: TestSupport.grassSpot)
        #expect(check.problem == .needsBuilding("workshop", level: 1))
    }

    @Test func metalWallNeedsResearch() throws {
        let check = try TestSupport.loop().checkPlacement(defId: "wall_metal", at: TestSupport.grassSpot)
        #expect(check.problem == .needsResearch("metal_fortification"))
    }

    @Test func mgNestNeedsHqLevel2() throws {
        let check = try TestSupport.loop().checkPlacement(defId: "mg_nest", at: TestSupport.grassSpot)
        #expect(check.problem == .needsHqLevel(2))
    }

    @Test func unknownBuildingIsReported() throws {
        let check = try TestSupport.loop().checkPlacement(defId: "castle", at: TestSupport.grassSpot)
        #expect(check.problem == .unknownBuilding("castle"))
    }
}

extension Result {
    var isSuccess: Bool { if case .success = self { true } else { false } }
}
