// Purpose: The whole saved game: clock, speed, random state, the group, and its bases. Notes: docs/features/core-api.md
import Foundation

public struct GameState: Codable, Equatable, Sendable {
    /// Simulation ticks run since the game began.
    public var tick: Int
    /// Current game speed (one of economy.json speedOptions; 0 = paused).
    public var speed: Int
    public var random: SeededRandom
    public var group: Group
    /// Phase 1 has exactly one base; the array leaves room for travel phases.
    public var bases: [Base]
    public var activeBaseIndex: Int

    /// The base the player is looking at.
    public var base: Base {
        get { bases[activeBaseIndex] }
        set { bases[activeBaseIndex] = newValue }
    }
}
