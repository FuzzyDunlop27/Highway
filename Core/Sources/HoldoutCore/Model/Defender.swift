// Purpose: One trained defender and where it is posted (HQ, garrisoned in a tower, holding a spot, or knocked out). Notes: docs/features/jobs-defenders.md
import Foundation

public typealias DefenderID = Int

public struct Defender: Codable, Equatable, Identifiable, Sendable {
    public enum Post: Codable, Equatable, Sendable {
        /// Waiting at the HQ: does nothing.
        case hq
        /// Inside a tower: counts as its worker and boosts its damage.
        case garrison(buildingId: BuildingID)
        /// Standing on a tile, shooting zombies in range.
        case hold(at: GridPoint)
        /// At 0 hp: out for a while, then back at the HQ with full hp. A defender never dies.
        case knockedOut(ticksLeft: Int)
    }

    /// Unique within its base; never reused.
    public let id: DefenderID
    public var hp: Int
    public var post: Post

    public init(id: DefenderID, hp: Int, post: Post = .hq) {
        self.id = id
        self.hp = hp
        self.post = post
    }

    public var isKnockedOut: Bool { if case .knockedOut = post { true } else { false } }

    /// The tower this defender is garrisoned in, if any.
    public var garrisonedIn: BuildingID? { if case .garrison(let id) = post { id } else { nil } }
}

/// One defender being trained at the Barracks. Only the first in `Base.training` makes progress.
/// Cost and the survivor are taken when it is queued.
public struct TrainingJob: Codable, Equatable, Sendable {
    public var ticksLeft: Int
    public let ticksTotal: Int
    /// What was paid, so cancelling can refund.
    public let paid: Cost

    public init(ticksLeft: Int, ticksTotal: Int, paid: Cost) {
        self.ticksLeft = ticksLeft
        self.ticksTotal = ticksTotal
        self.paid = paid
    }

    public var progress: Double { ticksTotal == 0 ? 1 : 1 - Double(ticksLeft) / Double(ticksTotal) }
}
