// Purpose: Pure math from map tiles to 3D world metres (and back) for the RealityKit view. Notes: docs/features/rendering-art.md
import Foundation

/// Maps grid positions (x right/east, y down/south, in tiles; may be fractional) to 3D world points in metres:
/// +X = east, +Y = up, +Z = south (RealityKit's −Z is north, matching the Blender export rule found in 1R).
/// The map's middle sits at the world origin. Lives in Core so it can be unit-tested; the simulation never uses it (D-016).
public struct WorldMapping3D: Equatable, Sendable {
    public let metresPerTile: Double
    public let mapWidth: Int
    public let mapHeight: Int

    public init(metresPerTile: Double, mapWidth: Int, mapHeight: Int) {
        self.metresPerTile = metresPerTile
        self.mapWidth = mapWidth
        self.mapHeight = mapHeight
    }

    public struct Point3: Equatable, Sendable {
        public var x: Double
        public var y: Double
        public var z: Double
        public init(x: Double, y: Double, z: Double) { self.x = x; self.y = y; self.z = z }
    }

    /// World point of grid position (gx, gy) at `height` metres above the ground.
    public func world(gx: Double, gy: Double, height: Double = 0) -> Point3 {
        Point3(x: (gx - Double(mapWidth) / 2) * metresPerTile, y: height, z: (gy - Double(mapHeight) / 2) * metresPerTile)
    }

    /// Grid position under a ground point (inverse of `world`, ignoring height).
    public func grid(x: Double, z: Double) -> (gx: Double, gy: Double) {
        (x / metresPerTile + Double(mapWidth) / 2, z / metresPerTile + Double(mapHeight) / 2)
    }

    /// The tile under a ground point (may be off the map; callers check).
    public func tile(x: Double, z: Double) -> GridPoint {
        let g = grid(x: x, z: z)
        return GridPoint(x: Int(g.gx.rounded(.down)), y: Int(g.gy.rounded(.down)))
    }

    /// Ground middle of a `w`×`h` footprint: where a model's origin goes (2M export rule: origin at the footprint's ground centre).
    public func footprintCenter(origin: GridPoint, width w: Int, height h: Int) -> Point3 {
        world(gx: Double(origin.x) + Double(w) / 2, gy: Double(origin.y) + Double(h) / 2)
    }

    /// A footprint's size on the ground in metres (x = east-west, z = north-south).
    public func footprintSize(width w: Int, height h: Int) -> (x: Double, z: Double) {
        (Double(w) * metresPerTile, Double(h) * metresPerTile)
    }

    /// The map's ground rectangle: x from −halfX to +halfX, z from −halfZ to +halfZ.
    public var halfExtent: (x: Double, z: Double) {
        (Double(mapWidth) * metresPerTile / 2, Double(mapHeight) * metresPerTile / 2)
    }

    /// Turn about +Y (radians, counter-clockwise seen from above, RealityKit's convention) that points a model whose
    /// front faces +X (east) along a grid heading (0 = east, π/2 = south). Heading south (+Z) needs −90°.
    public static func yaw(heading: Double) -> Double { -heading }
}
