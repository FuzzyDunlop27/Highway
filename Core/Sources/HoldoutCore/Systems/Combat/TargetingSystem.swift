// Purpose: Picks which zombie a tower shoots (nearest-to-HQ first, or nearest). Notes: docs/features/combat.md
import Foundation

/// STUB (1B contract) — the combat agent fills this in.
enum TargetingSystem {
    /// The zombie `tower` should shoot this tick, or nil if none is in range.
    static func target(for tower: Building, def: BuildingDef, range: Double, state: GameState, field: FlowField) -> ZombieID? { nil }
}
