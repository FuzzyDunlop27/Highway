// Purpose: Draw order: flat ground first, then upright things sorted front-to-back, then overlays and the ghost. Notes: docs/features/rendering-art.md
import CoreGraphics

enum ZLayer {
    /// Ground tiles (and later flat traps and goo).
    static let ground: CGFloat = 0
    /// Buildings, decorations, and later units/zombies: `sorted(depth:)`.
    static let sortedBase: CGFloat = 100
    /// Selection outline, drawn over buildings so it stays visible.
    static let selection: CGFloat = 5_000
    static let ghost: CGFloat = 6_000

    /// Child offsets inside a sorted node (turret top, progress bar). Smaller than the gap between sorted items.
    static let turretOffset: CGFloat = 1
    static let overlayOffset: CGFloat = 2

    /// zPosition for an upright thing with draw-order key `depth` (GridGeometry.depth): bigger depth = in front.
    static func sorted(depth: Double) -> CGFloat { sortedBase + CGFloat(depth) * 10 }
}
