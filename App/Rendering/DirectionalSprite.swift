// Purpose: Picks the facing image for things that turn (turrets now; units/zombies in 1B), or rotates one image. Notes: docs/features/rendering-art.md
import CoreGraphics
import Foundation

enum DirectionalSprite {
    struct Frame: Equatable {
        /// Art id to draw, e.g. "zmb_walker_se" (or the base id when `facings` is 1).
        let id: String
        /// Draw flipped left-right (west-facing frames reuse the east-facing image).
        let mirrored: Bool
        /// zRotation to apply (only when one image is rotated in code).
        let rotation: CGFloat
    }

    /// Screen-direction suffixes counter-clockwise from east (screen y is up).
    static let names = ["e", "ne", "n", "nw", "w", "sw", "s", "se"]
    /// West-side facings are mirrors of these east-side ones.
    static let mirrorOf = ["w": "e", "nw": "ne", "sw": "se"]

    /// `screenAngle`: direction on screen in radians (0 = right, π/2 = up), e.g. from GridGeometry points.
    /// `facings`: 1 = rotate `baseId`; 4 = diagonals only (ne, nw, sw, se); 8 = all eight.
    static func frame(baseId: String, screenAngle: Double, facings: Int, allowMirror: Bool = true) -> Frame {
        guard facings == 4 || facings == 8 else { return Frame(id: baseId, mirrored: false, rotation: CGFloat(screenAngle)) }
        let step = Double.pi / 4
        var index = Int((normalized(screenAngle) / step).rounded()) % 8
        if facings == 4 && index % 2 == 0 {
            // Snap to the nearest diagonal, favoring the one counter-clockwise.
            let diff = normalized(screenAngle) - Double(index) * step
            index = (index + (diff >= 0 ? 1 : 7)) % 8
        }
        let name = names[index]
        if allowMirror, let east = mirrorOf[name] { return Frame(id: "\(baseId)_\(east)", mirrored: true, rotation: 0) }
        return Frame(id: "\(baseId)_\(name)", mirrored: false, rotation: 0)
    }

    private static func normalized(_ angle: Double) -> Double {
        let full = 2 * Double.pi
        let a = angle.truncatingRemainder(dividingBy: full)
        return a < 0 ? a + full : a
    }
}
