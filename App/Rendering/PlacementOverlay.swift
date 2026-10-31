// Purpose: While placing/moving: a local tile grid around the ghost (red where nothing can be built) and fading of buildings that hide it. Notes: docs/features/input.md
import SpriteKit
import HoldoutCore

@MainActor
final class PlacementOverlay {
    /// Look-only: tiles of grid drawn on each side of the ghost.
    static let gridRadius = 6
    /// Look-only: how see-through a building in front of the ghost becomes.
    static let occluderAlpha: CGFloat = 0.3

    private struct GridKey: Equatable { let origin: GridPoint; let width: Int; let height: Int; let kind: ProjectionKind }
    private var grid: (key: GridKey, node: SKNode)?
    private var faded: [SKNode] = []

    /// Forget everything (the world was rebuilt for the other view).
    func reset() {
        grid?.node.removeFromParent()
        grid = nil
        faded = []
    }

    /// Call every frame. `def`/`origin` describe the ghost (nil when nothing is being placed or moved). With no
    /// `ghostNode` (wall tool before a line is drawn) only the grid shows.
    func sync(def: BuildingDef?, origin: GridPoint, ghostNode: SKNode?, loop: GameLoop, style: ArtStyle,
              world: SKNode, buildings: [BuildingID: SKNode]) {
        guard let def else {
            restoreFaded()
            reset()
            return
        }
        let key = GridKey(origin: origin, width: def.width, height: def.height, kind: style.kind)
        if grid?.key != key {
            grid?.node.removeFromParent()
            let node = makeGrid(around: origin, def: def, loop: loop, style: style)
            world.addChild(node)
            grid = (key, node)
        }
        guard let ghostNode else { restoreFaded(); return }
        fadeOccluders(of: ghostNode, depth: style.geometry.depth(origin: origin, width: def.width, height: def.height),
                      world: world, buildings: buildings)
    }

    // MARK: Grid

    /// Tile outlines within `gridRadius` of the ghost; tiles that can never be built on (highway, wrecks, trees) are tinted red.
    private func makeGrid(around origin: GridPoint, def: BuildingDef, loop: GameLoop, style: ArtStyle) -> SKNode {
        let map = loop.map, geometry = style.geometry
        let blockedTiles = map.decorationTiles
        let lines = CGMutablePath(), blocked = CGMutablePath()
        let r = Self.gridRadius
        for y in max(0, origin.y - r)...min(map.height - 1, origin.y + def.height - 1 + r) {
            for x in max(0, origin.x - r)...min(map.width - 1, origin.x + def.width - 1 + r) {
                let p = GridPoint(x: x, y: y)
                let outline = geometry.outlinePath(origin: p, width: 1, height: 1)
                lines.addPath(outline)
                if map.tile(at: p)?.buildable == false || blockedTiles.contains(p) { blocked.addPath(outline) }
            }
        }
        let root = SKNode()
        root.zPosition = ZLayer.decal + 0.5
        let blockedNode = SKShapeNode(path: blocked)
        blockedNode.fillColor = UIColor.systemRed.withAlphaComponent(0.18)
        blockedNode.strokeColor = .clear
        root.addChild(blockedNode)
        let lineNode = SKShapeNode(path: lines)
        lineNode.strokeColor = UIColor.white.withAlphaComponent(0.35)
        lineNode.lineWidth = 1
        lineNode.zPosition = 0.1
        root.addChild(lineNode)
        return root
    }

    // MARK: Occluders

    /// Buildings and decorations drawn in front of the ghost that overlap it on screen become see-through;
    /// anything faded last frame that no longer overlaps is restored. Presentation only: nothing in Core changes.
    private func fadeOccluders(of ghostNode: SKNode, depth: Double, world: SKNode, buildings: [BuildingID: SKNode]) {
        let ghostRect = ghostNode.calculateAccumulatedFrame()
        let ghostZ = ZLayer.sorted(depth: depth)
        var candidates = Array(buildings.values)
        if let terrain = world.childNode(withName: "terrain") {
            candidates += terrain.children.filter { $0.zPosition >= ZLayer.sortedBase }  // decorations (trees, wrecks)
        }
        let now = candidates.filter { $0.zPosition > ghostZ && $0.calculateAccumulatedFrame().intersects(ghostRect) }
        let nowSet = Set(now.map(ObjectIdentifier.init))
        for node in faded where !nowSet.contains(ObjectIdentifier(node)) { node.alpha = 1 }
        for node in now { node.alpha = Self.occluderAlpha }
        faded = now
    }

    private func restoreFaded() {
        for node in faded { node.alpha = 1 }
        faded = []
    }
}
