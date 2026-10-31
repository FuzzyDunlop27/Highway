// Purpose: Draws finished defenses: walls turned to their line, flat traps, towers with a turret top that aims. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
enum DefenseNodeFactory {
    /// buildings.json categories this factory draws.
    enum Category {
        static let wall = "wall"
        static let tower = "tower"
        static let trap = "trap"
    }

    static let turretName = "turret"
    /// Unstaffed towers show their turret faded (nobody is manning it).
    private static let unstaffedAlpha: CGFloat = 0.35
    private static let frameKey = "frame"

    static func isDefense(_ def: BuildingDef) -> Bool {
        [Category.wall, Category.tower, Category.trap].contains(def.category)
    }

    /// Tiles covered by standing walls (any state but rubble), for picking each wall's direction.
    static func wallTiles(_ buildings: [Building], content: GameContent) -> Set<GridPoint> {
        Set(buildings.compactMap { b in
            guard !b.isRubble, content.buildingDef(b.defId)?.category == Category.wall else { return nil }
            return b.origin
        })
    }

    /// A small number that changes when a defense must be redrawn: walls 1 = runs along y (north-south line),
    /// towers 1 = staffed. Goes into `BuildingNodeFactory.Signature`.
    static func variant(_ b: Building, def: BuildingDef, wallTiles: Set<GridPoint>) -> Int {
        switch def.category {
        case Category.wall:
            let p = b.origin
            let alongX = [GridPoint(x: p.x - 1, y: p.y), GridPoint(x: p.x + 1, y: p.y)].filter(wallTiles.contains).count
            let alongY = [GridPoint(x: p.x, y: p.y - 1), GridPoint(x: p.x, y: p.y + 1)].filter(wallTiles.contains).count
            return alongY > alongX ? 1 : 0
        case Category.tower:
            return b.staffed > 0 ? 1 : 0
        default:
            return 0
        }
    }

    /// Adds a finished defense's picture(s) to `root` (already positioned) and returns the body sprite.
    /// `aim`: the turret's last screen angle (nil = idle facing).
    static func addParts(to root: SKNode, def: BuildingDef, variant: Int, aim: Double?,
                         style: ArtStyle, art: ArtRegistry) -> SKSpriteNode {
        let body = art.sprite(def.sprite, width: def.width, height: def.height, category: def.category, style: style)
        root.addChild(body)
        switch def.category {
        case Category.wall:
            // Iso wall art is drawn for a line along x; the same image mirrored is the line along y.
            if style.kind == .isometric && variant == 1 && (style.asset(def.sprite)?.mirrorable ?? true) {
                body.xScale = -body.xScale
            }
        case Category.trap:
            root.zPosition = ZLayer.trap   // flat on the ground: zombies walk over it
        default:
            if let turret = def.turretSprite {
                aimTurret(root, turretId: turret, def: def, screenAngle: aim ?? idleAngle(style), style: style, art: art)
                root.childNode(withName: turretName)?.alpha = variant == 1 ? 1 : unstaffedAlpha
            }
        }
        return body
    }

    /// Idle facing: right top-down (where the art faces), toward the lower right in isometric.
    static func idleAngle(_ style: ArtStyle) -> Double { style.kind == .topDown ? 0 : -Double.pi / 4 }

    /// Points the turret top at `screenAngle` (0 = right, π/2 = up). Top-down rotates the one image; isometric swaps
    /// to the facing image (`_e`, `_se`, … mirrored for the west side) only when the facing changes. In isometric
    /// with no image for that facing, no turret is drawn (the tower body stands alone).
    static func aimTurret(_ root: SKNode, turretId: String, def: BuildingDef, screenAngle: Double,
                          style: ArtStyle, art: ArtRegistry) {
        let frame = DirectionalSprite.frame(baseId: turretId, screenAngle: screenAngle, facings: style.view.turretFacings,
                                            allowMirror: style.asset(turretId)?.mirrorable ?? true)
        let key = "\(frame.id)|\(frame.mirrored)"
        let existing = root.childNode(withName: turretName)
        if let existing, existing.userData?[frameKey] as? String == key {
            existing.zRotation = frame.rotation
            return
        }
        let alpha = existing?.alpha ?? 1
        existing?.removeFromParent()
        if style.kind == .isometric && !art.hasImage(frame.id, style: style) { return }
        let top = art.sprite(frame.id, width: def.width, height: def.height, category: def.category, style: style)
        top.name = turretName
        top.userData = [frameKey: key]
        top.zRotation = frame.rotation
        if frame.mirrored { top.xScale = -top.xScale }
        top.zPosition = ZLayer.turretOffset
        top.alpha = alpha
        root.addChild(top)
    }

    /// Where shots leave a tower (or the HQ): its middle top-down, near the top of the drawing in isometric.
    static func muzzlePoint(_ root: SKNode, style: ArtStyle) -> CGPoint {
        guard style.kind == .isometric, let body = root.childNode(withName: SpriteName.body) else { return root.position }
        return CGPoint(x: root.position.x, y: root.position.y + body.frame.maxY * 0.8)
    }
}
