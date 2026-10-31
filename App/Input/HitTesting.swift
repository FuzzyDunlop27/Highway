// Purpose: Finds what a tap hit: the front-most building drawn there (isometric roofs), else the ground tile. Notes: docs/features/input.md
import SpriteKit
import HoldoutCore

@MainActor
enum HitTesting {
    /// The building whose drawing covers `point` (scene coordinates of `world`), front-most first.
    /// Only used in isometric, where tall sprites stand over tiles that aren't theirs.
    static func building(at point: CGPoint, in world: SKNode, nodes: [BuildingID: SKNode]) -> BuildingID? {
        let local = world.convert(point, from: world.scene ?? world)
        return nodes
            .filter { _, node in node.childNode(withName: SpriteName.body)?.frame
                .offsetBy(dx: node.position.x, dy: node.position.y).contains(local) ?? false }
            .max { $0.value.zPosition < $1.value.zPosition }?
            .key
    }
}
