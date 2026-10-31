// Purpose: Tests zombie walking speed, barbed wire, spikes, wall bashing, HQ attacks, and determinism. Notes: docs/features/pathing.md
import Testing
@testable import HoldoutCore

struct ZombieMovementTests {
    typealias S = CombatTestSupport

    @Test func walkerWalksAtItsSpeedTowardTheHQ() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        S.addZombie("walker", x: 10.5, y: 19.5, state: &state, content: content)
        S.runMovement(&state, ticks: content.ticks(forSeconds: 1), content: content)
        let zombie = state.base.zombies[0]
        #expect(abs(zombie.x - (10.5 + S.zombieDef("walker", content).speed)) < 1e-9)
        #expect(zombie.y == 19.5)
        #expect(zombie.heading == 0)                                         // facing east, toward the HQ
        #expect(zombie.attacking == nil)
    }

    @Test func barbedWireSlowsBySlowPct() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        S.addBuilding("barbwire", at: GridPoint(x: 10, y: 19), state: &state, content: content)
        S.addZombie("walker", x: 10.5, y: 19.5, state: &state, content: content)
        S.runMovement(&state, ticks: 1, content: content)
        let slowPct = content.buildingDef("barbwire")!.level(1)!.effects.slowPct!
        let perTick = S.zombieDef("walker", content).speed / Double(content.economy.ticksPerSecond)
        #expect(abs(state.base.zombies[0].x - (10.5 + perTick * (1 - slowPct / 100))) < 1e-9)
    }

    @Test func spikesHurtZombiesAndWearDown() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        let spikes = S.addBuilding("spikes", at: GridPoint(x: 10, y: 19), state: &state, content: content)
        let zombie = S.addZombie("walker", x: 10.0, y: 19.5, state: &state, content: content)  // stays on it for 1 s
        let events = S.runMovement(&state, ticks: content.ticks(forSeconds: 1), content: content)
        let def = content.buildingDef("spikes")!
        let walkerHp = Double(S.zombieDef("walker", content).hp)
        #expect(abs(state.base.zombies[0].hp - (walkerHp - def.level(1)!.effects.dps!)) < 1e-9)
        #expect(state.base.building(spikes)!.hp == def.level(1)!.hp - Int(def.durabilityLossPerZombieSecond!))
        #expect(events.filter { $0 == .trapHit(spikes, zombie) }.count == 1)  // throttled: once per second
    }

    @Test func brokenOrUnfinishedSpikesDoNothing() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        S.addBuilding("spikes", at: GridPoint(x: 10, y: 19), rubble: true, state: &state, content: content)
        let building = S.addBuilding("spikes", at: GridPoint(x: 10, y: 21), state: &state, content: content)
        state.base.buildings[state.base.buildings.count - 1].constructionTicksLeft = 50
        S.addZombie("walker", x: 10.0, y: 19.5, state: &state, content: content)
        S.addZombie("walker", x: 10.0, y: 21.5, state: &state, content: content)
        S.runMovement(&state, ticks: 5, content: content)
        #expect(state.base.zombies.allSatisfy { $0.hp == Double(S.zombieDef("walker", content).hp) })
        #expect(state.base.building(building)!.hp == content.buildingDef("spikes")!.level(1)!.hp)
    }

    @Test func blockedZombieBashesTheWall() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        let walls = S.ringHQ(with: "wall_wood", state: &state, content: content)
        let wall = walls[GridPoint(x: 21, y: 19)]!
        S.addZombie("walker", x: 20.5, y: 19.5, state: &state, content: content)
        let events = S.runMovement(&state, ticks: content.ticks(forSeconds: 1), content: content)
        let walker = S.zombieDef("walker", content)
        let full = content.buildingDef("wall_wood")!.level(1)!.hp
        #expect(state.base.building(wall)!.hp == full - Int(walker.damageVsBuildingsPerSec * walker.wallBashMultiplier))
        #expect(state.base.zombies[0].attacking == wall)
        #expect(state.base.zombies[0].x == 20.5)                             // stopped in front of it
        #expect(events.filter { $0 == .buildingDamaged(wall) }.count == 1)   // throttled: once per second
    }

    @Test func bruteBashesWallsWithItsMultiplier() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        let wall = S.ringHQ(with: "wall_wood", state: &state, content: content)[GridPoint(x: 21, y: 19)]!
        S.addZombie("brute", x: 20.5, y: 19.5, state: &state, content: content)
        S.runMovement(&state, ticks: content.ticks(forSeconds: 2), content: content)
        let brute = S.zombieDef("brute", content)
        let full = content.buildingDef("wall_wood")!.level(1)!.hp
        #expect(state.base.building(wall)!.hp == full - Int(2 * brute.damageVsBuildingsPerSec * brute.wallBashMultiplier))
    }

    @Test func zombieNextToTheHQAttacksItWithoutTheWallMultiplier() throws {
        let content = try TestSupport.content()
        var state = try S.hqOnlyState(content: content)
        let hq = state.base.buildings[0]
        S.addZombie("brute", x: 21.5, y: 19.5, state: &state, content: content)
        S.runMovement(&state, ticks: content.ticks(forSeconds: 1), content: content)
        #expect(state.base.building(hq.id)!.hp == hq.hp - Int(S.zombieDef("brute", content).damageVsBuildingsPerSec))
        #expect(state.base.zombies[0].attacking == hq.id)
    }

    @Test func zombieFromTheHighwayReachesTheTown() throws {
        let content = try TestSupport.content()
        var state = try GameState.newGame(content: content, mapId: "phase1_exit", seed: 1)   // starting walls + tower
        S.addZombie("walker", x: 0.5, y: 2.5, state: &state, content: content)
        S.runMovement(&state, ticks: content.ticks(forSeconds: 120), content: content)
        #expect(state.base.zombies[0].attacking != nil)
    }

    @Test func sameSeedAndStepsGiveTheSameState() throws {
        func run(cacheResetAt reset: Int?) throws -> GameState {
            let content = try TestSupport.content()
            var state = try GameState.newGame(content: content, mapId: "phase1_exit", seed: 7)
            for (i, type) in ["walker", "runner", "brute", "walker", "runner"].enumerated() {
                S.addZombie(type, x: 0.5, y: 1.5 + Double(i % 4), state: &state, content: content)
            }
            S.addZombie("walker", x: 39.5, y: 2.5, state: &state, content: content)
            var cache = FlowFieldCache()
            for t in 0..<content.ticks(forSeconds: 90) {
                if t == reset { cache = FlowFieldCache() }                   // like loading a save mid-horde
                S.runMovement(&state, ticks: 1, content: content, fields: cache)
            }
            return state
        }
        let first = try run(cacheResetAt: nil)
        #expect(first == (try run(cacheResetAt: nil)))
        #expect(first == (try run(cacheResetAt: 450)))
        #expect(first.base.zombies.contains { $0.attacking != nil })         // the run actually reached the walls
    }
}
