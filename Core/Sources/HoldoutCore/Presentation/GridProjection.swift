// Purpose: Pure math from map tiles to screen points for each view (top-down, isometric) and back. Notes: docs/features/rendering-art.md
import Foundation

/// Maps grid positions (x right, y down, in tiles; may be fractional) to screen points (y up) and back.
/// Lives in Core only so it can be unit-tested anywhere; the simulation never uses it (DECISIONS D-016).
public struct GridProjection: Equatable, Sendable {
    public let kind: ProjectionKind
    public let tileWidth: Double
    public let tileHeight: Double
    public let mapWidth: Int
    public let mapHeight: Int

    public init(kind: ProjectionKind, tileWidth: Double, tileHeight: Double, mapWidth: Int, mapHeight: Int) {
        self.kind = kind
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.mapWidth = mapWidth
        self.mapHeight = mapHeight
    }

    public struct Point: Equatable, Sendable {
        public var x: Double
        public var y: Double
        public init(x: Double, y: Double) { self.x = x; self.y = y }
    }

    /// Size of the box that holds the whole map on screen; every projected point lies inside (0,0)...(size).
    public var mapSize: Point {
        switch kind {
        case .topDown:
            Point(x: Double(mapWidth) * tileWidth, y: Double(mapHeight) * tileHeight)
        case .isometric:
            Point(x: Double(mapWidth + mapHeight) * tileWidth / 2, y: Double(mapWidth + mapHeight) * tileHeight / 2)
        }
    }

    /// Screen point of grid position (gx, gy). (0,0) is the map's top-left corner, (W,H) its bottom-right corner.
    public func screen(gx: Double, gy: Double) -> Point {
        switch kind {
        case .topDown:
            return Point(x: gx * tileWidth, y: (Double(mapHeight) - gy) * tileHeight)
        case .isometric:
            // Map's north-west corner is the diamond's top point; south-east corner is its bottom point.
            return Point(x: (gx - gy + Double(mapHeight)) * tileWidth / 2,
                         y: (Double(mapWidth + mapHeight) - gx - gy) * tileHeight / 2)
        }
    }

    /// Grid position under a screen point (inverse of `screen`).
    public func grid(sx: Double, sy: Double) -> Point {
        switch kind {
        case .topDown:
            return Point(x: sx / tileWidth, y: Double(mapHeight) - sy / tileHeight)
        case .isometric:
            let a = sx / (tileWidth / 2) - Double(mapHeight)              // gx - gy
            let b = Double(mapWidth + mapHeight) - sy / (tileHeight / 2)  // gx + gy
            return Point(x: (a + b) / 2, y: (b - a) / 2)
        }
    }

    /// The tile under a screen point (may be off the map; callers check).
    public func tile(sx: Double, sy: Double) -> GridPoint {
        let g = grid(sx: sx, sy: sy)
        return GridPoint(x: Int(g.x.rounded(.down)), y: Int(g.y.rounded(.down)))
    }

    /// Footprint outline on screen, clockwise from its top-left grid corner (a rectangle top-down, a diamond isometric).
    public func outline(origin: GridPoint, width w: Int, height h: Int) -> [Point] {
        let x0 = Double(origin.x), y0 = Double(origin.y), x1 = x0 + Double(w), y1 = y0 + Double(h)
        return [screen(gx: x0, gy: y0), screen(gx: x1, gy: y0), screen(gx: x1, gy: y1), screen(gx: x0, gy: y1)]
    }

    /// Middle of a footprint on screen.
    public func center(origin: GridPoint, width w: Int, height h: Int) -> Point {
        screen(gx: Double(origin.x) + Double(w) / 2, gy: Double(origin.y) + Double(h) / 2)
    }

    /// Where a sprite stands: the footprint's middle (top-down) or its front (bottom) corner (isometric).
    public func groundAnchor(origin: GridPoint, width w: Int, height h: Int) -> Point {
        switch kind {
        case .topDown: center(origin: origin, width: w, height: h)
        case .isometric: screen(gx: Double(origin.x + w), gy: Double(origin.y + h))
        }
    }

    /// Bigger = closer to the viewer (drawn in front). Use the middle of a footprint or a unit's position.
    public func depth(gx: Double, gy: Double) -> Double {
        switch kind {
        case .topDown: gy
        case .isometric: gx + gy
        }
    }

    /// Width in points of a `w`×`h` footprint on screen (the diamond's width in isometric).
    public func footprintWidth(width w: Int, height h: Int) -> Double {
        switch kind {
        case .topDown: Double(w) * tileWidth
        case .isometric: Double(w + h) * tileWidth / 2
        }
    }
}
