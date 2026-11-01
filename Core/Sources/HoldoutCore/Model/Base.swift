// Purpose: One town: its map, buildings, and stored food/scrap. Notes: docs/features/economy.md
import Foundation

public struct Base: Codable, Equatable, Sendable {
    /// Which map in `Content/maps/` this base sits on.
    public let mapId: String
    public var buildings: [Building]
    /// Stored food and scrap (whole units; never above the storage cap).
    public var stock: Cost
    /// Fractional production not yet turned into whole units (internal bookkeeping).
    public var productionCarry: [ResourceKind: Double]
    /// Ticks counted toward the next survivor arriving.
    public var survivorArrivalTicks: Int
    public var nextBuildingID: BuildingID
    /// Construction work in the order it was queued: running jobs (`started`) and waiting ones.
    public var jobs: [ConstructionJob]
    /// Zombies on the map right now (only during a horde).
    public var zombies: [Zombie]
    /// Horde clock, day count, and the horde in progress.
    public var horde: HordeState

    public init(mapId: String, stock: Cost) {
        self.mapId = mapId
        self.buildings = []
        self.stock = stock
        self.productionCarry = [:]
        self.survivorArrivalTicks = 0
        self.nextBuildingID = 1
        self.jobs = []
        self.zombies = []
        self.horde = .initial
    }

    public func building(_ id: BuildingID) -> Building? { buildings.first { $0.id == id } }

    /// The construction job for building `id`, if it has one (a building has at most one).
    public func job(for id: BuildingID) -> ConstructionJob? { jobs.first { $0.buildingId == id } }

    /// Level of the finished HQ, or 0 if there is none.
    public var hqLevel: Int { buildings.first { $0.defId == "hq" && $0.isComplete }?.level ?? 0 }
}
