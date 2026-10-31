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
            ConstructionSystem.tick(&state)
            Staffing.assign(&state, content: content)
            EconomySystem.tick(&state, content: content)
            HordeSystem.tick(&state, content: content, events: &events)
            ZombieMovement.tick(&state, content: content, fields: flowFields, events: &events)
            TowerFiring.tick(&state, content: content, fields: flowFields, events: &events)
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
            return RepairSystem.repair(id: id, state: &state, content: content)
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

    /// "Can building `id` move here?" — ground only (moving is free). Nil if `id` doesn't exist.
    public func checkMove(id: BuildingID, to origin: GridPoint) -> PlacementCheck? {
        ConstructionSystem.checkMove(id: id, to: origin, state: state, content: content)
    }

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
