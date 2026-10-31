// Purpose: Codable shapes for Content/units.json (decoded and checked now; used from 1C). Notes: docs/features/core-api.md
import Foundation

public struct UnitsContent: Codable, Sendable {
    public let schemaVersion: Int
    public let units: [UnitDef]
    public let knockedOutSeconds: Double
}

public struct UnitDef: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let icon: String?
    public let hp: Int
    public let speed: Double
    public let canFight: Bool
    public let duringHorde: String?
    public let range: Double?
    public let damage: Double?
    public let fireRate: Double?
    public let training: TrainingDef?
    public let garrison: GarrisonDef?
}

public struct TrainingDef: Codable, Sendable {
    public let at: String
    public let consumesSurvivors: Int
    public let cost: Cost
    public let trainSeconds: Double
}

public struct GarrisonDef: Codable, Sendable {
    public let allowedIn: [String]
    public let countsAsWorker: Bool
    public let towerDamageMultiplier: Double
}
