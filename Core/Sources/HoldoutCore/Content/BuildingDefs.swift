// Purpose: Codable shapes for Content/buildings.json (buildings AND defenses). Notes: docs/features/construction.md
import Foundation

public struct BuildingsContent: Codable, Sendable {
    public let schemaVersion: Int
    public let rules: ConstructionRulesDef
    public let startingLayout: [StartingLayoutEntry]
    public let buildings: [BuildingDef]
    public let defenses: [BuildingDef]
}

public struct ConstructionRulesDef: Codable, Sendable {
    public let constructionSlotsByHq: [Int]
    public let buildersPerJob: Int
    public let constructionQueueLength: Int
    public let buildDuringHorde: Bool
    /// How far (tiles) `GameLoop.suggestSpot` looks around the asked-for tile.
    public let suggestSpotRadiusTiles: Int
    public let demolishRefundPct: Int
    /// Share of a running job's cost refunded when the player cancels it (waiting jobs paid nothing).
    public let cancelRefundPct: Int
    public let repair: RepairRulesDef
    public let rubble: RubbleRulesDef
    public let constructionSprites: [String: String]
}

public struct RepairRulesDef: Codable, Sendable {
    public let costPctOfLevelCost: Int
    public let timePctOfBuildTime: Int
    public let minSeconds: Double
}

public struct RubbleRulesDef: Codable, Sendable {
    public let rebuildCostPctOfInvested: Int
    public let rebuildTimePctOfInvested: Int
    public let keepsLevel: Bool
    public let rubbleSprite2x2: String
    public let rubbleSprite1x1: String
}

public struct StartingLayoutEntry: Codable, Sendable {
    public let id: String
    public let level: Int
    public let count: Int
    public let staffed: Bool?
}

/// One building or defense type (Farm, Wood Wall, ...).
public struct BuildingDef: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let turretSprite: String?
    public let category: String
    /// [width, height] in tiles when facing south (east/west swap them; see `size(facing:)`).
    public let footprint: [Int]
    /// The player may turn it to face east/west/north (nil = no).
    public let rotatable: Bool?
    /// Survivors needed to run it at full output.
    public let workers: Int
    /// How many may exist at HQ level 1, 2, 3.
    public let maxCountByHq: [Int]
    public let blocksPath: PathBlocking?
    public let sharesCountWith: String?
    public let requires: RequirementDef?
    public let canReplace: String?
    public let targeting: String?
    public let durabilityLossPerZombieSecond: Double?
    public let levels: [LevelDef]
    public let runs: ScavengingRunsDef?

    public var width: Int { footprint[0] }
    public var height: Int { footprint[1] }

    /// The definition for `level` (1-based), or nil if it doesn't exist.
    public func level(_ level: Int) -> LevelDef? { levels.first { $0.level == level } }
}

/// `"bashable"` (zombies can break through) or `false` (zombies walk over it).
public enum PathBlocking: Codable, Equatable, Sendable {
    case bashable
    case open

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let flag = try? c.decode(Bool.self), flag == false { self = .open; return }
        let text = try c.decode(String.self)
        guard text == "bashable" else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "blocksPath must be \"bashable\" or false, got \"\(text)\"")
        }
        self = .bashable
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .bashable: try c.encode("bashable")
        case .open: try c.encode(false)
        }
    }
}

/// A prerequisite: another building at a level, or a finished research item.
public struct RequirementDef: Codable, Sendable {
    public let building: String?
    public let level: Int?
    public let research: String?
}

public struct LevelDef: Codable, Sendable {
    public let level: Int
    public let cost: Cost
    public let buildSeconds: Double
    public let hp: Int
    public let requiredHq: Int
    public let effects: EffectsDef
}

/// Every effect any building level can have. Each building uses only some of them.
public struct EffectsDef: Codable, Sendable {
    public let housing: Int?
    public let storageAdded: Int?
    public let productionPerMin: [ResourceKind: Double]?
    public let range: Double?
    public let damage: Double?
    public let fireRate: Double?
    public let slowPct: Double?
    public let dps: Double?
    public let runsUnlocked: [String]?
    public let runRewardMultiplier: Double?
    public let researchEnabled: Bool?
    public let researchSpeedMultiplier: Double?
    public let maxDefenders: Int?
    public let trainingQueueLength: Int?
    public let trainTimeMultiplier: Double?
}

public struct ScavengingRunsDef: Codable, Sendable {
    public let rewardsHeldUntilCollected: Bool
    public let types: [ScavengingRunDef]
}

public struct ScavengingRunDef: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let durationSeconds: Double
    public let survivorsSent: Int
    public let cost: Cost
    public let reward: Cost
}
