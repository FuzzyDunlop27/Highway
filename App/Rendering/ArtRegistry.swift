// Purpose: Looks up menu/HUD pictures (UI kit PNGs) by id; draws a labeled placeholder when one is missing (never crashes). Notes: docs/features/rendering-art.md
import UIKit
import HoldoutCore

/// 2D pictures are only used by the SwiftUI menus and HUD now; the map is 3D (`ModelRegistry`, D-030).
@MainActor
final class ArtRegistry {
    static let shared = ArtRegistry()

    private var images: [String: UIImage] = [:]

    /// The image for `id` in a folder of `Assets.xcassets/Art/` ("UI" or "Menu"), if there is one.
    func image(_ id: String, namespace: String) -> UIImage? { UIImage(named: "\(namespace)/\(id)") }

    /// UIImage for SwiftUI (HUD icons): the UI kit folder, else a labeled placeholder.
    func uiImage(_ id: String) -> UIImage {
        if let cached = images[id] { return cached }
        let image = self.image(id, namespace: "UI") ?? PlaceholderArt.flatBox(id, size: CGSize(width: 64, height: 64))
        images[id] = image
        return image
    }

    /// Picture for a building in menus: the UI kit's 3/4 card `ui_build_<id>`, else the old isometric picture kept in
    /// `Art/Menu/`, else a placeholder. Only `wall_wood` borrows the kit's generic `ui_build_wall` (it is drawn as wood).
    func menuImage(for def: BuildingDef) -> UIImage {
        let key = "menu/\(def.id)"
        if let cached = images[key] { return cached }
        let kitAliases = ["wall_wood": "ui_build_wall"]
        let candidates = [("UI", "ui_build_\(def.id)"), ("UI", kitAliases[def.id] ?? ""), ("Menu", def.sprite)]
        let image = candidates.lazy.compactMap { self.image($0.1, namespace: $0.0) }.first
            ?? PlaceholderArt.flatBox(def.sprite, size: CGSize(width: 64, height: 64))
        images[key] = image
        return image
    }
}

/// Art categories that aren't building categories from buildings.json (placeholder heights in presentation.json).
enum ArtCategory {
    static let decoration = "decoration"
}

extension UIColor {
    /// "#RRGGBB" → UIColor (gray if the text isn't a valid color). Used for presentation.json colors.
    static func hex(_ hex: String) -> UIColor {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return .darkGray }
        return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                       blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }
}
