// Purpose: Builds the map's ground tiles and decorations (wrecks, dead trees, rubble) for the active view. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
enum TerrainNodeFactory {
    static func make(map: MapDef, style: ArtStyle, art: ArtRegistry) -> SKNode {
        let root = SKNode()
        root.name = "terrain"
        let geometry = style.geometry
        for y in 0..<map.height {
            for x in 0..<map.width {
                let p = GridPoint(x: x, y: y)
                guard let tile = map.tile(at: p) else { continue }
                let node = art.sprite(tile.tile, width: 1, height: 1, category: ArtCategory.tile, style: style)
                node.position = geometry.groundAnchor(origin: p, width: 1, height: 1)
                node.zPosition = ZLayer.ground
                root.addChild(node)
            }
        }
        for deco in map.decorations {
            let w = deco.footprint[0], h = deco.footprint[1], origin = GridPoint(x: deco.x, y: deco.y)
            let node = art.sprite(deco.id, width: w, height: h, category: ArtCategory.decoration, style: style)
            node.position = geometry.groundAnchor(origin: origin, width: w, height: h)
            node.zPosition = ZLayer.sorted(depth: geometry.depth(origin: origin, width: w, height: h))
            root.addChild(node)
        }
        return root
    }
}
