// Purpose: Draws one zombie: facing sprite (zombies.json sprite), walk bob, health bar when hurt, hit flash. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
enum ZombieNodeFactory {
    static func make(_ zombie: Zombie, def: ZombieDef?, style: ArtStyle, art: ArtRegistry) -> ZombieNode {
        let node = ZombieNode(seed: zombie.id)
        node.update(zombie, def: def, style: style, art: art)
        return node
    }
}

/// One zombie's nodes: root (position, draw order) → bobber (walk bob) → body (facing image), plus a health bar.
@MainActor
final class ZombieNode {
    let root = SKNode()
    private let bobber = SKNode()
    private var body: SKSpriteNode?
    private var frame: DirectionalSprite.Frame?
    private var healthBar: SKSpriteNode?

    // Look only (not game tuning): bob height/time, bar size, flash.
    private static let bobPoints: CGFloat = 1.5
    private static let bobSeconds = 0.22
    private static let barHeight: CGFloat = 3
    private static let flashKey = "hitFlash"
    static let category = "zombie"

    init(seed: Int) {
        root.addChild(bobber)
        // Each zombie starts its bob at a different moment so a crowd doesn't bounce in step.
        let up = SKAction.moveBy(x: 0, y: Self.bobPoints, duration: Self.bobSeconds)
        up.timingMode = .easeInEaseOut
        let bob = SKAction.sequence([up, up.reversed()])
        bobber.run(.sequence([.wait(forDuration: Double(seed % 7) * Self.bobSeconds / 7), .repeatForever(bob)]))
    }

    /// Where shots hit: the body's middle.
    var hitPoint: CGPoint {
        guard let body else { return root.position }
        return CGPoint(x: root.position.x, y: root.position.y + body.frame.midY)
    }

    /// Look-only: how far (tiles) a zombie may be drawn off its Core position, so packs don't stack on one spot.
    static let crowdSpreadTiles = 0.35

    /// A fixed offset per zombie in -spread/2...spread/2 (golden-ratio hash of the id; same every frame).
    private static func crowdOffset(_ id: ZombieID, salt: Double) -> Double {
        let f = (Double(id) * salt + salt).truncatingRemainder(dividingBy: 1)
        return (f - 0.5) * crowdSpreadTiles
    }

    func update(_ zombie: Zombie, def: ZombieDef?, style: ArtStyle, art: ArtRegistry) {
        let geometry = style.geometry
        // Core walks every zombie down the same path line; spread them a little so a horde reads as a crowd.
        let gx = zombie.x + Self.crowdOffset(zombie.id, salt: 0.618), gy = zombie.y + Self.crowdOffset(zombie.id, salt: 0.414)
        root.position = geometry.standingAnchor(gx: gx, gy: gy)
        root.zPosition = ZLayer.sorted(depth: geometry.depth(gx: gx, gy: gy))
        let baseId = def?.sprite ?? zombie.defId
        let angle = geometry.screenAngle(gx: zombie.x, gy: zombie.y, heading: zombie.heading)
        var next = DirectionalSprite.frame(baseId: baseId, screenAngle: angle, facings: style.view.facings,
                                           allowMirror: style.asset(baseId)?.mirrorable ?? true)
        if next.id != frame?.id || next.mirrored != frame?.mirrored {
            // A missing facing image falls back to the base image (then to a labeled placeholder).
            if next.id != baseId && !art.hasImage(next.id, style: style) {
                next = DirectionalSprite.Frame(id: baseId, mirrored: false, rotation: 0)
            }
            if next.id != frame?.id || next.mirrored != frame?.mirrored { setBody(next, style: style, art: art) }
        }
        body?.zRotation = next.rotation
        frame = next
        updateHealth(zombie, def: def)
    }

    /// Brief white flash when shot or hurt by a trap (skipped while one is already showing).
    func flash() {
        guard let body, body.action(forKey: Self.flashKey) == nil else { return }
        body.run(.sequence([.colorize(with: .white, colorBlendFactor: 0.85, duration: 0.03),
                            .colorize(withColorBlendFactor: 0, duration: 0.12)]), withKey: Self.flashKey)
    }

    private func setBody(_ frame: DirectionalSprite.Frame, style: ArtStyle, art: ArtRegistry) {
        body?.removeFromParent()
        let sprite = art.sprite(frame.id, width: 1, height: 1, category: Self.category, style: style)
        if frame.mirrored { sprite.xScale = -sprite.xScale }
        bobber.addChild(sprite)
        body = sprite
        healthBar?.position.y = sprite.frame.maxY + Self.barHeight
    }

    private func updateHealth(_ zombie: Zombie, def: ZombieDef?) {
        let maxHp = Double(def?.hp ?? 0)
        guard maxHp > 0, zombie.hp < maxHp else {
            healthBar?.isHidden = true
            return
        }
        if healthBar == nil, let body {
            let bar = BarNodeFactory.make(name: BarNodeFactory.healthName, width: abs(body.size.width) * 0.45,
                                          height: Self.barHeight, centerY: body.frame.maxY + Self.barHeight, color: .systemRed)
            root.addChild(bar)
            healthBar = bar
        }
        healthBar?.isHidden = false
        BarNodeFactory.set(healthBar, value: zombie.hp / maxHp)
    }
}
