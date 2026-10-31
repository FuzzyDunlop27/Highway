// Purpose: Draws the see-through placement preview (green ok / red blocked footprint tiles), the selection outline, and the range ring. Notes: docs/features/input.md
import SpriteKit
import HoldoutCore

@MainActor
enum GhostNodeFactory {
    static func make(def: BuildingDef, origin: GridPoint, check: PlacementCheck?, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let root = SKNode()
        root.zPosition = ZLayer.ghost
        let geometry = style.geometry
        let isValid = check?.isValid ?? false
        let bad = Set(check?.badTiles ?? [])
        for tile in origin.footprintTiles(width: def.width, height: def.height) {
            // Blocked tiles are strong red; if the spot fails for another reason (cost, limit) the whole footprint is light red.
            let color: UIColor = isValid ? .systemGreen : (bad.contains(tile) ? .systemRed : .systemRed.withAlphaComponent(0.6))
            let square = SKShapeNode(path: geometry.outlinePath(origin: tile, width: 1, height: 1))
            square.fillColor = color.withAlphaComponent(0.45)
            square.strokeColor = color.withAlphaComponent(0.8)
            square.lineWidth = 1
            root.addChild(square)
        }
        let sprite = art.sprite(def.sprite, width: def.width, height: def.height, category: def.category, style: style)
        sprite.position = geometry.groundAnchor(origin: origin, width: def.width, height: def.height)
        sprite.alpha = 0.6
        sprite.zPosition = 1
        if !isValid {
            sprite.color = .systemRed
            sprite.colorBlendFactor = 0.5
        }
        root.addChild(sprite)
        return root
    }

    /// Yellow outline around the selected building's footprint (a diamond in isometric).
    static func selectionOutline(def: BuildingDef, origin: GridPoint, style: ArtStyle) -> SKNode {
        let outline = SKShapeNode(path: style.geometry.outlinePath(origin: origin, width: def.width, height: def.height))
        outline.strokeColor = .systemYellow
        outline.lineWidth = 2
        outline.zPosition = ZLayer.selection
        return outline
    }

    /// Range ring of a selected tower (or HQ): a projected circle around its footprint middle, an ellipse in isometric.
    static func rangeRing(def: BuildingDef, origin: GridPoint, range: Double, style: ArtStyle) -> SKNode {
        let path = style.geometry.circlePath(gx: Double(origin.x) + Double(def.width) / 2,
                                             gy: Double(origin.y) + Double(def.height) / 2, radius: range)
        let ring = SKShapeNode(path: path)
        ring.fillColor = UIColor.systemYellow.withAlphaComponent(0.08)
        ring.strokeColor = UIColor.systemYellow.withAlphaComponent(0.7)
        ring.lineWidth = 1.5
        return ring
    }
}
