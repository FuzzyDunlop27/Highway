// Purpose: One placed building or defense on a base (position, level, build progress, staffing). Notes: docs/features/construction.md
import Foundation

public typealias BuildingID = Int

public struct Building: Codable, Equatable, Identifiable, Sendable {
    /// Unique within its base; never reused.
    public let id: BuildingID
    /// Which `BuildingDef` this is (e.g. "farm").
    public let defId: String
    public var level: Int
    /// Top-left tile of the footprint.
    public var origin: GridPoint
    /// Which way the front points; east/west turn the footprint (only for `rotatable` buildings).
    public var facing: Facing
    public var hp: Int
    /// Ticks left until construction finishes; 0 = finished and working.
    public var constructionTicksLeft: Int
    /// Ticks the current construction takes in total (for a progress bar).
    public var constructionTicksTotal: Int
    /// Food/scrap paid for this building so far (demolish refunds a share of it).
    public var invested: Cost
    /// Survivors working here right now (set every tick by the staffing rule).
    public var staffed: Int
    /// Destroyed in a horde (hp reached 0): does nothing and blocks nothing until rebuilt (`Command.repair`).
    public var isRubble: Bool
    /// How many civilians the player wants working here (nil = as many as it takes: the default for new buildings).
    public var assignedWorkers: Int?
    /// Scavenger Post: run rewards waiting to be collected (nil = none).
    public var heldReward: Cost?

    /// Finished, standing, and working. False while building/repairing and while rubble.
    public var isComplete: Bool { constructionTicksLeft == 0 && !isRubble }

    /// Construction progress from 0 to 1 (1 when finished).
    public var constructionProgress: Double {
        constructionTicksTotal == 0 ? 1 : 1 - Double(constructionTicksLeft) / Double(constructionTicksTotal)
    }

    public init(id: BuildingID, defId: String, level: Int, origin: GridPoint, hp: Int,
                constructionTicksLeft: Int, constructionTicksTotal: Int, invested: Cost, staffed: Int = 0,
                isRubble: Bool = false, assignedWorkers: Int? = nil, heldReward: Cost? = nil, facing: Facing = .south) {
        self.id = id
        self.defId = defId
        self.level = level
        self.origin = origin
        self.facing = facing
        self.hp = hp
        self.constructionTicksLeft = constructionTicksLeft
        self.constructionTicksTotal = constructionTicksTotal
        self.invested = invested
        self.staffed = staffed
        self.isRubble = isRubble
        self.assignedWorkers = assignedWorkers
        self.heldReward = heldReward
    }
}
