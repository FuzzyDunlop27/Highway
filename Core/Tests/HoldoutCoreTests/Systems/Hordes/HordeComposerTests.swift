// Purpose: Tests horde budget (day, town value, cap), composition brackets, guaranteed units, weights, edges, determinism. Notes: docs/features/hordes.md
import Testing
@testable import HoldoutCore

struct HordeComposerTests {
    private func state(seed: UInt64 = 42) throws -> (GameState, GameContent) {
        let content = try TestSupport.content()
        return (try GameState.newGame(content: content, mapId: "phase1_exit", seed: seed), content)
    }

    private func cost(_ id: String, _ content: GameContent) -> Int {
        content.zombies.zombies.first { $0.id == id }!.threatCost
    }

    /// Adds a finished farm that cost `scrap` (only `invested` matters for town value).
    private func addBuilding(investedScrap scrap: Int, to state: inout GameState, rubble: Bool = false) {
        state.base.buildings.append(Building(id: 900 + state.base.buildings.count, defId: "farm", level: 1,
                                             origin: GridPoint(x: 0, y: 0), hp: 300, constructionTicksLeft: 0,
                                             constructionTicksTotal: 0, invested: Cost(scrap: scrap), isRubble: rubble))
    }

    @Test func sameSeedGivesTheSameHorde() throws {
        var (a, content) = try state(seed: 99)
        var (b, _) = try state(seed: 99)
        for day in [1, 3, 6, 12] {
            let ha = HordeComposer.compose(day: day, state: &a, content: content)
            let hb = HordeComposer.compose(day: day, state: &b, content: content)
            #expect(ha.queue == hb.queue && ha.edges == hb.edges)
        }
        #expect(a.random == b.random)
    }

    @Test func budgetGrowsWithDayAndTownValueAndIsCapped() throws {
        var (s, content) = try state()
        let b = content.hordes.budget
        // Starting buildings were free, so town value is 0 and the factor is 1.
        #expect(HordeComposer.townValue(s.base) == 0)
        #expect(HordeComposer.budget(day: 1, base: s.base, content: content) == Int(b.baseBudget.rounded()))
        #expect(HordeComposer.budget(day: 4, base: s.base, content: content) == Int((b.baseBudget + 3 * b.budgetPerDay).rounded()))

        addBuilding(investedScrap: Int(b.townValueDivisor / 5), to: &s)
        #expect(HordeComposer.budget(day: 4, base: s.base, content: content)
                == Int(((b.baseBudget + 3 * b.budgetPerDay) * 1.2).rounded()))

        addBuilding(investedScrap: Int(b.townValueDivisor * 10), to: &s)
        #expect(HordeComposer.budget(day: 4, base: s.base, content: content)
                == Int(((b.baseBudget + 3 * b.budgetPerDay) * b.townFactorMax).rounded()))
    }

    @Test func rubbleAndStoredResourcesDontCountAsTownValue() throws {
        var (s, _) = try state()
        s.base.stock = Cost(scrap: 400, food: 400)
        addBuilding(investedScrap: 500, to: &s, rubble: true)
        #expect(HordeComposer.townValue(s.base) == 0)
        addBuilding(investedScrap: 70, to: &s)
        #expect(HordeComposer.townValue(s.base) == 70)
    }

    @Test func earlyDaysUseOnlyWalkersAndSpendTheBudget() throws {
        var (s, content) = try state()
        let budget = HordeComposer.budget(day: 1, base: s.base, content: content)
        let horde = HordeComposer.compose(day: 1, state: &s, content: content)
        #expect(horde.queue == Array(repeating: "walker", count: budget / cost("walker", content)))
        #expect(horde.edges.count == content.hordes.composition[0].edgeCount)
    }

    @Test func guaranteedUnitsComeFirstAndPayFromTheBudget() throws {
        var (s, content) = try state()
        let horde = HordeComposer.compose(day: 3, state: &s, content: content)
        #expect(horde.queue.first == "brute")
        #expect(horde.queue.filter { $0 == "brute" }.count == 1)  // brute weight is 0 on days 3–4
        let spent = horde.queue.reduce(0) { $0 + cost($1, content) }
        let budget = HordeComposer.budget(day: 3, base: s.base, content: content)
        #expect(spent <= budget && spent > budget - cost("walker", content))
        #expect(horde.edges.count == 2)
    }

    @Test func daysPastTheLastRangeUseTheLastBracket() throws {
        var (s, content) = try state()
        let last = try #require(content.hordes.composition.last)
        let horde = HordeComposer.compose(day: last.days[1] + 50, state: &s, content: content)
        #expect(Array(horde.queue.prefix(2)) == ["brute", "brute"])
        #expect(horde.edges.count == last.edgeCount)
        #expect(Set(horde.edges).count == horde.edges.count)
        #expect(horde.edges.allSatisfy { e in content.maps["phase1_exit"]!.spawnEdges.contains { $0.id == e } })
    }

    @Test func weightsShapeTheMix() throws {
        var counts: [String: Int] = [:]
        for seed in UInt64(1)...40 {
            var (s, content) = try state(seed: seed)
            for id in HordeComposer.composeQueue(day: 6, state: &s, content: content).dropFirst() { counts[id, default: 0] += 1 }
        }
        // Days 5–8: walker 55, runner 30, brute 15 (picks are by count, so walkers lead).
        #expect(counts["walker", default: 0] > counts["runner", default: 0])
        #expect(counts["runner", default: 0] > 0 && counts["brute", default: 0] > 0)
    }
}
