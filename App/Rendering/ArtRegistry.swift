// Purpose: Looks up art by id for the active view; draws a labeled placeholder when an image is missing (never crashes). Notes: docs/features/rendering-art.md
import SpriteKit
import UIKit
import HoldoutCore

@MainActor
final class ArtRegistry {
    static let shared = ArtRegistry()

    private var textures: [String: SKTexture] = [:]
    private var images: [String: UIImage] = [:]
    private var exists: [String: Bool] = [:]

    /// The real image for `id` in a view's folder (`Assets.xcassets/Art/<namespace>/`), if there is one.
    func image(_ id: String, namespace: String) -> UIImage? { UIImage(named: "\(namespace)/\(id)") }

    /// Remembered per image, because zombies ask about their facing images every frame.
    func hasImage(_ id: String, style: ArtStyle) -> Bool {
        let key = "\(style.namespace)/\(id)"
        if let known = exists[key] { return known }
        let found = image(id, namespace: style.namespace) != nil
        exists[key] = found
        return found
    }

    /// Cached real texture for animation; missing frames leave the still sprite intact.
    func texture(_ id: String, style: ArtStyle) -> SKTexture? {
        let key = "\(style.namespace)/\(id)"
        if let texture = textures[key] { return texture }
        guard let image = image(id, namespace: style.namespace) else { return nil }
        return cachedTexture(key) { SKTexture(image: image) }
    }

    /// A sprite showing `id` on a `w`×`h` footprint, sized and anchored so its `position` goes at
    /// `style.geometry.groundAnchor(...)`. Real art if present, otherwise a labeled placeholder.
    /// `category` picks the placeholder block height (buildings.json category, `ArtCategory.tile`, ...).
    func sprite(_ id: String, width w: Int, height h: Int, category: String, style: ArtStyle) -> SKSpriteNode {
        let geometry = style.geometry
        let fix = style.asset(id)
        let node: SKSpriteNode
        if let image = image(id, namespace: style.namespace) {
            let texture = cachedTexture("\(style.namespace)/\(id)") { SKTexture(image: image) }
            switch style.kind {
            case .topDown:
                node = SKSpriteNode(texture: texture, size: geometry.footprintBox(width: w, height: h))
                node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            case .isometric:
                // Iso art is drawn as wide as its footprint diamond, any height (docs/graphics-spec-iso.md).
                let width = geometry.footprintWidth(width: w, height: h)
                let aspect = image.size.width > 0 ? image.size.height / image.size.width : 1
                node = SKSpriteNode(texture: texture, size: CGSize(width: width, height: width * aspect))
                let anchor = fix?.anchor ?? [0.5, 1.0]
                node.anchorPoint = CGPoint(x: anchor[0], y: 1 - anchor[1])
            }
        } else {
            switch style.kind {
            case .topDown:
                let size = geometry.footprintBox(width: w, height: h)
                let texture = cachedTexture("\(style.namespace)/\(id)#placeholder") {
                    SKTexture(image: PlaceholderArt.flatBox(id, size: Self.placeholderSize(aspect: size)))
                }
                node = SKSpriteNode(texture: texture, size: size)
                node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            case .isometric:
                let height = style.blockHeight(category: category)
                let texture = cachedTexture("\(style.namespace)/\(id)#\(w)x\(h)@\(Int(height))") {
                    // Ground tiles stay unlabeled (1,200 labels are unreadable noise); their color says what they are.
                    SKTexture(image: PlaceholderArt.isoBlock(id, footprintW: w, footprintH: h, tileW: geometry.tileWidth,
                                                             tileH: geometry.tileHeight, height: height,
                                                             labeled: category != ArtCategory.tile))
                }
                node = SKSpriteNode(texture: texture)
                node.anchorPoint = CGPoint(x: 0.5, y: 0)
            }
        }
        if let scale = fix?.scale { node.setScale(scale) }
        node.name = SpriteName.body
        return node
    }

    /// Effect art (`fx_*`) exists only top-down, so it is shared by both views: this view's image, else the TopDown one,
    /// else a labeled placeholder. Callers size the sprite themselves.
    func effectTexture(_ id: String, style: ArtStyle) -> SKTexture {
        for namespace in [style.namespace, "TopDown"] {
            if let image = image(id, namespace: namespace) {
                return cachedTexture("\(namespace)/\(id)") { SKTexture(image: image) }
            }
        }
        return cachedTexture("fx/\(id)#placeholder") {
            SKTexture(image: PlaceholderArt.flatBox(id, size: CGSize(width: 64, height: 64)))
        }
    }

    /// UIImage for SwiftUI (HUD icons, build menu): UI folder, then top-down, then isometric art, else a placeholder.
    func uiImage(_ id: String) -> UIImage {
        if let cached = images[id] { return cached }
        let found = ["UI", "TopDown", "Iso"].lazy.compactMap { self.image(id, namespace: $0) }.first
        let image = found ?? PlaceholderArt.flatBox(id, size: CGSize(width: 64, height: 64))
        images[id] = image
        return image
    }

    /// Picture for a building in menus: the UI kit's 3/4 card `ui_build_<id>`, else the isometric sprite, else top-down
    /// art, else a placeholder. Only `wall_wood` borrows the kit's generic `ui_build_wall` (it is drawn as wood).
    func menuImage(for def: BuildingDef) -> UIImage {
        let key = "menu/\(def.id)"
        if let cached = images[key] { return cached }
        let kitAliases = ["wall_wood": "ui_build_wall"]
        let candidates = [("UI", "ui_build_\(def.id)"), ("UI", kitAliases[def.id] ?? ""), ("Iso", def.sprite), ("TopDown", def.sprite)]
        let image = candidates.lazy.compactMap { self.image($0.1, namespace: $0.0) }.first
            ?? PlaceholderArt.flatBox(def.sprite, size: CGSize(width: 64, height: 64))
        images[key] = image
        return image
    }

    private func cachedTexture(_ key: String, make: () -> SKTexture) -> SKTexture {
        if let cached = textures[key] { return cached }
        let texture = make()
        texture.filteringMode = .linear
        textures[key] = texture
        return texture
    }

    /// Top-down placeholders are drawn 128 pt on their longest side, so labels stay readable when zoomed.
    private static func placeholderSize(aspect: CGSize) -> CGSize {
        let scale = 128 / max(aspect.width, aspect.height, 1)
        return CGSize(width: max(aspect.width * scale, 32), height: max(aspect.height * scale, 32))
    }
}

/// Child node names the scene looks up.
enum SpriteName {
    static let body = "body"
    static let building = "building"
}
