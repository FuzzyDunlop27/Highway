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
    public var hp: Int
    /// Ticks left until construction finishes; 0 = finished and working.
    public var constructionTicksLeft: Int
    /// Ticks the current construction takes in total (for a progress bar).
    public var constructionTicksTotal: Int
    /// Food/scrap paid for this building so far (demolish refunds a share of it).
    public var invested: Cost
    /// Survivors working here right now (set every tick by the staffing rule).
    public var staffed: Int

    public var isComplete: Bool { constructionTicksLeft == 0 }

    /// Construction progress from 0 to 1 (1 when finished).
    public var constructionProgress: Double {
        constructionTicksTotal == 0 ? 1 : 1 - Double(constructionTicksLeft) / Double(constructionTicksTotal)
    }

    public init(id: BuildingID, defId: String, level: Int, origin: GridPoint, hp: Int,
                constructionTicksLeft: Int, constructionTicksTotal: Int, invested: Cost, staffed: Int = 0) {
        self.id = id
        self.defId = defId
        self.level = level
        self.origin = origin
        self.hp = hp
        self.constructionTicksLeft = constructionTicksLeft
        self.constructionTicksTotal = constructionTicksTotal
        self.invested = invested
        self.staffed = staffed
    }
}
