// Purpose: Picks which facing image (e, ne, n, ... se) a turning thing uses for a screen direction. Notes: docs/features/rendering-art.md
import Foundation

/// Pure facing math for the App's DirectionalSprite (kept in Core so it can be unit-tested; the simulation never uses it).
public enum Facing {
    /// Screen-direction suffixes counter-clockwise from east (screen y is up).
    public static let names = ["e", "ne", "n", "nw", "w", "sw", "s", "se"]

    /// Suffix for `screenAngle` (radians, 0 = right, π/2 = up). `facings` 8 = nearest of all eight;
    /// 4 = nearest diagonal (ne, nw, sw, se), ties go counter-clockwise.
    public static func name(screenAngle: Double, facings: Int) -> String {
        let step = Double.pi / 4
        let angle = normalized(screenAngle)
        let nearest = Int((angle / step).rounded())  // 0...8; 8 is east again after a full turn
        var index = nearest
        if facings == 4 && nearest % 2 == 0 {
            // Measure the side before wrapping, so 355° (just below east) snaps to se, not ne.
            index = nearest + (angle - Double(nearest) * step >= 0 ? 1 : -1)
        }
        return names[(index % 8 + 8) % 8]
    }

    static func normalized(_ angle: Double) -> Double {
        let full = 2 * Double.pi
        let a = angle.truncatingRemainder(dividingBy: full)
        return a < 0 ? a + full : a
    }
}
