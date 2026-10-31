// Purpose: A tile position on the map grid (x right, y down, origin top-left). Notes: docs/features/construction.md
import Foundation

public struct GridPoint: Codable, Hashable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    /// Every tile covered by a `width`×`height` footprint whose top-left tile is `self`.
    public func footprintTiles(width: Int, height: Int) -> [GridPoint] {
        (0..<height).flatMap { dy in (0..<width).map { dx in GridPoint(x: x + dx, y: y + dy) } }
    }
}
