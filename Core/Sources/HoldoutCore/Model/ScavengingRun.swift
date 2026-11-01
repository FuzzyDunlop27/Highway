// Purpose: A scavenging run in progress (survivors away from a Scavenger Post) and the Workshop's current research. Notes: docs/features/scavenging-research.md
import Foundation

/// Survivors sent from a Scavenger Post. They are away (not working, not at risk) until `ticksLeft` hits 0;
/// the reward then waits at the post (`Building.heldReward`) until the player collects it.
public struct ScavengingRun: Codable, Equatable, Sendable {
    public let buildingId: BuildingID
    /// Which `scavenger.runs.types` entry.
    public let typeId: String
    public let survivors: Int
    public var ticksLeft: Int
    public let ticksTotal: Int

    public init(buildingId: BuildingID, typeId: String, survivors: Int, ticksLeft: Int, ticksTotal: Int) {
        self.buildingId = buildingId
        self.typeId = typeId
        self.survivors = survivors
        self.ticksLeft = ticksLeft
        self.ticksTotal = ticksTotal
    }

    public var progress: Double { ticksTotal == 0 ? 1 : 1 - Double(ticksLeft) / Double(ticksTotal) }
}

/// The one research item being worked on at the Workshop. It only advances while the Workshop is finished and staffed.
public struct ActiveResearch: Codable, Equatable, Sendable {
    public let itemId: String
    public var ticksLeft: Int
    public let ticksTotal: Int
    /// What was paid at the start (kept in case the Workshop is demolished and the cost is returned).
    public let paid: Cost

    public init(itemId: String, ticksLeft: Int, ticksTotal: Int, paid: Cost) {
        self.itemId = itemId
        self.ticksLeft = ticksLeft
        self.ticksTotal = ticksTotal
        self.paid = paid
    }

    public var progress: Double { ticksTotal == 0 ? 1 : 1 - Double(ticksLeft) / Double(ticksTotal) }
}
