// Purpose: Saved horde data for a base: day count, clock to the next horde, warned edges, the horde in progress. Notes: docs/features/hordes.md
import Foundation

public struct HordeState: Codable, Equatable, Sendable {
    /// Day of the next (or current) horde, starting at 1. Goes up when a horde ends.
    public var day: Int
    /// Ticks until the next horde arrives; nil = not scheduled yet (HordeSystem schedules it from hordes.json).
    public var ticksUntilNext: Int?
    /// Spawn edges announced for the next horde (filled when the warning starts, empty otherwise).
    public var warningEdges: [String]
    /// The horde attacking right now, if any.
    public var active: ActiveHorde?
    public var nextZombieID: ZombieID

    public init(day: Int, ticksUntilNext: Int?, warningEdges: [String], active: ActiveHorde?, nextZombieID: ZombieID) {
        self.day = day
        self.ticksUntilNext = ticksUntilNext
        self.warningEdges = warningEdges
        self.active = active
        self.nextZombieID = nextZombieID
    }

    public static let initial = HordeState(day: 1, ticksUntilNext: nil, warningEdges: [], active: nil, nextZombieID: 1)
}

public struct ActiveHorde: Codable, Equatable, Sendable {
    /// Map spawn-edge ids zombies enter from.
    public var edges: [String]
    /// Zombie types still to spawn, in order.
    public var spawnQueue: [String]
    public var ticksUntilNextSpawn: Int
    public var spawned: Int
    public var killed: Int
    /// Loot multiplier (1 normally; hordes.json bonusHorde.lootMultiplier for bonus hordes in 1D).
    public var lootMultiplier: Double
    public var isBonus: Bool

    public init(edges: [String], spawnQueue: [String], ticksUntilNextSpawn: Int = 0, spawned: Int = 0, killed: Int = 0,
                lootMultiplier: Double = 1, isBonus: Bool = false) {
        self.edges = edges
        self.spawnQueue = spawnQueue
        self.ticksUntilNextSpawn = ticksUntilNextSpawn
        self.spawned = spawned
        self.killed = killed
        self.lootMultiplier = lootMultiplier
        self.isBonus = isBonus
    }
}
