// Purpose: Codable shapes for Content/resources.json, plus the shared Cost type. Notes: docs/features/economy.md
import Foundation

/// A stored resource. Survivors are not a stored resource; they are capped by housing.
public enum ResourceKind: String, Codable, CaseIterable, Sendable, CodingKeyRepresentable {
    case food, scrap
}

/// An amount of food and scrap (a price, a refund, or a stockpile).
public struct Cost: Codable, Equatable, Hashable, Sendable {
    public var scrap: Int
    public var food: Int

    public init(scrap: Int = 0, food: Int = 0) {
        self.scrap = scrap
        self.food = food
    }

    public static let zero = Cost()

    /// A missing amount in JSON (e.g. `"cost": { "food": 10 }`) means 0.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        scrap = try c.decodeIfPresent(Int.self, forKey: .scrap) ?? 0
        food = try c.decodeIfPresent(Int.self, forKey: .food) ?? 0
    }

    public subscript(kind: ResourceKind) -> Int {
        get { kind == .food ? food : scrap }
        set { if kind == .food { food = newValue } else { scrap = newValue } }
    }

    public static func + (a: Cost, b: Cost) -> Cost { Cost(scrap: a.scrap + b.scrap, food: a.food + b.food) }

    /// Each amount times `pct / 100`, rounded down.
    public func percent(_ pct: Int) -> Cost { Cost(scrap: scrap * pct / 100, food: food * pct / 100) }

    /// True when every amount in `self` is at least the matching amount in `other`.
    public func covers(_ other: Cost) -> Bool { scrap >= other.scrap && food >= other.food }
}

public struct ResourcesContent: Codable, Sendable {
    public let schemaVersion: Int
    public let resources: [ResourceDef]
    public let survivorArrival: SurvivorArrivalDef
    public let foodUpkeepPerSurvivorPerMin: Double

    /// The definition for a stored resource (food or scrap).
    public func def(_ kind: ResourceKind) -> ResourceDef? { resources.first { $0.id == kind.rawValue } }
}

public struct ResourceDef: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let icon: String
    public let starting: Int
    public let baseCap: Int
    public let capSource: String?
}

public struct SurvivorArrivalDef: Codable, Sendable {
    public let intervalSeconds: Double
    public let foodCost: Int
    public let requiresFreeHousing: Bool
    public let pausedDuringHorde: Bool
}
