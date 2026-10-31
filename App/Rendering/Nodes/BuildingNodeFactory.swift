// Purpose: Draws one placed building for the active view: sprite (defenses via DefenseNodeFactory), scaffolding + progress bar, rubble, health bar. Notes: docs/features/rendering-art.md
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
        let isRubble: Bool
        /// Health in tenths (10 = full), so the health bar redraws as it drops.
        let hpBucket: Int
        /// Defense look (DefenseNodeFactory.variant): wall direction, tower staffed.
        let variant: Int

        init(_ b: Building, def: BuildingDef?, variant: Int = 0) {
            defId = b.defId
            level = b.level
            origin = b.origin
            isComplete = b.isComplete
            isRubble = b.isRubble
            hpBucket = Int((BuildingNodeFactory.healthFraction(b, def: def) * Double(BuildingNodeFactory.hpBuckets)).rounded(.up))
            self.variant = variant
        }
    }

    nonisolated static let hpBuckets = 10
    private static let barHeight: CGFloat = 4

    /// hp / max hp at its level (1 if unknown).
    nonisolated static func healthFraction(_ b: Building, def: BuildingDef?) -> Double {
        guard let maxHp = def?.level(b.level)?.hp, maxHp > 0 else { return 1 }
        return min(1, max(0, Double(b.hp) / Double(maxHp)))
    }

    /// `variant` and `aim` only matter for defenses (see DefenseNodeFactory).
    static func make(_ building: Building, content: GameContent, style: ArtStyle, art: ArtRegistry,
                     variant: Int = 0, aim: Double? = nil) -> SKNode {
        let root = SKNode()
        root.name = SpriteName.building
        guard let def = content.buildingDef(building.defId) else { return root }
        let geometry = style.geometry
        root.position = geometry.groundAnchor(origin: building.origin, width: def.width, height: def.height)
        root.zPosition = ZLayer.sorted(depth: geometry.depth(origin: building.origin, width: def.width, height: def.height))
        let barWidth = geometry.footprintWidth(width: def.width, height: def.height) * 0.6

        let body: SKSpriteNode
        if building.isRubble {
            // One rubble picture per size, stretched to the footprint (buildings.json rules.rubble).
            let rules = content.buildings.rules.rubble
            let id = def.width == 1 && def.height == 1 ? rules.rubbleSprite1x1 : rules.rubbleSprite2x2
            body = art.sprite(id, width: def.width, height: def.height, category: ArtCategory.decoration, style: style)
            root.addChild(body)
        } else if !building.isComplete {
            let scaffold = content.buildings.rules.constructionSprites["\(def.width)x\(def.height)"] ?? def.sprite
            body = art.sprite(scaffold, width: def.width, height: def.height, category: def.category, style: style)
            root.addChild(body)
        } else if DefenseNodeFactory.isDefense(def) {
            body = DefenseNodeFactory.addParts(to: root, def: def, variant: variant, aim: aim, style: style, art: art)
        } else {
            body = art.sprite(def.sprite, width: def.width, height: def.height, category: def.category, style: style)
            root.addChild(body)
        }

        let top = body.frame.maxY + barHeight
        if building.constructionTicksLeft > 0 {
            root.addChild(BarNodeFactory.make(name: BarNodeFactory.progressName, width: barWidth, height: barHeight,
                                              centerY: top, color: .systemGreen))
            updateProgress(root, building: building)
        } else if building.isComplete {
            let health = healthFraction(building, def: def)
            if health < 1 {
                let bar = BarNodeFactory.make(name: BarNodeFactory.healthName, width: barWidth, height: barHeight,
                                              centerY: top, color: BarNodeFactory.healthColor(health))
                BarNodeFactory.set(bar, value: health)
                root.addChild(bar)
            }
        }
        return root
    }

    /// Stretches the green fill to the building's construction (or repair) progress (0...1).
    static func updateProgress(_ node: SKNode, building: Building) {
        BarNodeFactory.set(node.childNode(withName: BarNodeFactory.progressName), value: building.constructionProgress)
    }
}
