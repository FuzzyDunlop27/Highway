// Purpose: All decoded Content/*.json in one value, with lookups by id. Notes: docs/features/core-api.md
import Foundation

/// Everything loaded from the Content folder. Create it with `ContentLoader.load(from:)`.
public struct GameContent: Sendable {
    public let resources: ResourcesContent
    public let buildings: BuildingsContent
    public let units: UnitsContent
    public let zombies: ZombiesContent
    public let hordes: HordesContent
    public let research: ResearchContent
    public let offline: OfflineContent
    public let economy: EconomyContent
    /// How the App draws things (views, tile sizes, art packs). Not used by the simulation.
    public let presentation: PresentationContent
    /// Maps by id (from `Content/maps/<id>.json`).
    public let maps: [String: MapDef]

    private let buildingIndex: [String: BuildingDef]

    public init(resources: ResourcesContent, buildings: BuildingsContent, units: UnitsContent,
                zombies: ZombiesContent, hordes: HordesContent, research: ResearchContent,
                offline: OfflineContent, economy: EconomyContent, presentation: PresentationContent,
                maps: [String: MapDef]) {
        self.resources = resources
        self.buildings = buildings
        self.units = units
        self.zombies = zombies
        self.hordes = hordes
        self.research = research
        self.offline = offline
        self.economy = economy
        self.presentation = presentation
        self.maps = maps
        var index: [String: BuildingDef] = [:]
        for def in buildings.buildings + buildings.defenses { index[def.id] = def }
        self.buildingIndex = index
    }

    /// Every placeable type, buildings first then defenses, in file order (good for a build menu).
    public var allBuildingDefs: [BuildingDef] { buildings.buildings + buildings.defenses }

    /// A building or defense definition by id (e.g. "farm", "wall_wood").
    public func buildingDef(_ id: String) -> BuildingDef? { buildingIndex[id] }

    /// Converts in-game seconds to whole simulation ticks (rounded to nearest).
    public func ticks(forSeconds seconds: Double) -> Int {
        Int((seconds * Double(economy.ticksPerSecond)).rounded())
    }
}
