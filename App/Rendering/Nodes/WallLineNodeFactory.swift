// Purpose: Draws the wall tool's planned line: see-through walls on green tiles, red tiles that will be skipped. Notes: docs/features/input.md
import SpriteKit
import HoldoutCore

@MainActor
enum WallLineNodeFactory {
    /// Look-only: how see-through the planned walls are.
    static let plannedAlpha: CGFloat = 0.6

    static func make(plan: LinePlan, def: BuildingDef, existingWalls: Set<GridPoint>, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let root = SKNode()
        root.zPosition = ZLayer.ghost
        let geometry = style.geometry
        let ok = CGMutablePath(), skipped = CGMutablePath()
        for t in plan.buildable { ok.addPath(geometry.outlinePath(origin: t, width: 1, height: 1)) }
        for t in plan.blocked { skipped.addPath(geometry.outlinePath(origin: t, width: 1, height: 1)) }
        root.addChild(shape(ok, color: plan.canBuild ? .systemGreen : .systemOrange))
        root.addChild(shape(skipped, color: .systemRed))

        // Planned walls face along the line, like built ones (DefenseNodeFactory picks the mirror from neighbors).
        let neighbors = existingWalls.union(plan.tiles)
        for t in plan.buildable.sorted(by: { geometry.depth(origin: $0, width: 1, height: 1) < geometry.depth(origin: $1, width: 1, height: 1) }) {
            let wall = SKNode()
            wall.position = geometry.groundAnchor(origin: t, width: 1, height: 1)
            wall.zPosition = 1 + CGFloat(geometry.depth(origin: t, width: 1, height: 1)) * 0.01
            let fake = Building(id: 0, defId: def.id, level: 1, origin: t, hp: 1, constructionTicksLeft: 0,
                                constructionTicksTotal: 0, invested: .zero)
            let variant = DefenseNodeFactory.variant(fake, def: def, wallTiles: neighbors)
            _ = DefenseNodeFactory.addParts(to: wall, def: def, variant: variant, aim: nil, style: style, art: art)
            wall.alpha = plannedAlpha
            root.addChild(wall)
        }
        return root
    }

    private static func shape(_ path: CGPath, color: UIColor) -> SKShapeNode {
        let node = SKShapeNode(path: path)
        node.fillColor = color.withAlphaComponent(0.4)
        node.strokeColor = color.withAlphaComponent(0.85)
        node.lineWidth = 1
        return node
    }
}
