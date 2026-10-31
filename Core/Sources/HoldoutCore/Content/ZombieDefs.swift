// Purpose: Codable shapes for Content/zombies.json (decoded and checked now; used from 1B). Notes: docs/features/core-api.md
import Foundation

public struct ZombiesContent: Codable, Sendable {
    public let schemaVersion: Int
    public let zombies: [ZombieDef]
}

public struct ZombieDef: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let hp: Int
    public let speed: Double
    public let damageVsBuildingsPerSec: Double
    public let damageVsUnitsPerSec: Double
    public let attackRange: Double
    public let wallBashMultiplier: Double
    public let threatCost: Int
    public let pathCostWeight: Double
    public let loot: Cost
}
