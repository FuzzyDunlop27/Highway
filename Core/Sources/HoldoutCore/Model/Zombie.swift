// Purpose: One zombie on the map: type, position, health, and what it is bashing. Notes: docs/features/hordes.md
import Foundation

public typealias ZombieID = Int

public struct Zombie: Codable, Equatable, Identifiable, Sendable {
    /// Unique within its base; never reused (HordeState.nextZombieID).
    public let id: ZombieID
    /// Which `ZombieDef` this is ("walker", "runner", "brute").
    public let defId: String
    /// Position in tiles: x right, y down, (0,0) = the map's top-left corner, so a tile's middle is (tx + 0.5, ty + 0.5).
    public var x: Double
    public var y: Double
    public var hp: Double
    /// Facing in grid space, radians: 0 = +x (east), π/2 = +y (south). For drawing only.
    public var heading: Double
    /// The building it is hitting right now, or nil while walking.
    public var attacking: BuildingID?

    public init(id: ZombieID, defId: String, x: Double, y: Double, hp: Double, heading: Double = 0, attacking: BuildingID? = nil) {
        self.id = id
        self.defId = defId
        self.x = x
        self.y = y
        self.hp = hp
        self.heading = heading
        self.attacking = attacking
    }

    /// The tile it stands on.
    public var tile: GridPoint { GridPoint(x: Int(x.rounded(.down)), y: Int(y.rounded(.down))) }
}
