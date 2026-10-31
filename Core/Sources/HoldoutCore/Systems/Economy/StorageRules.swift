// Purpose: Storage caps for food/scrap and housing (survivor cap) from finished buildings. Notes: docs/features/economy.md
import Foundation

enum StorageRules {
    /// baseCap (resources.json) + storageAdded of every finished building at its level (HQ, Storage).
    static func cap(_ kind: ResourceKind, base: Base, content: GameContent) -> Int {
        let baseCap = content.resources.def(kind)?.baseCap ?? 0
        return baseCap + finishedEffects(base, content).reduce(0) { $0 + ($1.storageAdded ?? 0) }
    }

    /// Survivor cap: housing of every finished building at its level (HQ, Shelters).
    static func housing(base: Base, content: GameContent) -> Int {
        finishedEffects(base, content).reduce(0) { $0 + ($1.housing ?? 0) }
    }

    /// Stock can never sit above the cap (e.g. after a Storage is demolished).
    static func clampToCaps(_ base: inout Base, content: GameContent) {
        for kind in ResourceKind.allCases {
            base.stock[kind] = min(base.stock[kind], cap(kind, base: base, content: content))
        }
    }

    private static func finishedEffects(_ base: Base, _ content: GameContent) -> [EffectsDef] {
        base.buildings.compactMap { b in
            b.isComplete ? content.buildingDef(b.defId)?.level(b.level)?.effects : nil
        }
    }
}
