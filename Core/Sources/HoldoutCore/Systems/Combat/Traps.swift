// Purpose: Traps under a zombie act on it each tick: spikes hurt it, barbed wire slows it, both wear down. Notes: docs/features/pathing.md
import Foundation

enum Traps {
    /// Applies the finished, standing trap (if any) on `tile` to `zombie` for one tick and returns the speed
    /// multiplier (1 − slowPct/100 on barbed wire, 1 elsewhere). Spikes deal `dps`/tps damage and emit
    /// `.trapHit` about once per second per zombie. Any trap with `durabilityLossPerZombieSecond` loses that
    /// much hp per zombie-second (whole hp per tick, see ZombieClock), clamped at 0. Dead zombies are not removed.
    static func apply(zombie: inout Zombie, tile: GridPoint, index: BuildingTileIndex, buildings: inout [Building],
                      content: GameContent, clock: ZombieClock, events: inout [SimEvent]) -> Double {
        guard let bi = index.buildingIndex(at: tile) else { return 1 }
        var trap = buildings[bi]
        guard trap.isComplete, trap.hp > 0, let def = content.buildingDef(trap.defId), def.blocksPath == .open,
              let level = def.level(trap.level) else { return 1 }
        if let dps = level.effects.dps, dps > 0, clock.ticksPerSecond > 0 {
            zombie.hp -= dps / Double(clock.ticksPerSecond)
            if clock.isPulse { events.append(.trapHit(trap.id, zombie.id)) }
        }
        if let loss = def.durabilityLossPerZombieSecond {
            trap.hp = max(0, trap.hp - clock.wholeAmount(perSecond: loss))
            buildings[bi] = trap
        }
        return max(0, 1 - (level.effects.slowPct ?? 0) / 100)
    }
}
