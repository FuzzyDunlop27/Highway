// Purpose: Draws one placed building or defense for the active view: sprite (or scaffolding while building), turret top, progress bar. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
enum BuildingNodeFactory {
    /// What a building node depends on; when it changes the scene rebuilds the node.
    struct Signature: Equatable {
        let defId: String
        let level: Int
        let origin: GridPoint
        let isComplete: Bool

        init(_ b: Building) {
            defId = b.defId
            level = b.level
            origin = b.origin
            isComplete = b.isComplete
        }
    }

    private static let progressName = "progress"

    static func make(_ building: Building, content: GameContent, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let root = SKNode()
        root.name = SpriteName.building
        guard let def = content.buildingDef(building.defId) else { return root }
        let geometry = style.geometry
        root.position = geometry.groundAnchor(origin: building.origin, width: def.width, height: def.height)
        root.zPosition = ZLayer.sorted(depth: geometry.depth(origin: building.origin, width: def.width, height: def.height))

        let body: SKSpriteNode
        if building.isComplete {
            body = art.sprite(def.sprite, width: def.width, height: def.height, category: def.category, style: style)
            root.addChild(body)
            if let turret = def.turretSprite, let top = turretNode(turret, def: def, style: style, art: art) {
                root.addChild(top)
            }
        } else {
            let scaffold = content.buildings.rules.constructionSprites["\(def.width)x\(def.height)"] ?? def.sprite
            body = art.sprite(scaffold, width: def.width, height: def.height, category: def.category, style: style)
            root.addChild(body)
            root.addChild(progressBar(width: geometry.footprintWidth(width: def.width, height: def.height) * 0.6,
                                      aboveY: (1 - body.anchorPoint.y) * body.size.height))
            updateProgress(root, building: building)
        }
        return root
    }

    /// Turret top resting toward the screen's lower right. Top-down rotates its one image; isometric uses a facing
    /// image and is left out while that view has no turret art (the placeholder block stands in for the tower).
    private static func turretNode(_ id: String, def: BuildingDef, style: ArtStyle, art: ArtRegistry) -> SKNode? {
        let restAngle = -Double.pi / 4
        let frame = DirectionalSprite.frame(baseId: id, screenAngle: style.kind == .topDown ? 0 : restAngle,
                                            facings: style.view.turretFacings, allowMirror: style.asset(id)?.mirrorable ?? true)
        if style.kind == .isometric && !art.hasImage(frame.id, style: style) { return nil }
        let top = art.sprite(frame.id, width: def.width, height: def.height, category: def.category, style: style)
        top.zRotation = frame.rotation
        if frame.mirrored { top.xScale = -top.xScale }
        top.zPosition = ZLayer.turretOffset
        return top
    }

    /// Stretches the green fill to the building's construction progress (0...1).
    static func updateProgress(_ node: SKNode, building: Building) {
        guard let bar = node.childNode(withName: progressName),
              let fill = bar.childNode(withName: "fill") as? SKSpriteNode else { return }
        fill.xScale = max(0.001, building.constructionProgress)
    }

    private static func progressBar(width barWidth: CGFloat, aboveY top: CGFloat) -> SKNode {
        let barHeight: CGFloat = 4
        let bar = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6), size: CGSize(width: barWidth, height: barHeight))
        bar.name = progressName
        bar.position = CGPoint(x: 0, y: top + barHeight)
        bar.zPosition = ZLayer.overlayOffset
        let fill = SKSpriteNode(color: .systemGreen, size: CGSize(width: barWidth, height: barHeight))
        fill.name = "fill"
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -barWidth / 2, y: 0)
        fill.zPosition = 1
        bar.addChild(fill)
        return bar
    }
}
