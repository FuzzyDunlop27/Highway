// Purpose: Pulsing red arrows and tile highlights at the spawn edges the next horde was announced for. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
final class HordeWarningOverlay {
    private var node: SKNode?
    private var shownEdges: [String]?

    // Look only: arrow size in tiles, how far inside the map it sits, pulse time.
    private static let arrowTiles: CGFloat = 1.4
    private static let insetTiles = 1.5
    private static let pulseSeconds = 0.5

    /// Forgets what is drawn (the world was rebuilt); the next sync redraws.
    func reset() {
        node?.removeFromParent()
        node = nil
        shownEdges = nil
    }

    /// Shows arrows for `edges` (map spawnEdges ids); redraws only when the list changes.
    func sync(edges: [String], map: MapDef, style: ArtStyle, parent: SKNode) {
        guard edges != shownEdges else { return }
        reset()
        shownEdges = edges
        guard !edges.isEmpty else { return }
        let root = SKNode()
        for edge in map.spawnEdges where edges.contains(edge.id) {
            root.addChild(highlight(edge, style: style))
            root.addChild(arrow(edge, map: map, style: style))
        }
        parent.addChild(root)
        node = root
    }

    private func highlight(_ edge: SpawnEdgeDef, style: ArtStyle) -> SKNode {
        let shape = SKShapeNode(path: style.geometry.outlinePath(origin: GridPoint(x: edge.x, y: edge.y), width: edge.w, height: edge.h))
        shape.fillColor = UIColor.systemRed.withAlphaComponent(0.35)
        shape.strokeColor = UIColor.systemRed.withAlphaComponent(0.8)
        shape.lineWidth = 1.5
        shape.zPosition = ZLayer.decal
        shape.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: Self.pulseSeconds),
                                            .fadeAlpha(to: 1, duration: Self.pulseSeconds)])))
        return shape
    }

    /// An arrow just inside the edge, pointing toward the middle of the map (where zombies will head).
    private func arrow(_ edge: SpawnEdgeDef, map: MapDef, style: ArtStyle) -> SKNode {
        let geometry = style.geometry
        let cx = Double(edge.x) + Double(edge.w) / 2, cy = Double(edge.y) + Double(edge.h) / 2
        let heading = atan2(Double(map.height) / 2 - cy, Double(map.width) / 2 - cx)
        let gx = cx + cos(heading) * Self.insetTiles, gy = cy + sin(heading) * Self.insetTiles
        let length = geometry.tileWidth * Self.arrowTiles
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: length / 2, y: 0), CGPoint(x: -length / 2, y: length * 0.4),
                                CGPoint(x: -length / 4, y: 0), CGPoint(x: -length / 2, y: -length * 0.4)])
        path.closeSubpath()
        let shape = SKShapeNode(path: path)
        shape.fillColor = .systemRed
        shape.strokeColor = .white
        shape.lineWidth = 2
        shape.position = geometry.point(gx: gx, gy: gy)
        shape.zRotation = CGFloat(geometry.screenAngle(gx: gx, gy: gy, heading: heading))
        shape.zPosition = ZLayer.effects
        let grow = SKAction.scale(to: 1.25, duration: Self.pulseSeconds)
        grow.timingMode = .easeInEaseOut
        let shrink = SKAction.scale(to: 1, duration: Self.pulseSeconds)
        shrink.timingMode = .easeInEaseOut
        shape.run(.repeatForever(.sequence([grow, shrink])))
        return shape
    }
}
