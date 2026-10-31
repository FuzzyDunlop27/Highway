// Purpose: Picks the facing image for things that turn (turrets now; units/zombies in 1B), or rotates one image. Notes: docs/features/rendering-art.md
import CoreGraphics
import Foundation
import HoldoutCore

enum DirectionalSprite {
    struct Frame: Equatable {
        /// Art id to draw, e.g. "zmb_walker_se" (or the base id when `facings` is 1).
        let id: String
        /// Draw flipped left-right (west-facing frames reuse the east-facing image).
        let mirrored: Bool
        /// zRotation to apply (only when one image is rotated in code).
        let rotation: CGFloat
    }

    /// West-side facings are mirrors of these east-side ones.
    static let mirrorOf = ["w": "e", "nw": "ne", "sw": "se"]

    /// `screenAngle`: direction on screen in radians (0 = right, π/2 = up), e.g. from GridGeometry points.
    /// `facings`: 1 = rotate `baseId`; 4 = diagonals only (ne, nw, sw, se); 8 = all eight.
    static func frame(baseId: String, screenAngle: Double, facings: Int, allowMirror: Bool = true) -> Frame {
        guard facings == 4 || facings == 8 else { return Frame(id: baseId, mirrored: false, rotation: CGFloat(screenAngle)) }
        let name = Facing.name(screenAngle: screenAngle, facings: facings)  // Core/Presentation/Facing.swift (tested)
        if allowMirror, let east = mirrorOf[name] { return Frame(id: "\(baseId)_\(east)", mirrored: true, rotation: 0) }
        return Frame(id: "\(baseId)_\(name)", mirrored: false, rotation: 0)
    }
}
