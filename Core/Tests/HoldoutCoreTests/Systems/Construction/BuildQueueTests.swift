// Purpose: Tests build slots, the waiting queue, builders, pay-on-start, cancelling, and upgrades. Notes: docs/features/construction.md
import Foundation
import Testing
@testable import HoldoutCore

struct BuildQueueTests {
    private let wall = "wall_wood"

    private func wallSpot(_ i: Int) -> GridPoint { GridPoint(x: i, y: 26) }

    @discardableResult
    private func placeWall(_ loop: GameLoop, _ i: Int) -> BuildingID? {
        if case .success(.placed(let id)) = loop.send(.placeBuilding(defId: wall, at: wallSpot(i))) { return id }
        return nil
    }

    private func richLoop(survivors: Int = 6) throws -> GameLoop {
        try TestSupport.loop { $0.base.stock = Cost(scrap: 400, food: 200); $0.group.survivors = survivors }
    }

    // MARK: Slots, queue, pay on start

    @Test func onlyAsManyJobsRunAsTheHqHasSlots() throws {
        let loop = try richLoop()
        for i in 0..<5 { placeWall(loop, i) }
        let slots = loop.content.buildings.rules.constructionSlotsByHq[0]
        #expect(loop.buildQueue.slots == slots)
        #expect(loop.buildQueue.active == slots)
        #expect(loop.buildQueue.queued == 5 - slots)
    }

    @Test func costIsPaidWhenAJobStartsNotWhenQueued() throws {
        let loop = try richLoop()
        let cost = loop.content.buildingDef(wall)!.level(1)!.cost
        let before = loop.state.base.stock.scrap
        for i in 0..<4 { placeWall(loop, i) }
        let slots = loop.buildQueue.slots
        #expect(loop.state.base.stock.scrap == before - cost.scrap * slots)
        let queuedId = try #require(loop.state.base.jobs.first { !$0.started }).buildingId
        #expect(loop.state.base.building(queuedId)?.invested == .zero)
        loop.step(ticks: TestSupport.ticks(loop.content.buildingDef(wall)!.level(1)!.buildSeconds, loop))
        // The first jobs finished; the waiting ones started by themselves and paid.
        #expect(loop.state.base.jobs.allSatisfy { $0.started })
        #expect(loop.state.base.building(queuedId)?.invested == cost)
        #expect(loop.state.base.stock.scrap == before - cost.scrap * 4)
    }

    @Test func aJobStuckOnResourcesLetsACheaperOneGoFirst() throws {
        let setup = try richLoop()
        placeWall(setup, 0)
        placeWall(setup, 1)  // both slots busy
        let hqId = hq(setup).id
        #expect(setup.send(.upgrade(id: hqId)).isSuccess)  // queued first (300 scrap, 150 food)
        let wallId = try #require(placeWall(setup, 2))     // queued behind it
        let loop = try setup.edited { $0.base.stock = Cost(scrap: 50, food: 0) }  // the upgrade is now out of reach
        loop.step(ticks: TestSupport.ticks(loop.content.buildingDef(wall)!.level(1)!.buildSeconds, loop))
        #expect(loop.state.base.job(for: hqId)?.started == false)
        #expect(loop.state.base.job(for: wallId)?.started == true)
        // Money arrives and the upgrade starts by itself.
        loop.send(.debugAddResources(Cost(scrap: 400, food: 200)))
        loop.step()
        #expect(loop.state.base.job(for: hqId)?.started == true)
    }

    @Test func queueFullStopsNewBuildings() throws {
        let loop = try richLoop()
        let capacity = loop.buildQueue.slots + loop.buildQueue.queueLength
        for i in 0..<capacity { #expect(placeWall(loop, i) != nil) }
        #expect(loop.checkPlacement(defId: wall, at: wallSpot(capacity)).problem == .queueFull)
        #expect(loop.send(.placeBuilding(defId: wall, at: wallSpot(capacity))) == .failure(.placement(.queueFull)))
    }

    // MARK: Builders

    @Test func buildersAreBorrowedWhileAJobRunsAndReturnedWhenDone() throws {
        let loop = try richLoop(survivors: 6)
        let per = loop.content.buildings.rules.buildersPerJob
        placeWall(loop, 0)
        #expect(loop.buildQueue.freeBuilders == 6 - per)
        loop.step(ticks: TestSupport.ticks(loop.content.buildingDef(wall)!.level(1)!.buildSeconds, loop))
        #expect(loop.buildQueue.freeBuilders == 6)
    }

    @Test func noFreeBuilderMeansTheJobWaits() throws {
        let loop = try richLoop(survivors: 1)
        placeWall(loop, 0)
        let second = try #require(placeWall(loop, 1))
        #expect(loop.buildQueue.active == 1 && loop.state.base.job(for: second)?.started == false)
        loop.step(ticks: TestSupport.ticks(loop.content.buildingDef(wall)!.level(1)!.buildSeconds, loop))
        #expect(loop.state.base.job(for: second)?.started == true)
    }

    @Test func staffingLeavesBuildersAlone() throws {
        let loop = try TestSupport.loop { $0.base.stock = Cost(scrap: 400, food: 200); $0.group.survivors = 2 }
        placeWall(loop, 0)  // one builder; only the other survivor can man the watchtower
        let staffed = loop.state.base.buildings.reduce(0) { $0 + $1.staffed }
        #expect(staffed <= loop.state.group.survivors - loop.content.buildings.rules.buildersPerJob)
    }

    // MARK: Cancel

    @Test func cancellingAWaitingBuildingCostsNothingAndRemovesIt() throws {
        let loop = try richLoop()
        for i in 0..<3 { placeWall(loop, i) }
        let waiting = try #require(loop.state.base.jobs.first { !$0.started }).buildingId
        let stock = loop.state.base.stock
        #expect(loop.send(.cancelJob(buildingId: waiting)) == .success(.cancelled(refund: .zero)))
        #expect(loop.state.base.building(waiting) == nil)
        #expect(loop.state.base.stock == stock)
    }

    @Test func cancellingARunningBuildingRefundsAShareAndFreesTheSlot() throws {
        let loop = try richLoop()
        for i in 0..<3 { placeWall(loop, i) }
        let running = try #require(loop.state.base.jobs.first { $0.started }).buildingId
        let cost = loop.content.buildingDef(wall)!.level(1)!.cost
        let refund = cost.percent(loop.content.buildings.rules.cancelRefundPct)
        let stock = loop.state.base.stock
        // Cancelling frees the slot, so the waiting wall starts at once and pays.
        #expect(loop.send(.cancelJob(buildingId: running)) == .success(.cancelled(refund: refund)))
        #expect(loop.state.base.building(running) == nil)
        #expect(loop.state.base.stock.scrap == stock.scrap + refund.scrap - cost.scrap)
        #expect(loop.buildQueue.active == loop.buildQueue.slots && loop.buildQueue.queued == 0)
    }

    @Test func cancelWithNoJobFails() throws {
        let loop = try richLoop()
        let hq = try #require(loop.state.base.buildings.first { $0.defId == "hq" })
        #expect(loop.send(.cancelJob(buildingId: hq.id)) == .failure(.noJob(hq.id)))
    }

    @Test func demolishingAnUnfinishedBuildingDropsItsJob() throws {
        let loop = try richLoop()
        let id = try #require(placeWall(loop, 0))
        loop.send(.demolish(id: id))
        #expect(loop.state.base.jobs.isEmpty && loop.buildQueue.freeBuilders == 6)
    }

    // MARK: Upgrades

    private func hq(_ loop: GameLoop) -> Building { loop.state.base.buildings.first { $0.defId == "hq" }! }

    @Test func hqUpgradePaysTakesTimeAndAppliesEffectsOnlyWhenDone() throws {
        let loop = try richLoop()
        let l2 = loop.content.buildingDef("hq")!.level(2)!
        let id = hq(loop).id
        let housing = loop.resources.housing
        let stock = loop.state.base.stock
        #expect(loop.send(.upgrade(id: id)) == .success(.upgradeQueued(cost: l2.cost)))
        #expect(loop.state.base.stock == Cost(scrap: stock.scrap - l2.cost.scrap, food: stock.food - l2.cost.food))
        #expect(hq(loop).level == 1 && hq(loop).isComplete && loop.state.base.hqLevel == 1)  // keeps working at level 1
        loop.step(ticks: TestSupport.ticks(l2.buildSeconds, loop) - 1)
        #expect(hq(loop).level == 1 && loop.resources.housing == housing)
        loop.step()
        #expect(hq(loop).level == 2 && hq(loop).hp == l2.hp && loop.state.base.hqLevel == 2)
        let gain = (l2.effects.housing ?? 0) - (loop.content.buildingDef("hq")!.level(1)!.effects.housing ?? 0)
        #expect(loop.resources.housing == housing + gain && gain > 0)
        #expect(hq(loop).invested == l2.cost && loop.state.base.jobs.isEmpty)
    }

    @Test func upgradeIsGatedByHqLevelAndOtherRules() throws {
        let loop = try richLoop()
        var farm = try #require({ () -> BuildingID? in
            if case .success(.placed(let id)) = loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot)) { return id }
            return nil
        }())
        #expect(loop.upgradeProblem(id: farm) == .notFinished)
        loop.step(ticks: TestSupport.ticks(60, loop))
        #expect(loop.upgradeProblem(id: farm) == .needsHqLevel(2))
        #expect(loop.send(.upgrade(id: farm)) == .failure(.upgrade(.needsHqLevel(2))))
        #expect(loop.send(.upgrade(id: 999)) == .failure(.unknownBuildingID(999)))
        // Raise the HQ to level 2 and the farm can go up.
        let raised = try loop.edited { s in
            let i = s.base.buildings.firstIndex { $0.defId == "hq" }!
            s.base.buildings[i].level = 2
            s.base.stock = Cost(scrap: 400, food: 200)
        }
        farm = try #require(raised.state.base.buildings.first { $0.defId == "farm" }).id
        #expect(raised.upgradeProblem(id: farm) == nil)
        #expect(raised.send(.upgrade(id: farm)).isSuccess)
        #expect(raised.upgradeProblem(id: farm) == .alreadyWorking)
    }

    @Test func upgradeNeedsResourcesAndStopsAtMaxLevel() throws {
        let loop = try TestSupport.loop { $0.base.stock = Cost(scrap: 10, food: 0) }
        let id = hq(loop).id
        let cost = loop.content.buildingDef("hq")!.level(2)!.cost
        #expect(loop.send(.upgrade(id: id)) == .failure(.upgrade(.notEnoughResources(needed: cost))))
        let max = try loop.edited { s in
            let i = s.base.buildings.firstIndex { $0.defId == "hq" }!
            s.base.buildings[i].level = 3
        }
        #expect(max.upgradeProblem(id: id) == .maxLevel && max.upgradeCost(id: id) == nil)
    }

    @Test func cancellingARunningUpgradeRefundsAndKeepsTheOldLevel() throws {
        let loop = try richLoop()
        let id = hq(loop).id
        let cost = loop.content.buildingDef("hq")!.level(2)!.cost
        let stock = loop.state.base.stock
        loop.send(.upgrade(id: id))
        let refund = cost.percent(loop.content.buildings.rules.cancelRefundPct)
        #expect(loop.send(.cancelJob(buildingId: id)) == .success(.cancelled(refund: refund)))
        #expect(hq(loop).level == 1 && hq(loop).invested == .zero && loop.state.base.jobs.isEmpty)
        #expect(loop.state.base.stock.scrap == stock.scrap - cost.scrap + refund.scrap)
    }

    // MARK: Rubble

    @Test func rubbleRebuildWaitsInTheQueueAndPaysWhenItStarts() throws {
        let loop = try richLoop()
        let wallB = try #require(loop.state.base.buildings.first { $0.defId == wall })
        let rubble = try loop.edited { s in
            let i = s.base.buildings.firstIndex { $0.id == wallB.id }!
            s.base.buildings[i].isRubble = true
            s.base.buildings[i].hp = 0
        }
        let level = rubble.content.buildingDef(wall)!.level(1)!
        let quoted = try #require(rubble.repairCost(id: wallB.id))
        let stock = rubble.state.base.stock
        #expect(rubble.send(.repair(id: wallB.id)) == .success(.repairStarted(cost: quoted)))
        #expect(rubble.state.base.stock.scrap == stock.scrap - quoted.scrap)  // a slot was free, so it started and paid
        #expect(rubble.send(.repair(id: wallB.id)) == .failure(.nothingToRepair(wallB.id)))
        rubble.step(ticks: TestSupport.ticks(level.buildSeconds, rubble))
        #expect(rubble.state.base.building(wallB.id)?.isComplete == true)
    }

    // MARK: Save

    @Test func version2SaveWithAHalfBuiltBuildingMigratesToARunningJob() throws {
        let loop = try richLoop()
        loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
        loop.step(ticks: 100)
        let farm = try #require(loop.state.base.buildings.first { $0.defId == "farm" })
        var json = try JSONSerialization.jsonObject(with: SaveCodec.encode(loop.state)) as! [String: Any]
        var state = json["state"] as! [String: Any]
        var bases = state["bases"] as! [[String: Any]]
        bases[0].removeValue(forKey: "jobs")
        state["bases"] = bases
        json["state"] = state
        json["version"] = 2
        let decoded = try SaveCodec.decode(JSONSerialization.data(withJSONObject: json))
        let job = try #require(decoded.base.job(for: farm.id))
        #expect(job.started && job.ticksLeft == farm.constructionTicksLeft && job.cost == .zero)
        // It finishes on schedule and nobody is charged a second time.
        let reloaded = try GameLoop(content: loop.content, state: decoded)
        let scrap = reloaded.state.base.stock.scrap
        reloaded.step(ticks: farm.constructionTicksLeft)
        #expect(reloaded.state.base.building(farm.id)?.isComplete == true)
        #expect(reloaded.state.base.stock.scrap >= scrap)
    }
}
