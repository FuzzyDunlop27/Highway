// Purpose: One piece of builder work (new building, upgrade, or rubble rebuild), waiting or running. Notes: docs/features/construction.md
import Foundation

/// A job sits in `Base.jobs` in the order it was queued. Queued jobs have paid nothing yet; the cost is paid when
/// the job starts (a slot, a free builder and the resources are all there). Started jobs count down `ticksLeft`.
public struct ConstructionJob: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        /// A new building: its `Building` already exists but isn't complete.
        case build
        /// A finished building going up one level; it keeps working at its old level meanwhile.
        case upgrade
        /// Rubble being rebuilt at its old level.
        case rebuild
    }

    public let buildingId: BuildingID
    public let kind: Kind
    /// Level the building has when the job is done.
    public let targetLevel: Int
    /// Price paid when the job starts (zero for a job migrated from an old save, which was paid long ago).
    public let cost: Cost
    public var started: Bool
    public var ticksLeft: Int
    public let ticksTotal: Int
    /// Survivors borrowed as builders until the job is done (0 while queued).
    public var builders: Int

    public init(buildingId: BuildingID, kind: Kind, targetLevel: Int, cost: Cost, started: Bool = false,
                ticksLeft: Int, ticksTotal: Int, builders: Int = 0) {
        self.buildingId = buildingId
        self.kind = kind
        self.targetLevel = targetLevel
        self.cost = cost
        self.started = started
        self.ticksLeft = ticksLeft
        self.ticksTotal = ticksTotal
        self.builders = builders
    }

    /// 0 to 1.
    public var progress: Double { ticksTotal == 0 ? 1 : 1 - Double(ticksLeft) / Double(ticksTotal) }
}
