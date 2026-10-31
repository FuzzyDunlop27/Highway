// Purpose: Codable shapes for Content/economy.json (tick rate, speeds, autosave, HQ-fall rules). Notes: docs/features/economy.md
import Foundation

public struct EconomyContent: Codable, Sendable {
    public let schemaVersion: Int
    /// Fixed simulation ticks per in-game second at 1x.
    public let ticksPerSecond: Int
    /// Allowed game speeds; 0 = paused.
    public let speedOptions: [Int]
    /// Real seconds between autosaves (the App runs the timer).
    public let autosaveSeconds: Double
    /// Longest real-time gap one `GameLoop.advance` call will simulate (protects against frame hitches).
    public let maxFrameSeconds: Double
    public let hqFall: HqFallDef
}

public struct HqFallDef: Codable, Sendable {
    public let endsHorde: Bool
    public let resourceLossPct: Int
    public let affects: [ResourceKind]
    public let hqRestoreHpPct: Int
    public let destroyedBuildingsBecomeRubble: Bool
}
