// Purpose: Tests scavenging runs: start rules, absence, reward and multiplier, collect clamped to caps, levels. Notes: docs/features/scavenging-research.md
import Foundation
import Testing
@testable import HoldoutCore

struct ScavengingTests {
    private typealias S = JobsTestSupport

    private func run(_ loop: GameLoop, _ id: String) -> ScavengingRunDef {
        loop.content.buildingDef("scavenger")!.runs!.types.first { $0.id == id }!
    }

    private func postLoop(level: Int = 1, survivors: Int = 6, stock: Cost = Cost(scrap: 100, food: 100)) throws -> GameLoop {
        try S.loop([("scavenger", S.postSpot)], survivors: survivors, stock: stock) { $0.base.buildings[1].level = level }
    }

    @Test func aRunCostsFoodAndSendsSurvivorsAway() throws {
        let loop = try postLoop()
        let quick = run(loop, "quick")
        let post = S.building(loop, "scavenger").id
        #expect(loop.send(.startRun(buildingId: post, runId: "quick")) == .success(.runStarted(cost: quick.cost)))
        #expect(loop.state.base.stock == Cost(scrap: 100 - quick.cost.scrap, food: 100 - quick.cost.food))
        #expect(loop.population.away == quick.survivorsSent)
        #expect(S.building(loop, "scavenger").staffed <= 6 - quick.survivorsSent)
    }

    @Test func survivorsReturnAndTheRewardWaitsAtThePostAfterTheTimer() throws {
        let loop = try postLoop()
        let quick = run(loop, "quick")
        let post = S.building(loop, "scavenger").id
        loop.send(.startRun(buildingId: post, runId: "quick"))
        let ticks = S.ticks(quick.durationSeconds, loop)
        let scrapBefore = loop.state.base.stock.scrap
        loop.step(ticks: ticks - 1)
        #expect(loop.population.away == quick.survivorsSent)
        #expect(S.building(loop, "scavenger").heldReward == nil)
        loop.step()
        #expect(loop.population.away == 0)
        #expect(loop.state.base.runs.isEmpty)
        #expect(S.building(loop, "scavenger").heldReward == quick.reward)
        #expect(loop.drainEvents().contains(.runFinished(buildingId: post)))
        // Not in storage until collected (only the Post's own production added scrap).
        let produced = loop.state.base.stock.scrap - scrapBefore
        #expect(produced < quick.reward.scrap + 100)
        #expect(loop.send(.collectRun(buildingId: post)) == .success(.collected(quick.reward)))
        #expect(S.building(loop, "scavenger").heldReward == nil)
        #expect(loop.send(.collectRun(buildingId: post)) == .failure(.run(.nothingToCollect)))
    }

    @Test func collectingIsClampedToCapsAndTheRestStays() throws {
        let loop = try postLoop()
        let cap = StorageRules.cap(.scrap, base: loop.state.base, content: loop.content)
        let post = S.building(loop, "scavenger").id
        let full = try loop.edited { state in
            state.base.stock.scrap = cap - 10
            let i = state.base.buildings.firstIndex { $0.id == post }!
            state.base.buildings[i].heldReward = Cost(scrap: 60, food: 5)
        }
        #expect(full.send(.collectRun(buildingId: post)) == .success(.collected(Cost(scrap: 10, food: 5))))
        #expect(full.state.base.stock.scrap == cap)
        #expect(S.building(full, "scavenger").heldReward == Cost(scrap: 50, food: 0))
    }

    @Test func onlyOneRunPerPostAndLevelsUnlockRuns() throws {
        let loop = try postLoop()
        let post = S.building(loop, "scavenger").id
        #expect(loop.send(.startRun(buildingId: post, runId: "overnight")) == .failure(.run(.notUnlocked)))
        #expect(loop.send(.startRun(buildingId: post, runId: "nonsense")) == .failure(.run(.unknownRun)))
        #expect(loop.send(.startRun(buildingId: post, runId: "quick")).isSuccess)
        #expect(loop.send(.startRun(buildingId: post, runId: "long")) == .failure(.run(.postBusy)))
        let two = try postLoop(level: 2, stock: Cost(scrap: 0, food: 500))
        #expect(two.send(.startRun(buildingId: S.building(two, "scavenger").id, runId: "overnight")).isSuccess)
        #expect(two.population.away == run(two, "overnight").survivorsSent)
    }

    @Test func startRulesNeedSurvivorsFoodAndAFinishedPost() throws {
        let few = try postLoop(survivors: 1)
        let post = S.building(few, "scavenger").id
        #expect(few.send(.startRun(buildingId: post, runId: "quick")) == .failure(.run(.noFreeSurvivors(needed: 2))))
        let poor = try postLoop(stock: Cost(scrap: 100, food: 0))
        #expect(poor.send(.startRun(buildingId: S.building(poor, "scavenger").id, runId: "quick"))
                == .failure(.run(.notEnoughResources(needed: run(poor, "quick").cost))))
        let farm = try S.loop([("farm", S.farmSpot)])
        #expect(farm.send(.startRun(buildingId: S.building(farm, "farm").id, runId: "quick")) == .failure(.run(.notAPost)))
        let unfinished = try S.loop([("scavenger", S.postSpot)]) { $0.base.buildings[1].constructionTicksLeft = 5 }
        #expect(unfinished.send(.startRun(buildingId: S.building(unfinished, "scavenger").id, runId: "quick"))
                == .failure(.run(.notAPost)))
        #expect(few.send(.startRun(buildingId: 999, runId: "quick")) == .failure(.run(.unknownBuilding)))
    }

    @Test func level3PostsMultiplyTheReward() throws {
        let loop = try postLoop(level: 3, stock: Cost(scrap: 0, food: 500))
        let long = run(loop, "long")
        loop.send(.startRun(buildingId: S.building(loop, "scavenger").id, runId: "long"))
        loop.step(ticks: S.ticks(long.durationSeconds, loop))
        let factor = loop.content.buildingDef("scavenger")!.level(3)!.effects.runRewardMultiplier!
        #expect(S.building(loop, "scavenger").heldReward
                == Cost(scrap: Int((Double(long.reward.scrap) * factor).rounded(.down)),
                        food: Int((Double(long.reward.food) * factor).rounded(.down))))
    }

    @Test func demolishingThePostBringsSurvivorsHomeAndPaysOutTheReward() throws {
        let loop = try postLoop()
        let post = S.building(loop, "scavenger").id
        loop.send(.startRun(buildingId: post, runId: "quick"))
        loop.send(.demolish(id: post))
        #expect(loop.state.base.runs.isEmpty)
        #expect(loop.population.away == 0)
    }

    @Test func runsSurviveASaveRoundTrip() throws {
        let loop = try postLoop()
        loop.send(.startRun(buildingId: S.building(loop, "scavenger").id, runId: "quick"))
        loop.step(ticks: 100)
        let back = try GameLoop(content: loop.content, state: SaveCodec.decode(SaveCodec.encode(loop.state)))
        #expect(back.state == loop.state)
        loop.step(ticks: 3000)
        back.step(ticks: 3000)
        #expect(back.state == loop.state)
        #expect(S.building(back, "scavenger").heldReward != nil)
    }
}
