// Purpose: What finished research changes: tower range, farm output (wall_metal is a placement rule). Notes: docs/features/scavenging-research.md
import Foundation

enum ResearchEffects {
    /// Items the group has finished, as definitions.
    private static func known(_ knowledge: [String], _ content: GameContent) -> [ResearchItemDef] {
        content.research.items.filter { knowledge.contains($0.id) }
    }

    /// Extra range in tiles for tower `defId` (research.json `towerRangeBonusTiles`).
    static func towerRangeBonus(defId: String, knowledge: [String], content: GameContent) -> Double {
        known(knowledge, content).reduce(0) { total, item in
            guard item.effect.type == "towerRangeBonusTiles", item.effect.towers?.contains(defId) == true else { return total }
            return total + (item.effect.value ?? 0)
        }
    }

    /// Output factor for building `defId` (research.json `productionMultiplier`); 1 if nothing applies.
    static func productionMultiplier(defId: String, knowledge: [String], content: GameContent) -> Double {
        known(knowledge, content).reduce(1) { total, item in
            guard item.effect.type == "productionMultiplier", item.effect.buildings?.contains(defId) == true else { return total }
            return total * (item.effect.value ?? 1)
        }
    }
}
