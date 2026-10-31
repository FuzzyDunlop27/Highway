// Purpose: Picks what a blocked zombie attacks (HQ next to it, or the building on its next tile) and deals the damage. Notes: docs/features/pathing.md
import Foundation

enum WallBashing {
    /// What a zombie on `tile` attacks this tick, or nil if its way is clear.
    /// The HQ comes first when the zombie is next to it (8 neighbors); otherwise the blocking building
    /// (not rubble, not a trap) on the flow field's next tile.
    static func target(from tile: GridPoint, field: FlowField, index: BuildingTileIndex,
                       buildings: [Building], content: GameContent) -> (buildingIndex: Int, tile: GridPoint)? {
        for step in FlowField.steps {
            let n = GridPoint(x: tile.x + step.dx, y: tile.y + step.dy)
            if let bi = index.buildingIndex(at: n), buildings[bi].defId == FlowField.hqId { return (bi, n) }
        }
        guard let next = field.nextStep(from: tile), let bi = index.buildingIndex(at: next) else { return nil }
        guard let def = content.buildingDef(buildings[bi].defId) else { return nil }
        return FlowField.blocks(buildings[bi], def: def) ? (bi, next) : nil
    }

    /// One tick of bashing: damageVsBuildingsPerSec (× wallBashMultiplier on walls), hp clamped at 0.
    /// Emits `.buildingDamaged` about once per second per zombie. Does not make rubble (HordeResolution does).
    static func hit(_ building: inout Building, by zombie: ZombieDef, content: GameContent, clock: ZombieClock,
                    events: inout [SimEvent]) {
        guard let def = content.buildingDef(building.defId) else { return }
        let multiplier = FlowField.isWall(def) ? zombie.wallBashMultiplier : 1
        let damage = clock.wholeAmount(perSecond: zombie.damageVsBuildingsPerSec * multiplier)
        building.hp = max(0, building.hp - damage)
        if clock.isPulse { events.append(.buildingDamaged(building.id)) }
    }
}
