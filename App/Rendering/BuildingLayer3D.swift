// Purpose: Keeps one 3D entity per building in Core state; rebuilds it only when its look changes (Signature). Notes: docs/features/rendering-art.md
import RealityKit
import HoldoutCore

/// Art ids per state: finished model, scaffold (buildings.json constructionSprites), faded 1×1 while building, rubble.
/// Turret tops, health and progress bars come with effects in chunk 4R; tower bases draw alone for now.
@MainActor
final class BuildingLayer3D {
    /// Everything that changes how a building looks in 3D right now (no health bars yet, so hp isn't in it).
    struct Signature: Equatable {
        let defId: String
        let level: Int
        let origin: GridPoint
        let isComplete: Bool
        let isRubble: Bool
        /// True for a wall in a north-south line (its model turns 90°; models are built along east-west).
        let runsNorthSouth: Bool
    }

    let root = Entity()
    private var entries: [BuildingID: (signature: Signature, entity: Entity)] = [:]

    init() { root.name = "buildings" }

    func sync(loop: GameLoop, mapping: WorldMapping3D, settings: Reality3DDef, registry: ModelRegistry) {
        let buildings = loop.state.base.buildings
        let walls = Self.wallTiles(buildings, content: loop.content)
        var seen = Set<BuildingID>(minimumCapacity: buildings.count)
        for building in buildings {
            seen.insert(building.id)
            guard let def = loop.content.buildingDef(building.defId) else { continue }
            let signature = Signature(defId: building.defId, level: building.level, origin: building.origin,
                                      isComplete: building.isComplete, isRubble: building.isRubble,
                                      runsNorthSouth: Self.runsNorthSouth(building, def: def, wallTiles: walls))
            if entries[building.id]?.signature == signature { continue }
            entries[building.id]?.entity.removeFromParent()
            let entity = make(building, def: def, signature: signature, content: loop.content, mapping: mapping,
                              settings: settings, registry: registry)
            root.addChild(entity)
            entries[building.id] = (signature, entity)
        }
        guard entries.count != seen.count else { return }
        for id in entries.keys where !seen.contains(id) {
            entries.removeValue(forKey: id)?.entity.removeFromParent()
        }
    }

    private func make(_ b: Building, def: BuildingDef, signature: Signature, content: GameContent,
                      mapping: WorldMapping3D, settings: Reality3DDef, registry: ModelRegistry) -> Entity {
        let isSmall = def.width == 1 && def.height == 1
        let id: String, category: String
        if b.isRubble {
            let rules = content.buildings.rules.rubble
            id = isSmall ? rules.rubbleSprite1x1 : rules.rubbleSprite2x2
            category = ArtCategory.decoration
        } else if !b.isComplete && !isSmall {
            id = content.buildings.rules.constructionSprites["\(def.width)x\(def.height)"] ?? def.sprite
            category = def.category
        } else {
            id = def.sprite  // half-built 1×1s (walls, towers, traps) show themselves faded, as in 2D
            category = def.category
        }
        let size = mapping.footprintSize(width: def.width, height: def.height)
        let entity = registry.entity(id, size: [Float(size.x), Reality3DSizes.height(category: category, settings: settings),
                                                Float(size.z)])
        entity.position = Reality3DSizes.vector(mapping.footprintCenter(origin: b.origin, width: def.width, height: def.height))
        if signature.runsNorthSouth {
            entity.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        }
        if !b.isComplete && !b.isRubble && isSmall {
            entity.components.set(OpacityComponent(opacity: ModelRegistry.underConstructionOpacity))
        }
        return entity
    }

    private static let wallCategory = "wall"

    /// Tiles holding a standing wall (rubble doesn't count).
    static func wallTiles(_ buildings: [Building], content: GameContent) -> Set<GridPoint> {
        Set(buildings.compactMap { b in
            guard !b.isRubble, content.buildingDef(b.defId)?.category == wallCategory else { return nil }
            return b.origin
        })
    }

    /// A wall with more wall neighbours north/south than east/west is part of a north-south line.
    static func runsNorthSouth(_ b: Building, def: BuildingDef, wallTiles: Set<GridPoint>) -> Bool {
        guard def.category == wallCategory else { return false }
        let p = b.origin
        let alongX = [GridPoint(x: p.x - 1, y: p.y), GridPoint(x: p.x + 1, y: p.y)].filter(wallTiles.contains).count
        let alongY = [GridPoint(x: p.x, y: p.y - 1), GridPoint(x: p.x, y: p.y + 1)].filter(wallTiles.contains).count
        return alongY > alongX
    }
}
