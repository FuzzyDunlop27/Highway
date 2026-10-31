// Purpose: Codable shape for Content/presentation.json (views, tile sizes, art packs). Read by the App only. Notes: docs/features/rendering-art.md
import Foundation

/// How the App draws the map. Core never uses this; it is decoded here so content tests cover the file.
public struct PresentationContent: Codable, Sendable {
    public let schemaVersion: Int
    /// The view the game opens in (until the player picks another).
    public let defaultView: ProjectionKind
    /// Flip to top-down while placing or moving a building, then flip back.
    public let autoTopDownWhilePlacing: Bool
    /// Real seconds for the fade between views (half out, half in).
    public let switchFadeSeconds: Double
    /// Hex color drawn outside the map (e.g. the empty corners around the isometric diamond).
    public let outsideMapColor: String
    /// One entry per view, keyed by `ProjectionKind` raw value.
    public let views: [String: ViewDef]

    public func view(_ kind: ProjectionKind) -> ViewDef? { views[kind.rawValue] }
}

public enum ProjectionKind: String, Codable, CaseIterable, Sendable {
    case topDown
    case isometric
}

public struct ViewDef: Codable, Sendable {
    public let projection: ProjectionKind
    /// Screen points for one tile: top-down is a square; isometric is a 2:1 diamond (width × height).
    public let tileWidthPt: Double
    public let tileHeightPt: Double
    /// Folder (Xcode namespace) under `Assets.xcassets/Art/` holding this view's art, e.g. "Iso".
    public let artNamespace: String
    /// Facing images for units/zombies: 1 = one image rotated in code; 4 or 8 = `<id>_se`, `<id>_ne`, ...
    public let facings: Int
    /// Facing images for turret tops (watchtower gunner, MG).
    public let turretFacings: Int
    /// Closest zoom (camera scale) and the zoom the view opens at.
    public let minScale: Double
    public let startScale: Double
    /// Placeholder block height per building category, in tile heights (isometric only).
    public let placeholderHeightTiles: [String: Double]
    /// Optional per-image fixes, keyed by art id.
    public let assets: [String: AssetDef]
}

public struct AssetDef: Codable, Sendable {
    /// Ground point inside the image as [x, y] fractions from its top-left (isometric default: bottom middle).
    public let anchor: [Double]?
    /// Extra size multiplier when the art is drawn a bit too big or small.
    public let scale: Double?
    /// False if this image must not be mirrored to make the opposite facing (e.g. text or a one-sided detail).
    public let mirrorable: Bool?
}
