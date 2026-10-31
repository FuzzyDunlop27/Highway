// Purpose: After combat each tick: remove dead zombies (loot), turn 0-hp buildings to rubble, HQ fall, horde end. Notes: docs/features/hordes.md
import Foundation

/// STUB (1B contract) — the hordes agent fills this in.
enum HordeResolution {
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {}
}
