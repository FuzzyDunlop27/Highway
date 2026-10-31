// Purpose: Tests the horde clock, warning, start, spawning, debug start, survivor pause, and save/load mid-horde. Notes: docs/features/hordes.md
import Foundation
import Testing
@testable import HoldoutCore

extension GameLoop {
    /// A new loop on a copy of this state after `change` (tests can't edit `state` directly; zombies don't
    /// move or die on their own in these tests, so tests kill them and damage buildings by hand).
    func edited(_ change: (inout GameState) -> Void) throws -> GameLoop {
        var copy = state
        change(&copy)
        return try GameLoop(content: content, state: copy)
    }
}

struct HordeSystemTests {
    private func schedule(_ loop: GameLoop) -> HordeScheduleDef { loop.content.hordes.schedule }

    @Test func firstHordeArrivesAtFirstHordeSeconds() throws {
        let loop = try TestSupport.loop()
        let first = TestSupport.ticks(schedule(loop).firstHordeSeconds, loop)
        loop.step(ticks: first - 1)
        #expect(loop.state.base.horde.active == nil)
        #expect(loop.hordeStatus.secondsUntilNext == 1 / Double(loop.content.economy.ticksPerSecond))
        loop.step()
        let active = try #require(loop.state.base.horde.active)
        #expect(loop.drainEvents().contains(.hordeStarted(day: 1, edges: active.edges, isBonus: false)))
        #expect(loop.hordeStatus.isActive)
    }

    @Test func warningFiresOnceWithEdgesBeforeTheHorde() throws {
        let loop = try TestSupport.loop()
        let s = schedule(loop)
        let warnAt = TestSupport.ticks(s.firstHordeSeconds - s.warningSeconds, loop)
        loop.step(ticks: warnAt - 1)
        #expect(loop.state.base.horde.warningEdges.isEmpty)
        #expect(loop.drainEvents().isEmpty)
        loop.step()
        let edges = loop.state.base.horde.warningEdges
        #expect(edges.count == loop.content.hordes.composition[0].edgeCount)
        #expect(loop.drainEvents() == [.hordeWarning(edges: edges, seconds: s.warningSeconds)])
        #expect(loop.hordeStatus.warningEdges == edges)

        loop.step(ticks: TestSupport.ticks(s.warningSeconds, loop))
        let events = loop.drainEvents()
        #expect(!events.contains { if case .hordeWarning = $0 { true } else { false } })
        #expect(loop.state.base.horde.active?.edges == edges)
        #expect(loop.state.base.horde.warningEdges.isEmpty)
    }

    @Test func clockIsFrozenDuringAHorde() throws {
        let loop = try TestSupport.loop()
        loop.send(.debugStartHorde)
        loop.step(ticks: TestSupport.ticks(schedule(loop).intervalSeconds * 2, loop))
        #expect(loop.state.base.horde.active != nil)  // zombies don't die by themselves here
        #expect(loop.state.base.horde.day == 1)
        #expect(loop.state.base.horde.ticksUntilNext == nil)
        #expect(loop.hordeStatus.secondsUntilNext == nil)
    }

    @Test func zombiesSpawnAtTheIntervalInsideTheEdges() throws {
        let loop = try TestSupport.loop()
        loop.send(.debugStartHorde)
        let active = try #require(loop.state.base.horde.active)
        let total = active.spawnQueue.count + active.spawned
        let perWave = active.edges.count
        #expect(loop.state.base.zombies.count == perWave)  // first wave enters at once
        let interval = TestSupport.ticks(loop.content.hordes.spawnIntervalSeconds, loop)
        loop.step(ticks: interval - 1)
        #expect(loop.state.base.zombies.count == perWave)
        loop.step()
        #expect(loop.state.base.zombies.count == min(2 * perWave, total))
        loop.step(ticks: interval * total)
        #expect(loop.state.base.zombies.count == total)
        #expect(loop.state.base.horde.active?.spawned == total)
        #expect(loop.state.base.horde.active?.spawnQueue.isEmpty == true)

        let rects = loop.map.spawnEdges.filter { active.edges.contains($0.id) }
        for z in loop.state.base.zombies {
            let def = try #require(loop.content.zombies.zombies.first { $0.id == z.defId })
            #expect(z.hp == Double(def.hp))
            #expect(z.x == Double(z.tile.x) + 0.5 && z.y == Double(z.tile.y) + 0.5)
            #expect(rects.contains { r in (r.x..<r.x + r.w).contains(z.tile.x) && (r.y..<r.y + r.h).contains(z.tile.y) })
        }
        #expect(Set(loop.state.base.zombies.map(\.id)).count == total)
    }

    @Test func debugStartUsesWarnedEdgesAndIgnoresRepeats() throws {
        let loop = try TestSupport.loop()
        let s = schedule(loop)
        loop.step(ticks: TestSupport.ticks(s.firstHordeSeconds - s.warningSeconds, loop))
        let warned = loop.state.base.horde.warningEdges
        #expect(loop.send(.debugStartHorde) == .success(.debugDone))
        #expect(loop.state.base.horde.active?.edges == warned)
        let before = loop.state
        loop.send(.debugStartHorde)
        #expect(loop.state == before)
    }

    @Test func noSurvivorsArriveDuringAHorde() throws {
        let loop = try TestSupport.loop { $0.group.survivors = 1; $0.base.stock.food = 400 }
        loop.send(.debugStartHorde)
        loop.step(ticks: TestSupport.ticks(loop.content.resources.survivorArrival.intervalSeconds * 3, loop))
        #expect(loop.state.group.survivors == 1)

        // Once the horde is over (it ends during the next tick, after the economy ran), arrivals resume.
        let after = try loop.edited { $0.base.zombies.removeAll(); $0.base.horde.active?.spawnQueue.removeAll() }
        after.step(ticks: TestSupport.ticks(loop.content.resources.survivorArrival.intervalSeconds, after) + 1)
        #expect(after.state.base.horde.active == nil)
        #expect(after.state.group.survivors == 2)
    }

    @Test func saveAndLoadMidHordeKeepsGoingIdentically() throws {
        let loop = try TestSupport.loop(seed: 7)
        loop.send(.debugStartHorde)
        loop.step(ticks: 7)
        let copy = try GameLoop(content: loop.content, state: SaveCodec.decode(SaveCodec.encode(loop.state)))
        #expect(copy.state == loop.state)
        loop.step(ticks: 40)
        copy.step(ticks: 40)
        #expect(copy.state == loop.state)

        let kill: (inout GameState) -> Void = { s in for i in s.base.zombies.indices { s.base.zombies[i].hp = 0 } }
        let a = try loop.edited(kill), b = try copy.edited(kill)
        a.step(ticks: 300)
        b.step(ticks: 300)
        #expect(a.state == b.state)
        #expect(a.state.base.horde.active == nil && a.state.base.horde.day == 2)
    }
}
