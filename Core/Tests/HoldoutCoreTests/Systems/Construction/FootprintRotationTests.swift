// Purpose: 2×1 footprints and turning buildings (facing) when placing and moving. Notes: docs/features/construction.md
import Foundation
import Testing
@testable import HoldoutCore

struct FootprintRotationTests {
    private let spot = TestSupport.grassSpot  // (8, 20), open grass

    @Test func fiveBuildingsAreTwoByOneAndRotatable() throws {
        let content = try TestSupport.content()
        for id in ["shelter", "scavenger", "workshop", "barracks", "storage"] {
            let def = try #require(content.buildingDef(id))
            #expect(def.size(facing: .south) == (2, 1) && def.size(facing: .north) == (2, 1), "\(id)")
            #expect(def.size(facing: .east) == (1, 2) && def.size(facing: .west) == (1, 2), "\(id)")
        }
        for id in ["hq", "farm"] { #expect(content.buildingDef(id)?.isRotatable == false, "\(id)") }
    }

    @Test func southFacingShelterCoversOneRow() throws {
        let loop = try TestSupport.loop()
        let id = try placed(loop.send(.placeBuilding(defId: "shelter", at: spot)))
        let b = try #require(loop.state.base.building(id))
        #expect(b.facing == .south)
        #expect(b.footprintTiles(try #require(loop.content.buildingDef("shelter"))) == [spot, GridPoint(x: 9, y: 20)])
        #expect(loop.building(at: GridPoint(x: 8, y: 21)) == nil)
    }

    @Test func eastFacingStorageTurnsItsFootprint() throws {
        let loop = try TestSupport.loop()
        let id = try placed(loop.send(.placeBuilding(defId: "storage", at: spot, facing: .east)))
        #expect(loop.state.base.building(id)?.facing == .east)
        #expect(loop.building(at: GridPoint(x: 8, y: 21))?.id == id)
        #expect(loop.building(at: GridPoint(x: 9, y: 20)) == nil)
        // The turned footprint blocks the tile below and leaves the one beside it free.
        #expect(loop.checkPlacement(defId: "wall_wood", at: GridPoint(x: 8, y: 21)).problem == .occupied)
        #expect(loop.checkPlacement(defId: "wall_wood", at: GridPoint(x: 9, y: 20)).isValid)
    }

    @Test func turnedFootprintIsCheckedBeforePlacing() throws {
        let loop = try TestSupport.loop()
        loop.send(.placeBuilding(defId: "wall_wood", at: GridPoint(x: 8, y: 21)))
        #expect(loop.checkPlacement(defId: "shelter", at: spot).isValid)
        let turned = loop.checkPlacement(defId: "shelter", at: spot, facing: .west)
        #expect(turned.problem == .occupied && turned.badTiles == [GridPoint(x: 8, y: 21)])
    }

    @Test func buildingsThatCantTurnAlwaysFaceSouth() throws {
        let loop = try TestSupport.loop()
        let id = try placed(loop.send(.placeBuilding(defId: "farm", at: spot, facing: .east)))
        #expect(loop.state.base.building(id)?.facing == .south)
    }

    @Test func movingCanTurnABuildingOrKeepItsFacing() throws {
        let loop = try TestSupport.loop()
        let id = try placed(loop.send(.placeBuilding(defId: "shelter", at: spot)))
        let target = TestSupport.secondGrassSpot
        #expect(loop.checkMove(id: id, to: target, facing: .north)?.isValid == true)
        #expect(loop.send(.moveBuilding(id: id, to: target, facing: .east)) == .success(.moved))
        #expect(loop.state.base.building(id)?.facing == .east)
        #expect(loop.building(at: GridPoint(x: target.x, y: target.y + 1))?.id == id)
        #expect(loop.send(.moveBuilding(id: id, to: spot)) == .success(.moved))
        #expect(loop.state.base.building(id)?.facing == .east)  // nil facing keeps the turn
        // Turning in place may hit what is next to it: the move is refused and nothing changes.
        loop.send(.placeBuilding(defId: "wall_wood", at: GridPoint(x: 9, y: 20)))
        #expect(loop.send(.moveBuilding(id: id, to: spot, facing: .south)) == .failure(.placement(.occupied)))
        #expect(loop.state.base.building(id)?.facing == .east)
    }

    @Test func zombiesPathAroundTheTurnedFootprint() throws {
        let loop = try TestSupport.loop()
        let id = try placed(loop.send(.placeBuilding(defId: "storage", at: spot, facing: .east)))
        for _ in 0..<100 where loop.state.base.building(id)?.isComplete != true { loop.step(ticks: TestSupport.ticks(10, loop)) }
        #expect(loop.state.base.building(id)?.isComplete == true)
        let field = FlowField(state: loop.state, content: loop.content, weight: 1)
        let open = loop.content.hordes.pathing.openTileCost
        #expect(field.entryCost(at: GridPoint(x: 8, y: 21)) > open)  // part of the building now
        #expect(field.entryCost(at: GridPoint(x: 9, y: 20)) == open)
    }

    private func placed(_ result: Result<CommandOutcome, CommandError>) throws -> BuildingID {
        guard case .success(.placed(let id)) = result else { throw CommandError.unknownBuildingID(-1) }
        return id
    }
}
