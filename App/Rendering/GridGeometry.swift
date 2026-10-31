// Purpose: CoreGraphics wrapper around Core's GridProjection: tiles ↔ scene points for the active view. Notes: docs/features/rendering-art.md
import CoreGraphics
import HoldoutCore

struct GridGeometry {
    let projection: GridProjection

    init(map: MapDef, view: ViewDef) {
        projection = GridProjection(kind: view.projection, tileWidth: view.tileWidthPt, tileHeight: view.tileHeightPt,
                                    mapWidth: map.width, mapHeight: map.height)
    }

    var kind: ProjectionKind { projection.kind }
    var tileWidth: CGFloat { CGFloat(projection.tileWidth) }
    var tileHeight: CGFloat { CGFloat(projection.tileHeight) }
    var mapSize: CGSize { CGSize(width: projection.mapSize.x, height: projection.mapSize.y) }

    /// Scene point of a (possibly fractional) grid position.
    func point(gx: Double, gy: Double) -> CGPoint { Self.cg(projection.screen(gx: gx, gy: gy)) }

    /// Grid position (fractional) under a scene point.
    func grid(at point: CGPoint) -> (x: Double, y: Double) {
        let g = projection.grid(sx: point.x, sy: point.y)
        return (g.x, g.y)
    }

    func tile(at point: CGPoint) -> GridPoint { projection.tile(sx: point.x, sy: point.y) }

    func center(origin: GridPoint, width w: Int, height h: Int) -> CGPoint {
        Self.cg(projection.center(origin: origin, width: w, height: h))
    }

    /// Where a sprite's anchor goes: footprint middle (top-down) or front corner (isometric).
    func groundAnchor(origin: GridPoint, width w: Int, height h: Int) -> CGPoint {
        Self.cg(projection.groundAnchor(origin: origin, width: w, height: h))
    }

    /// Footprint outline as a closed path in scene coordinates.
    func outlinePath(origin: GridPoint, width w: Int, height h: Int) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: projection.outline(origin: origin, width: w, height: h).map(Self.cg))
        path.closeSubpath()
        return path
    }

    /// Draw-order key for a footprint (its middle); bigger = in front.
    func depth(origin: GridPoint, width w: Int, height h: Int) -> Double {
        projection.depth(gx: Double(origin.x) + Double(w) / 2, gy: Double(origin.y) + Double(h) / 2)
    }

    /// On-screen width of a footprint (rectangle width top-down, diamond width isometric).
    func footprintWidth(width w: Int, height h: Int) -> CGFloat { CGFloat(projection.footprintWidth(width: w, height: h)) }

    /// Rectangle size of a footprint in top-down; the diamond's bounding box in isometric.
    func footprintBox(width w: Int, height h: Int) -> CGSize {
        switch kind {
        case .topDown: CGSize(width: CGFloat(w) * tileWidth, height: CGFloat(h) * tileHeight)
        case .isometric: CGSize(width: footprintWidth(width: w, height: h), height: CGFloat(w + h) * tileHeight / 2)
        }
    }

    private static func cg(_ p: GridProjection.Point) -> CGPoint { CGPoint(x: p.x, y: p.y) }
}
