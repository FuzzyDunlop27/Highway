// Purpose: Tests tower firing: staffing/finished rules, fire rate, range, damage, levels, determinism. Notes: docs/features/combat.md
import Testing
@testable import HoldoutCore

/// Small builders shared by the combat tests.
enum CombatFixtures {
    static func tower(id: BuildingID, def: BuildingDef, at origin: GridPoint, level: Int = 1, staffed: Int? = nil,
                      ticksLeft: Int = 0, rubble: Bool = false) -> Building {
        Building(id: id, defId: def.id, level: level, origin: origin, hp: def.level(level)?.hp ?? 1,
                 constructionTicksLeft: ticksLeft, constructionTicksTotal: ticksLeft, invested: .zero,
                 staffed: staffed ?? def.workers, isRubble: rubble)
    }
}

struct TowerFiringTests {
    /// Open grass; a 1×1 tower here has its middle at (8.5, 20.5).
    private let spot = TestSupport.grassSpot
    private let tough = 1e9

    /// The Phase 1 map with the starting watchtower removed, then `towers` and `zombies` added.
    private func setup(_ towers: (GameContent) throws -> [Building], zombies: [Zombie]) throws -> (GameState, GameContent) {
        let content = try TestSupport.content()
        let added = try towers(content)
        let loop = try TestSupport.loop { state in
            state.base.buildings.removeAll { content.buildingDef($0.defId)?.levels.first?.effects.fireRate != nil }
            state.base.buildings += added
            state.base.zombies = zombies
        }
        return (loop.state, content)
    }

    private func def(_ id: String, _ content: GameContent) throws -> BuildingDef { try #require(content.buildingDef(id)) }
    private func effects(_ id: String, level: Int = 1, _ content: GameContent) throws -> EffectsDef {
        try #require(def(id, content).level(level)?.effects)
    }

    /// Calls TowerFiring for `ticks` ticks (no other system runs) and returns its events.
    @discardableResult
    private func run(_ state: inout GameState, _ content: GameContent, ticks: Int) -> [SimEvent] {
        let fields = FlowFieldCache()
        var events: [SimEvent] = []
        for _ in 0..<ticks {
            TowerFiring.tick(&state, content: content, fields: fields, events: &events)
            state.tick += 1
        }
        return events
    }

    private func zombie(_ id: Int, dx: Double = 0, dy: Double = 2, hp: Double) -> Zombie {
        Zombie(id: id, defId: "walker", x: Double(spot.x) + 0.5 + dx, y: Double(spot.y) + 0.5 + dy, hp: hp)
    }

    @Test(arguments: ["unstaffed", "unfinished", "rubble"])
    func brokenTowersDoNotFire(problem: String) throws {
        var (state, content) = try setup({ c in
            [CombatFixtures.tower(id: 100, def: try def("watchtower", c), at: spot,
                                  staffed: problem == "unstaffed" ? 0 : nil,
                                  ticksLeft: problem == "unfinished" ? 50 : 0,
                                  rubble: problem == "rubble")]
        }, zombies: [zombie(1, hp: 100)])
        let events = run(&state, content, ticks: content.economy.ticksPerSecond * 5)
        #expect(events.isEmpty)
        #expect(state.base.zombies[0].hp == 100)
    }

    @Test(arguments: ["watchtower", "mg_nest"])
    func firesAtItsFireRate(defId: String) throws {
        var (state, content) = try setup({ c in [CombatFixtures.tower(id: 100, def: try def(defId, c), at: spot)] },
                                         zombies: [zombie(1, hp: tough)])
        let fx = try effects(defId, content)
        let seconds = 10
        let events = run(&state, content, ticks: content.economy.ticksPerSecond * seconds)
        #expect(events.count == Int(try #require(fx.fireRate) * Double(seconds)))
        #expect(events.allSatisfy { $0 == .shot(from: 100, at: 1) })
    }

    @Test func doesNotFireAtZombiesOutOfRange() throws {
        let content = try TestSupport.content()
        let r = try #require(try effects("watchtower", content).range)
        var (state, _) = try setup({ c in [CombatFixtures.tower(id: 100, def: try def("watchtower", c), at: spot)] },
                                   zombies: [zombie(1, dx: r + 0.1, dy: 0, hp: 100)])
        #expect(run(&state, content, ticks: content.economy.ticksPerSecond * 3).isEmpty)
    }

    @Test(arguments: ["watchtower", "mg_nest"])
    func eachShotDoesTheLevelsDamage(defId: String) throws {
        var (state, content) = try setup({ c in [CombatFixtures.tower(id: 100, def: try def(defId, c), at: spot)] },
                                         zombies: [zombie(1, dy: 1, hp: 1000)])
        let damage = try #require(try effects(defId, content).damage)
        let events = run(&state, content, ticks: content.economy.ticksPerSecond)
        #expect(state.base.zombies[0].hp == 1000 - damage * Double(events.count))
        #expect(!events.isEmpty)
    }

    @Test func levelTwoUsesLevelTwoRangeAndDamage() throws {
        let content = try TestSupport.content()
        let l1 = try effects("watchtower", level: 1, content), l2 = try effects("watchtower", level: 2, content)
        let r1 = try #require(l1.range), r2 = try #require(l2.range)
        try #require(r2 > r1)
        let between = (r1 + r2) / 2   // out of reach at level 1, in reach at level 2
        for level in [1, 2] {
            var (state, _) = try setup({ c in [CombatFixtures.tower(id: 100, def: try def("watchtower", c), at: spot, level: level)] },
                                       zombies: [zombie(1, dy: between, hp: 1000)])
            let events = run(&state, content, ticks: content.economy.ticksPerSecond)
            if level == 1 {
                #expect(events.isEmpty)
            } else {
                #expect(events == [.shot(from: 100, at: 1)])
                #expect(state.base.zombies[0].hp == 1000 - (try #require(l2.damage)))
            }
        }
    }

    @Test func secondTowerSkipsAZombieKilledEarlierInTheSameTick() throws {
        let content = try TestSupport.content()
        let mg = try def("mg_nest", content)
        let damage = try #require(try effects("mg_nest", content).damage)
        let perShot = TowerFiring.ticksPerShot(fireRate: try #require(mg.level(1)?.effects.fireRate),
                                               ticksPerSecond: content.economy.ticksPerSecond)
        // Ids a whole shot period apart fire on the same ticks.
        var (state, _) = try setup({ _ in [CombatFixtures.tower(id: 100, def: mg, at: spot),
                                           CombatFixtures.tower(id: 100 + perShot, def: mg, at: GridPoint(x: spot.x + 1, y: spot.y))] },
                                   zombies: [zombie(1, dx: 0.5, dy: 1, hp: damage), zombie(2, dx: 0.5, dy: 2, hp: tough)])
        let events = run(&state, content, ticks: perShot)
        #expect(events == [.shot(from: 100, at: 1), .shot(from: 100 + perShot, at: 2)])
        #expect(state.base.zombies[0].hp <= 0)
    }

    @Test func sameSetupGivesSameShots() throws {
        func once() throws -> ([SimEvent], [Zombie]) {
            var (state, content) = try setup({ c in
                [CombatFixtures.tower(id: 100, def: try def("watchtower", c), at: spot),
                 CombatFixtures.tower(id: 101, def: try def("mg_nest", c), at: GridPoint(x: spot.x + 2, y: spot.y))]
            }, zombies: (1...6).map { zombie($0, dx: Double($0 % 3), dy: Double($0) * 0.7, hp: 90) })
            let events = run(&state, content, ticks: content.economy.ticksPerSecond * 4)
            return (events, state.base.zombies)
        }
        let (a, b) = (try once(), try once())
        #expect(a.0 == b.0)
        #expect(a.1 == b.1)
        #expect(!a.0.isEmpty)
    }

    @Test func startingWatchtowerShootsDuringGameLoop() throws {
        let content = try TestSupport.content()
        let map = try #require(content.maps["phase1_exit"])
        let start = try #require(map.startingPositions.first { $0.id == "watchtower" })
        let loop = try TestSupport.loop { state in
            state.base.zombies = [Zombie(id: 1, defId: "walker", x: Double(start.x) + 0.5, y: Double(start.y) + 1.5, hp: 1e9)]
        }
        let tower = try #require(loop.state.base.buildings.first { $0.defId == "watchtower" })
        loop.step(ticks: content.economy.ticksPerSecond)
        #expect(loop.drainEvents().contains(.shot(from: tower.id, at: 1)))
    }
}
