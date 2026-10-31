// Purpose: Read-only horde summary for the HUD: day, countdown, warned edges, zombies left. Notes: docs/features/hordes.md
import Foundation

public struct HordeStatus: Equatable, Sendable {
    public let day: Int
    /// In-game seconds until the next horde (nil while one is attacking or before the clock is scheduled).
    public let secondsUntilNext: Double?
    /// Edges announced for the next horde (empty until the warning).
    public let warningEdges: [String]
    public let isActive: Bool
    public let zombiesAlive: Int
    /// Zombies still to come in the active horde.
    public let zombiesToSpawn: Int

    static func make(state: GameState, content: GameContent) -> HordeStatus {
        let h = state.base.horde
        return HordeStatus(day: h.day,
                           secondsUntilNext: h.active == nil ? h.ticksUntilNext.map { Double($0) / Double(content.economy.ticksPerSecond) } : nil,
                           warningEdges: h.warningEdges, isActive: h.active != nil,
                           zombiesAlive: state.base.zombies.count, zombiesToSpawn: h.active?.spawnQueue.count ?? 0)
    }
}
