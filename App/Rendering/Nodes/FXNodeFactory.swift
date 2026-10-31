// Purpose: Short-lived effects: tracer, muzzle flash, goo splat, dust puff, building shake, trap flash. Notes: docs/features/rendering-art.md
import SpriteKit

/// Effect art (fx_*) exists only top-down; both views use it (ArtRegistry.effectTexture). In isometric, ground
/// decals (goo) are squashed to half height so they lie on the ground. Every effect removes itself when done.
@MainActor
enum FXNodeFactory {
    // Look only (not game tuning): sizes in tiles and times in seconds.
    private static let tracerThickness: CGFloat = 3
    private static let tracerSeconds = 0.12
    private static let flashTiles: CGFloat = 0.45
    private static let flashSeconds = 0.08
    private static let gooTiles: CGFloat = 0.9
    private static let gooStaySeconds = 4.0
    private static let gooFadeSeconds = 1.5
    private static let dustSeconds = 0.8
    private static let shakeKey = "shake"
    private static let trapFlashKey = "trapFlash"

    /// A streak from `from` to `to` (the fx_tracer image stretched along the line), fading fast.
    static func tracer(from: CGPoint, to: CGPoint, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let dx = to.x - from.x, dy = to.y - from.y
        let length = max(1, (dx * dx + dy * dy).squareRoot())
        let node = SKSpriteNode(texture: art.effectTexture("fx_tracer", style: style),
                                size: CGSize(width: length, height: tracerThickness))
        node.anchorPoint = CGPoint(x: 0, y: 0.5)
        node.position = from
        node.zRotation = atan2(dy, dx)
        node.zPosition = ZLayer.effects
        node.run(.sequence([.fadeOut(withDuration: tracerSeconds), .removeFromParent()]))
        return node
    }

    /// A flash at a gun's muzzle, pointing along `angle` (the art faces right).
    static func muzzleFlash(at point: CGPoint, angle: CGFloat, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let side = style.geometry.tileWidth * flashTiles
        let node = SKSpriteNode(texture: art.effectTexture("fx_muzzle_flash", style: style),
                                size: CGSize(width: side, height: side))
        node.position = point
        node.zRotation = angle
        node.zPosition = ZLayer.effects + 1
        node.run(.sequence([.wait(forDuration: flashSeconds), .removeFromParent()]))
        return node
    }

    /// Goo where a zombie died: lies on the ground, stays a while, fades out.
    static func gooSplat(at point: CGPoint, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let width = style.geometry.tileWidth * gooTiles
        let height = style.kind == .isometric ? width / 2 : width
        let node = SKSpriteNode(texture: art.effectTexture("fx_goo_splat", style: style), size: CGSize(width: width, height: height))
        node.position = point
        node.zPosition = ZLayer.decal
        node.run(.sequence([.wait(forDuration: gooStaySeconds), .fadeOut(withDuration: gooFadeSeconds), .removeFromParent()]))
        return node
    }

    /// A puff of dust over a building that just fell.
    static func dustPuff(at point: CGPoint, width: CGFloat, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let node = SKSpriteNode(texture: art.effectTexture("fx_dust_puff", style: style), size: CGSize(width: width, height: width))
        node.position = point
        node.zPosition = ZLayer.effects
        node.setScale(0.6)
        node.run(.sequence([.group([.scale(to: 1.2, duration: dustSeconds), .fadeOut(withDuration: dustSeconds)]),
                            .removeFromParent()]))
        return node
    }

    /// A small shake and red tint on a building that is being hit (skipped while one is already playing).
    static func shake(_ building: SKNode) {
        guard building.action(forKey: shakeKey) == nil else { return }
        let step = 1.5, time = 0.04
        building.run(.sequence([.moveBy(x: step, y: 0, duration: time), .moveBy(x: -2 * step, y: 0, duration: time),
                                .moveBy(x: step, y: 0, duration: time)]), withKey: shakeKey)
        if let body = building.childNode(withName: SpriteName.body) as? SKSpriteNode {
            body.run(.sequence([.colorize(with: .systemRed, colorBlendFactor: 0.4, duration: time),
                                .colorize(withColorBlendFactor: 0, duration: 3 * time)]))
        }
    }

    /// A tiny flash on a trap that hurt a zombie (skipped while one is already showing).
    static func trapFlash(_ trap: SKNode) {
        guard let body = trap.childNode(withName: SpriteName.body) as? SKSpriteNode,
              body.action(forKey: trapFlashKey) == nil else { return }
        body.run(.sequence([.colorize(with: .white, colorBlendFactor: 0.7, duration: 0.05),
                            .colorize(withColorBlendFactor: 0, duration: 0.2)]), withKey: trapFlashKey)
    }
}
