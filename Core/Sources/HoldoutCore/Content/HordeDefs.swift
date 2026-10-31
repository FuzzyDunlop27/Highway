// Purpose: Codable shapes for Content/hordes.json (decoded and checked now; used from 1B). Notes: docs/features/core-api.md
import Foundation

public struct HordesContent: Codable, Sendable {
    public let schemaVersion: Int
    public let schedule: HordeScheduleDef
    public let budget: HordeBudgetDef
    public let composition: [HordeBracketDef]
    public let spawnEdges: [String]
    public let spawnIntervalSeconds: Double
    public let completionBonus: CompletionBonusDef
    public let pathing: PathingCostDef
    public let bonusHorde: BonusHordeDef
}

public struct HordeScheduleDef: Codable, Sendable {
    public let firstHordeSeconds: Double
    public let intervalSeconds: Double
    public let warningSeconds: Double
    public let clockRunsOnlyWhileAppOpen: Bool
    public let clockFrozenDuringHorde: Bool
}

public struct HordeBudgetDef: Codable, Sendable {
    public let baseBudget: Double
    public let budgetPerDay: Double
    public let townValueDivisor: Double
    public let townFactorMax: Double
}

public struct HordeBracketDef: Codable, Sendable {
    /// [firstDay, lastDay], inclusive.
    public let days: [Int]
    public let edgeCount: Int
    public let guaranteed: [String: Int]
    public let weights: [String: Int]
}

public struct CompletionBonusDef: Codable, Sendable {
    public let scrapBase: Int
    public let scrapPerDay: Int
    public let foodBase: Int
    public let foodPerDay: Int
}

public struct PathingCostDef: Codable, Sendable {
    public let openTileCost: Double
    public let wallTileCostPerHp: Double
    public let buildingTileCostPerHp: Double
}

public struct BonusHordeDef: Codable, Sendable {
    public let sizeMultiplier: Double
    public let lootMultiplier: Double
    public let usesDay: String
    public let advancesDay: Bool
    public let maxWaiting: Int
    public let waitsIndefinitely: Bool
    public let spawnEdgeCount: Int
}
