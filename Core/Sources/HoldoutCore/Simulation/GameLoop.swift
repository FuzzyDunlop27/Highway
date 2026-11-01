// Purpose: Runs the fixed-tick simulation and is the App's single entry point into Core. Notes: docs/features/core-api.md
import Foundation

/// Owns the game state and advances it in fixed ticks (economy.json ticksPerSecond).
/// Use it from one thread (the App's main actor). See docs/features/core-api.md.
public final class GameLoop {
    public let content: GameContent
    public private(set) var state: GameState
    /// Real time not yet turned into a tick (not saved; less than one tick).
    private var leftoverSeconds: Double = 0
    /// What happened since the App last called `drainEvents()` (not saved; capped so tests needn't drain).
    public private(set) var events: [SimEvent] = []
    /// Zombie path costs toward the HQ, rebuilt only when buildings change (not saved; derived from state).
    public let flowFields = FlowFieldCache()
    private static let maxQueuedEvents = 5_000

    public enum LoopError: Error, Equatable { case unknownMap(String) }

    /// Wraps a new or loaded state. Throws if the state's map isn't in `content`.
    public init(content: GameContent, state: GameState) throws {
        guard content.maps[state.base.mapId] != nil else { throw LoopError.unknownMap(state.base.mapId) }
        self.content = content
        self.state = state
    }

    /// The map the active base is on (tiles, decorations, spawn edges).
    public var map: MapDef { content.maps[state.base.mapId]! }

    // MARK: Time

    /// Call every frame with real seconds since the last frame. Applies game speed, caps the gap at
    /// economy.json maxFrameSeconds, runs whole ticks, and returns how many ran.
    @discardableResult
    public func advance(realSeconds: Double) -> Int {
        let tickLength = 1 / Double(content.economy.ticksPerSecond)
        leftoverSeconds += min(max(realSeconds, 0), content.economy.maxFrameSeconds) * Double(state.speed)
        let ticks = Int((leftoverSeconds / tickLength + 1e-9).rounded(.down))
        leftoverSeconds = max(0, leftoverSeconds - Double(ticks) * tickLength)
        step(ticks: ticks)
        return ticks
    }

    /// Runs exactly `ticks` simulation ticks, ignoring speed (tests and, later, offline catch-up).
    public func step(ticks: Int = 1) {
        for _ in 0..<max(0, ticks) {
            BuildQueue.tick(&state, content: content)
            DefenderPosts.releaseFromBrokenTowers(&state)
            DefenderTraining.tick(&state, content: content, events: &events)
            ScavengingSystem.tick(&state, content: content, events: &events)
            ResearchSystem.tick(&state, content: content, events: &events)
            Staffing.assign(&state, content: content)
            EconomySystem.tick(&state, content: content)
            HordeSystem.tick(&state, content: content, events: &events)
            ZombieMovement.tick(&state, content: content, fields: flowFields, events: &events)
            TowerFiring.tick(&state, content: content, fields: flowFields, events: &events)
            DefenderCombat.tick(&state, content: content, events: &events)
            HordeResolution.tick(&state, content: content, events: &events)
            state.tick += 1
        }
        if events.count > Self.maxQueuedEvents { events.removeFirst(events.count - Self.maxQueuedEvents) }
    }

    /// Returns and clears everything that happened since the last call (the App draws these as effects).
    public func drainEvents() -> [SimEvent] {
        defer { events.removeAll(keepingCapacity: true) }
        return events
    }

    // MARK: Commands

    /// Applies a player action right away. On failure nothing changes.
    @discardableResult
    public func send(_ command: Command) -> Result<CommandOutcome, CommandError> {
        switch command {
        case .placeBuilding(let defId, let at):
            let result = ConstructionSystem.place(defId: defId, at: at, state: &state, content: content)
            BuildQueue.startJobs(&state, content: content)
            Staffing.assign(&state, content: content)
            return result
        case .placeLine(let defId, let from, let to):
            let result = WallLinePlanner.place(defId: defId, from: from, to: to, state: &state, content: content)
            BuildQueue.startJobs(&state, content: content)
            Staffing.assign(&state, content: content)
            return result
        case .moveBuilding(let id, let to):
            return ConstructionSystem.move(id: id, to: to, state: &state, content: content)
        case .demolish(let id):
            return ConstructionSystem.demolish(id: id, state: &state, content: content)
        case .setSpeed(let speed):
            guard content.economy.speedOptions.contains(speed) else { return .failure(.invalidSpeed(speed)) }
            state.speed = speed
            return .success(.speedSet)
        case .repair(let id):
            let result = RepairSystem.repair(id: id, state: &state, content: content)
            BuildQueue.startJobs(&state, content: content)
            Staffing.assign(&state, content: content)
            return result
        case .upgrade(let id):
            let result = UpgradeSystem.upgrade(id: id, state: &state, content: content)
            BuildQueue.startJobs(&state, content: content)
            Staffing.assign(&state, content: content)
            return result
        case .cancelJob(let id):
            return BuildQueue.cancel(buildingId: id, state: &state, content: content)
        case .setWorkers(let id, let count):
            return WorkerAssignment.set(id: id, count: count, state: &state, content: content)
        case .trainDefender:
            return DefenderTraining.queue(&state, content: content)
        case .cancelTraining(let index):
            return DefenderTraining.cancel(index: index, state: &state, content: content)
        case .garrison(let defender, let tower):
            return DefenderPosts.garrison(defender, in: tower, state: &state, content: content)
        case .holdSpot(let defender, let tile):
            return DefenderPosts.hold(defender, at: tile, state: &state, content: content)
        case .recallDefender(let defender):
            return DefenderPosts.recall(defender, state: &state, content: content)
        case .startRun(let id, let runId):
            return ScavengingSystem.start(buildingId: id, runId: runId, state: &state, content: content)
        case .collectRun(let id):
            return ScavengingSystem.collect(buildingId: id, state: &state, content: content)
        case .startResearch(let id):
            return ResearchSystem.start(id, state: &state, content: content)
        case .debugStartHorde:
            HordeSystem.startNow(&state, content: content, events: &events)
            return .success(.debugDone)
        case .debugAddResources(let amount):
            state.base.stock = state.base.stock + amount
            StorageRules.clampToCaps(&state.base, content: content)
            return .success(.debugDone)
        case .debugKillAllZombies:
            state.base.zombies.removeAll()
            return .success(.debugDone)
        }
    }

    // MARK: Questions the App asks

    /// "Can I place `defId` with its top-left tile here?" — for the ghost preview. Includes cost and limits.
    public func checkPlacement(defId: String, at origin: GridPoint) -> PlacementCheck {
        ConstructionSystem.checkPlace(defId: defId, at: origin, state: state, content: content)
    }

    /// What `.placeLine` would build from `from` to `to`: path, buildable/skipped tiles, total cost (wall tool preview).
    public func planLine(defId: String, from: GridPoint, to: GridPoint) -> LinePlan {
        WallLinePlanner.plan(defId: defId, from: from, to: to, state: state, content: content)
    }

    /// "Can building `id` move here?" — ground only (moving is free). Nil if `id` doesn't exist.
    public func checkMove(id: BuildingID, to origin: GridPoint) -> PlacementCheck? {
        ConstructionSystem.checkMove(id: id, to: origin, state: state, content: content)
    }

    /// What `.repair(id:)` would cost right now, or nil if the building needs no repair (for the Repair button).
    public func repairCost(id: BuildingID) -> Cost? {
        guard let b = state.base.building(id), let level = content.buildingDef(b.defId)?.level(b.level) else { return nil }
        return RepairSystem.quote(b, level: level, content: content)?.cost
    }

    /// "Why can't building `id` be upgraded?" — nil means `.upgrade(id:)` would be accepted.
    public func upgradeProblem(id: BuildingID) -> UpgradeProblem? {
        UpgradeSystem.problem(id: id, state: state, content: content)
    }

    /// What upgrading `id` to its next level would cost, or nil at the top level (for the Upgrade button).
    public func upgradeCost(id: BuildingID) -> Cost? {
        state.base.building(id).flatMap { UpgradeSystem.nextLevel(of: $0, content: content) }?.cost
    }

    /// Why a defender can't be queued at the Barracks right now (nil = `.trainDefender` would be accepted).
    public func trainingProblem() -> TrainingProblem? { DefenderTraining.problem(state, content: content) }

    /// Why a run can't start (nil = `.startRun` would be accepted).
    public func runProblem(buildingId: BuildingID, runId: String) -> RunProblem? {
        ScavengingSystem.problem(buildingId: buildingId, runId: runId, state: state, content: content)
    }

    /// Why research `id` can't start (nil = `.startResearch` would be accepted).
    public func researchProblem(_ id: String) -> ResearchProblem? { ResearchSystem.problem(id, state: state, content: content) }

    /// Who is working, building, away, defending or idle.
    public var population: PopulationSnapshot { Roster.snapshot(state) }

    /// A tower's range in tiles right now, including researched bonuses (nil if the building isn't a tower).
    public func towerRange(id: BuildingID) -> Double? {
        guard let b = state.base.building(id), let range = content.buildingDef(b.defId)?.level(b.level)?.effects.range else { return nil }
        return range + ResearchEffects.towerRangeBonus(defId: b.defId, knowledge: state.group.knowledge, content: content)
    }

    /// Build slots, queue and builders, for the build-queue strip.
    public var buildQueue: BuildQueueStatus { BuildQueueStatus.make(state: state, content: content) }

    /// Day, countdown, warned edges, and zombies left, for the HUD.
    public var hordeStatus: HordeStatus { HordeStatus.make(state: state, content: content) }

    /// Resources, caps, survivors, housing, and current rates for the HUD.
    public var resources: ResourceSnapshot { ResourceSnapshot.make(state: state, content: content) }

    /// The building whose footprint covers `tile`, if any (for tap-to-select).
    public func building(at tile: GridPoint) -> Building? {
        state.base.buildings.first { b in
            guard let def = content.buildingDef(b.defId) else { return false }
            return b.origin.footprintTiles(width: def.width, height: def.height).contains(tile)
        }
    }
}
