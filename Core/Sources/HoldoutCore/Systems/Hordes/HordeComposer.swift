// Purpose: Decides a horde's size and mix (budget by day and town value, composition, edges) with seeded random. Notes: docs/features/hordes.md
import Foundation

/// STUB (1B contract) — the hordes agent fills this in.
enum HordeComposer {
    /// Zombie types to spawn (in order) and the edges they come from.
    static func compose(day: Int, state: inout GameState, content: GameContent) -> (queue: [String], edges: [String]) { ([], []) }
}
