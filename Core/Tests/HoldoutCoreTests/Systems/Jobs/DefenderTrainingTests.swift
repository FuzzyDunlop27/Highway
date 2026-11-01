// Purpose: Tests the Barracks training queue: cost, time, caps, staffing, cancel and demolish refunds. Notes: docs/features/jobs-defenders.md
import Foundation
import Testing
@testable import HoldoutCore

struct DefenderTrainingTests {
    private typealias S = JobsTestSupport
    private func rule(_ loop: GameLoop) -> TrainingDef { loop.content.units.units.first { $0.training != nil }!.training! }

    @Test func needsAFinishedBarracks() throws {
        let loop = try S.loop()
        #expect(loop.send(.trainDefender) == .failure(.training(.needsBarracks)))
        let building = try S.loop([("barracks", S.barracksSpot)]) { $0.base.buildings[1].constructionTicksLeft = 50 }
        #expect(building.send(.trainDefender) == .failure(.training(.needsBarracks)))
    }

    @Test func trainingPaysTheCostAndTakesTheTime() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)], stock: Cost(scrap: 100, food: 100))
        let r = rule(loop)
        #expect(loop.send(.trainDefender) == .success(.trainingQueued(cost: r.cost)))
        #expect(loop.state.base.stock == Cost(scrap: 100 - r.cost.scrap, food: 100 - r.cost.food))
        #expect(loop.population.training == 1)
        let ticks = S.ticks(r.trainSeconds, loop)  // Barracks L1 trainTimeMultiplier is 1.0
        loop.step(ticks: ticks - 1)
        #expect(loop.state.base.defenders.isEmpty)
        loop.step()
        #expect(loop.state.base.defenders.count == 1)
        #expect(loop.state.base.defenders[0].post == .hq)
        #expect(loop.state.base.defenders[0].hp == loop.content.units.units.first { $0.id == "defender" }!.hp)
        #expect(loop.population.defenders == 1 && loop.population.training == 0)
        #expect(loop.drainEvents().contains(.defenderReady(1)))
    }

    @Test func eachDefenderUsesUpOneSurvivor() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)], survivors: 1)
        #expect(loop.send(.trainDefender).isSuccess)
        #expect(loop.send(.trainDefender) == .failure(.training(.noFreeSurvivor)))
        #expect(loop.population.idle == 0)
    }

    @Test func costMustBeAffordable() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)], stock: Cost(scrap: 0, food: 0))
        #expect(loop.send(.trainDefender) == .failure(.training(.notEnoughResources(needed: rule(loop).cost))))
    }

    @Test func queueLengthAndMaxDefendersAreEnforced() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)])
        let effects = loop.content.buildingDef("barracks")!.level(1)!.effects
        for _ in 0..<(effects.trainingQueueLength ?? 0) { #expect(loop.send(.trainDefender).isSuccess) }
        #expect(loop.send(.trainDefender) == .failure(.training(.queueFull)))
        let full = try S.loop([("barracks", S.barracksSpot)]) { state in
            for i in 1...(effects.maxDefenders ?? 0) { state.base.defenders.append(Defender(id: i, hp: 120)) }
        }
        #expect(full.send(.trainDefender) == .failure(.training(.maxDefenders(effects.maxDefenders ?? 0))))
    }

    @Test func onlyTheFirstJobProgressesAndTheNextFollows() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)])
        loop.send(.trainDefender)
        loop.send(.trainDefender)
        loop.step(ticks: S.ticks(rule(loop).trainSeconds, loop))
        #expect(loop.state.base.defenders.count == 1)
        #expect(loop.state.base.training.count == 1)
        #expect(loop.state.base.training[0].progress < 0.05)
        loop.step(ticks: S.ticks(rule(loop).trainSeconds, loop))
        #expect(loop.state.base.defenders.count == 2)
    }

    @Test func anUnstaffedBarracksPausesTraining() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)])
        loop.send(.trainDefender)
        loop.send(.setWorkers(id: S.building(loop, "barracks").id, count: 0))
        loop.step(ticks: S.ticks(rule(loop).trainSeconds * 2, loop))
        #expect(loop.state.base.defenders.isEmpty)
        loop.send(.setWorkers(id: S.building(loop, "barracks").id, count: 1))
        loop.step(ticks: S.ticks(rule(loop).trainSeconds, loop))
        #expect(loop.state.base.defenders.count == 1)
    }

    @Test func cancellingRefundsFullForWaitingAndAShareForTheActiveOne() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)], stock: Cost(scrap: 200, food: 200))
        let cost = rule(loop).cost
        loop.send(.trainDefender)
        loop.send(.trainDefender)
        let afterTwo = loop.state.base.stock
        #expect(loop.send(.cancelTraining(index: 1)) == .success(.trainingCancelled(refund: cost)))
        #expect(loop.state.base.stock == afterTwo + cost)
        let pct = loop.content.buildings.rules.cancelRefundPct
        #expect(loop.send(.cancelTraining(index: 0)) == .success(.trainingCancelled(refund: cost.percent(pct))))
        #expect(loop.send(.cancelTraining(index: 0)) == .failure(.training(.noSuchTraining)))
        #expect(loop.population.training == 0)
    }

    @Test func demolishingTheBarracksRefundsTheQueue() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)], stock: Cost(scrap: 200, food: 200))
        loop.send(.trainDefender)
        let before = loop.state.base.stock
        loop.send(.demolish(id: S.building(loop, "barracks").id))
        #expect(loop.state.base.training.isEmpty)
        #expect(loop.state.base.stock.scrap >= before.scrap + rule(loop).cost.scrap)
    }

    @Test func upgradedBarracksTrainsFaster() throws {
        let loop = try S.loop([("barracks", S.barracksSpot)]) { $0.base.buildings[1].level = 2 }
        loop.send(.trainDefender)
        let multiplier = loop.content.buildingDef("barracks")!.level(2)!.effects.trainTimeMultiplier!
        #expect(loop.state.base.training[0].ticksTotal == S.ticks(rule(loop).trainSeconds * multiplier, loop))
    }
}
