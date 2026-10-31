// Purpose: Keeps one ZombieNode per zombie in Core state: adds new ones, moves them every frame, removes the gone. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
final class ZombieLayer {
    private(set) var nodes: [ZombieID: ZombieNode] = [:]
    private var defs: [String: ZombieDef] = [:]

    /// Forgets every node (the world was rebuilt for the other view; the next sync re-makes them).
    func reset() {
        for node in nodes.values { node.root.removeFromParent() }
        nodes.removeAll()
    }

    func sync(loop: GameLoop, style: ArtStyle, art: ArtRegistry, parent: SKNode) {
        if defs.isEmpty {
            defs = Dictionary(loop.content.zombies.zombies.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        let zombies = loop.state.base.zombies
        var seen = Set<ZombieID>(minimumCapacity: zombies.count)
        for zombie in zombies {
            seen.insert(zombie.id)
            if let node = nodes[zombie.id] {
                node.update(zombie, def: defs[zombie.defId], style: style, art: art)
            } else {
                let node = ZombieNodeFactory.make(zombie, def: defs[zombie.defId], style: style, art: art)
                parent.addChild(node.root)
                nodes[zombie.id] = node
            }
        }
        guard nodes.count != seen.count else { return }
        for id in nodes.keys where !seen.contains(id) {
            nodes.removeValue(forKey: id)?.root.removeFromParent()
        }
    }
}
