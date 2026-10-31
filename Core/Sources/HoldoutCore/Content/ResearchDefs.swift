// Purpose: Codable shapes for Content/research.json (decoded and checked now; used from 1C). Notes: docs/features/core-api.md
import Foundation

public struct ResearchContent: Codable, Sendable {
    public let schemaVersion: Int
    public let researchRequires: RequirementDef
    public let concurrentResearch: Int
    public let items: [ResearchItemDef]
}

public struct ResearchItemDef: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let cost: Cost
    public let researchSeconds: Double
    public let requiredHq: Int
    public let effect: ResearchEffectDef
}

public struct ResearchEffectDef: Codable, Sendable {
    /// unlockBuilding, towerRangeBonusTiles, or productionMultiplier.
    public let type: String
    public let building: String?
    public let towers: [String]?
    public let buildings: [String]?
    public let value: Double?
}
