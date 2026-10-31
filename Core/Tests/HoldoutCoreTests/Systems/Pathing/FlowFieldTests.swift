// Purpose: Tests the zombie flow field: tile costs, walls by hp, rubble/traps open, decorations blocked, caching. Notes: docs/features/pathing.md
import Testing
@testable import HoldoutCore

struct FlowFieldTests {
    typealias S = CombatTestSupport

    @Test func openGroundCostCountsStepsToHQ() throws {
        let content = try TestSupport.content()
        let state = try S.hqOnlyState(content: content)
        let field = FlowField(state: state, content: content, weight: 1)
        let open = content.hordes.pathing.openTileCost
        #expect(field.distance(at: GridPoint(x: 23, y: 19)) == 0)          // HQ tile = goal
        #expect(field.distance(at: GridPoint(x: 21, y: 19)) == open)
        #expect(field.distance(at: GridPoint(x: 18, y: 19)) == 4 * open)
        #expect(abs(field.distance(at: GridPoint(x: 21, y: 17)) - 2.0.squareRoot() * open) < 1e-9)  // one diagonal step
        #expect(field.nextStep(from: GridPoint(x: 23, y: 19)) == nil)
        #expect(field.nextStep(from: GridPoint(x: 18, y: 19)) == GridPoint(x: 19, y: 19))
        #expect(field.distance(at: GridPoint(x: -1, y: 0)) == .infinity)
    }

    @Test func highwayIsWalkableAndDecorationsAreNot() throws {
        let content = try TestSupport.content()
        let state = try S.hqOnlyState(content: content)
        let field = FlowField(state: state, content: content, weight: 1)
        #expect(field.distance(at: GridPoint(x: 0, y: 2)).isFinite)        // highway lane, spawn edge
        let tree = GridPoint(x: 14, y: 8)
        #expect(field.distance(at: tree) == .infinity)
        #expect(field.entryCost(at: tree) == .infinity)
        // No step onto it, and no diagonal cutting past its corner.
        for dy in -1...1 { for dx in -1...1 { #expect(field.nextStep(from: GridPoint(x: 14 + dx, y: 8 + dy)) != tree) } }
        #expect(field.canStep(from: GridPoint(x: 13, y: 8), dx: 1, dy: 1) == false)
        #expect(field.canStep(from: GridPoint(x: 13, y: 9), dx: 1, dy: 0) == true)
    }

    @Test func wallAndBuildingCostScalesWithHpAndWeight() throws {
        let content = try TestSupport.content()
        let p = content.hordes.pathing
        var state = try S.hqOnlyState(content: content)
        let walls = S.ringHQ(with: "wall_wood", state: &state, content: content)
        S.addBuilding("farm", at: GridPoint(x: 10, y: 10), state: &state, content: content)
        let west = GridPoint(x: 21, y: 19)
        let full = content.buildingDef("wall_wood")!.level(1)!.hp
        let farmHp = content.buildingDef("farm")!.level(1)!.hp

        let normal = FlowField(state: state, content: content, weight: 1)
        #expect(normal.entryCost(at: west) == p.openTileCost + Double(full) * p.wallTileCostPerHp)
        #expect(normal.entryCost(at: GridPoint(x: 11, y: 11)) == p.openTileCost + Double(farmHp) * p.buildingTileCostPerHp)
        #expect(normal.distance(at: GridPoint(x: 20, y: 19)) == normal.entryCost(at: west) + p.openTileCost)

        let brute = FlowField(state: state, content: content, weight: 0.5)
        #expect(brute.entryCost(at: west) == p.openTileCost + Double(full) * p.wallTileCostPerHp * 0.5)

        state.base.buildings[state.base.buildings.firstIndex { $0.id == walls[west] }!].hp = full / 2
        let damaged = FlowField(state: state, content: content, weight: 1)
        #expect(damaged.entryCost(at: west) == p.openTileCost + Double(full / 2) * p.wallTileCostPerHp)
    }

    @Test func zombiesPathThroughTheWeakestWall() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        let walls = S.ringHQ(with: "wall_metal", state: &state, content: content)
        let weak = GridPoint(x: 25, y: 19)                                   // east side, far from the start
        state.base.buildings[state.base.buildings.firstIndex { $0.id == walls[weak] }!].hp = 40
        let field = FlowField(state: state, content: content, weight: 1)
        let path = S.path(from: GridPoint(x: 10, y: 19), field: field)
        #expect(path.contains(weak))
        #expect(path.filter { walls[$0] != nil } == [weak])                  // no other wall on the way
        #expect(field.distance(at: path.last!) == 0)                         // ends on the HQ
    }

    @Test func rubbleAndTrapsAreOpenGround() throws {
        let content = try TestSupport.content()
        let open = content.hordes.pathing.openTileCost
        var state = try S.hqOnlyState(content: content)
        S.addBuilding("wall_wood", at: GridPoint(x: 15, y: 19), rubble: true, state: &state, content: content)
        S.addBuilding("spikes", at: GridPoint(x: 16, y: 19), state: &state, content: content)
        S.addBuilding("barbwire", at: GridPoint(x: 17, y: 19), state: &state, content: content)
        let field = FlowField(state: state, content: content, weight: 1)
        for x in 15...18 {
            #expect(field.entryCost(at: GridPoint(x: x, y: 19)) == open)
            #expect(field.canStep(from: GridPoint(x: x - 1, y: 18), dx: 1, dy: 1))  // no corner to cut
        }
        #expect(field.distance(at: GridPoint(x: 14, y: 19)) == 8 * open)
    }

    @Test func cacheRebuildsOnlyWhenPathCostsChange() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        let walls = S.ringHQ(with: "wall_wood", state: &state, content: content)
        let index = state.base.buildings.firstIndex { $0.id == walls[GridPoint(x: 21, y: 19)] }!
        let cache = FlowFieldCache()
        _ = cache.field(weight: 1, state: state, content: content)
        _ = cache.field(weight: 1, state: state, content: content)
        _ = cache.field(weight: 0.5, state: state, content: content)
        #expect(cache.buildCount == 2)

        // A few hp off stays in the same whole cost step: no rebuild, and still identical to a fresh field
        // (so a loaded save, which starts with an empty cache, gets exactly the same paths).
        state.base.buildings[index].hp -= 5
        let cached = cache.field(weight: 1, state: state, content: content)
        #expect(cache.buildCount == 2)
        #expect(cached.cost == FlowField(state: state, content: content, weight: 1).cost)

        state.base.buildings[index].hp /= 2
        _ = cache.field(weight: 1, state: state, content: content)
        #expect(cache.buildCount == 3)
        state.base.buildings[index].isRubble = true
        _ = cache.field(weight: 1, state: state, content: content)
        #expect(cache.buildCount == 4)
    }
}
