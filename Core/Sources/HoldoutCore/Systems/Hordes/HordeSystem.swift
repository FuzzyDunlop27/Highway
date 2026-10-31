// Purpose: The horde clock (app-open only), the warning, and spawning zombies at the chosen edges. Notes: docs/features/hordes.md
import Foundation

/// STUB (1B contract) — the hordes agent fills this in.
enum HordeSystem {
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {}
    /// Starts the next horde right away (debug command).
    static func startNow(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {}
}
