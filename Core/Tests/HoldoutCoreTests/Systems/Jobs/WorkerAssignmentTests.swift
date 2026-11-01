// Purpose: Tests choosing worker counts, survivors never double-booked, and staffing scaling production. Notes: docs/features/jobs-defenders.md
import Foundation
import Testing
@testable import HoldoutCore

struct WorkerAssignmentTests {
    private typealias S = JobsTestSupport

    @Test func newBuildingsFillAutomatically() throws {
        let loop = try S.loop([("farm", S.farmSpot)])
        #expect(S.building(loop, "farm").staffed == 2)
        #expect(S.building(loop, "farm").assignedWorkers == nil)
    }

    @Test func setWorkersLimitsTheCrew() throws {
        let loop = try S.loop([("farm", S.farmSpot), ("wall_wood", GridPoint(x: 1, y: 1))])
        let farm = S.building(loop, "farm").id
        #expect(loop.send(.setWorkers(id: farm, count: 1)) == .success(.workersSet))
        #expect(S.building(loop, "farm").staffed == 1)
        #expect(loop.send(.setWorkers(id: farm, count: 0)) == .success(.workersSet))
        #expect(S.building(loop, "farm").staffed == 0)
        #expect(loop.send(.setWorkers(id: farm, count: 3)) == .failure(.jobs(.tooManyWorkers(max: 2))))
        #expect(loop.send(.setWorkers(id: farm, count: -1)) == .failure(.jobs(.tooManyWorkers(max: 2))))
        let wall = S.building(loop, "wall_wood").id
        #expect(loop.send(.setWorkers(id: wall, count: 1)) == .failure(.jobs(.notAWorkplace)))
        #expect(loop.send(.setWorkers(id: 999, count: 1)) == .failure(.unknownBuildingID(999)))
    }

    @Test func fewerWorkersMeansProportionallyLessFood() throws {
        func foodAfterAMinute(workers: Int) throws -> Int {
            let loop = try S.loop([("farm", S.farmSpot)], stock: Cost(scrap: 0, food: 0))
            loop.send(.setWorkers(id: S.building(loop, "farm").id, count: workers))
            let before = loop.state.base.stock.food
            loop.step(ticks: S.ticks(60, loop))
            return loop.state.base.stock.food - before
        }
        let full = try foodAfterAMinute(workers: 2)
        #expect(full == 10)
        #expect(try foodAfterAMinute(workers: 1) == full / 2)
        #expect(try foodAfterAMinute(workers: 0) == 0)
    }

    @Test func notEnoughSurvivorsFillsOldestFirst() throws {
        let loop = try S.loop([("farm", S.farmSpot), ("workshop", S.workshopSpot)], survivors: 3)
        #expect(S.building(loop, "farm").staffed == 2)
        #expect(S.building(loop, "workshop").staffed == 1)
        #expect(loop.population.idle == 0)
    }

    @Test func freedSurvivorsStayIdle() throws {
        let loop = try S.loop([("farm", S.farmSpot)], survivors: 5)
        loop.send(.setWorkers(id: S.building(loop, "farm").id, count: 0))
        #expect(loop.population.idle == 5)
        #expect(loop.resources.idleSurvivors == 5)
    }

    @Test func nobodyIsEverBookedTwice() throws {
        let loop = try S.loop([("farm", S.farmSpot), ("barracks", S.barracksSpot), ("scavenger", S.postSpot)], survivors: 5)
        loop.send(.trainDefender)
        loop.send(.startRun(buildingId: S.building(loop, "scavenger").id, runId: "quick"))
        loop.send(.placeBuilding(defId: "wall_wood", at: GridPoint(x: 2, y: 2)))
        for _ in 0..<40 {
            loop.step(ticks: 25)
            let p = loop.population
            #expect(p.working + p.building + p.away + p.defenders + p.training + p.idle == p.total)
            #expect(p.idle >= 0 && p.working >= 0)
        }
    }

    @Test func buildersAndRunnersComeBeforeWorkers() throws {
        let loop = try S.loop([("farm", S.farmSpot), ("scavenger", S.postSpot)], survivors: 3)
        #expect(S.building(loop, "farm").staffed == 2)
        loop.send(.startRun(buildingId: S.building(loop, "scavenger").id, runId: "quick"))  // takes 2
        #expect(loop.population.away == 2)
        #expect(S.building(loop, "farm").staffed <= 1)
        #expect(loop.population.working + loop.population.away <= 3)
    }
}
