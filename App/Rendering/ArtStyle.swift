// Purpose: The active view (isometric or top-down): its geometry, art folder, placeholder heights, per-image fixes. Notes: docs/features/rendering-art.md
import UIKit
import HoldoutCore

struct ArtStyle {
    let kind: ProjectionKind
    let view: ViewDef
    let geometry: GridGeometry

    /// Nil if presentation.json has no entry for `kind` (content validation prevents that).
    init?(kind: ProjectionKind, content: GameContent, map: MapDef) {
        guard let view = content.presentation.view(kind) else { return nil }
        self.kind = kind
        self.view = view
        geometry = GridGeometry(map: map, view: view)
    }

    /// Asset-catalog folder for this view's art, e.g. "Iso" → image "Iso/bld_farm".
    var namespace: String { view.artNamespace }

    /// Placeholder block height in points for a building category (0 in top-down and for ground tiles).
    func blockHeight(category: String) -> CGFloat {
        guard kind == .isometric, category != ArtCategory.tile else { return 0 }
        let tiles = view.placeholderHeightTiles[category] ?? view.placeholderHeightTiles["default"] ?? 1
        return CGFloat(tiles) * geometry.tileHeight
    }

    func asset(_ id: String) -> AssetDef? { view.assets[id] }

    /// "#RRGGBB" → UIColor (gray if the text isn't a valid color).
    static func color(hex: String) -> UIColor {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return .darkGray }
        return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                       blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }
}

/// Categories that aren't building categories from buildings.json.
enum ArtCategory {
    static let tile = "tile"
    static let decoration = "decoration"
}
