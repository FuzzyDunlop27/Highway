// Purpose: 3D selection look: yellow outline around the selected building's footprint and its range ring on the ground. Notes: docs/features/input.md
import RealityKit
import UIKit
import HoldoutCore

/// Shows which building is selected. Towers (and the HQ) also get their range (`buildings.json effects.range`, tiles)
/// as a ring on the ground. Rebuilt only when the selection, its spot or its level changes.
@MainActor
final class SelectionLayer3D {
    let root = Entity()

    /// Look-only: outline and ring strength.
    private static let outlineAlpha: Float = 0.95
    private static let ringAlpha: Float = 0.7
    private static let ringFillAlpha: Float = 0.08

    private struct Key: Equatable { let id: BuildingID; let defId: String; let origin: GridPoint; let level: Int }
    private var shown: (key: Key, entity: Entity)?

    init() { root.name = "selection" }

    func sync(selected: Building?, content: GameContent, mapping: WorldMapping3D) {
        let key = selected.map { Key(id: $0.id, defId: $0.defId, origin: $0.origin, level: $0.level) }
        guard shown?.key != key else { return }
        shown?.entity.removeFromParent()
        shown = nil
        guard let selected, let key, let def = content.buildingDef(selected.defId) else { return }
        let entity = Entity()
        let a = mapping.world(gx: Double(key.origin.x), gy: Double(key.origin.y))
        let b = mapping.world(gx: Double(key.origin.x + def.width), gy: Double(key.origin.y + def.height))
        let rect = OverlayMeshes3D.Rect(x0: Float(a.x), z0: Float(a.z), x1: Float(b.x), z1: Float(b.z))
        if let outline = OverlayMeshes3D.rects(OverlayMeshes3D.outline(rect, width: OverlayMeshes3D.outlineWidth),
                                               color: .systemYellow, alpha: Self.outlineAlpha, lift: OverlayMeshes3D.lineLift) {
            entity.addChild(outline)
        }
        if let range = def.level(selected.level)?.effects.range, range > 0 {
            let center = Reality3DSizes.vector(mapping.footprintCenter(origin: key.origin, width: def.width, height: def.height))
            entity.addChild(OverlayMeshes3D.ring(center: center, radius: Float(range * mapping.metresPerTile),
                                                 color: .systemYellow, alpha: Self.ringAlpha, fillAlpha: Self.ringFillAlpha))
        }
        root.addChild(entity)
        shown = (key, entity)
    }
}
