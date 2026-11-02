// Purpose: Which way a building's front points; east/west turn its footprint a quarter. Notes: docs/features/construction.md
import Foundation

/// Which way a building's front points. South is how it is modelled and how `footprint` is written in buildings.json.
/// Same names and order as map decorations' `faces` (quarter turns from south).
public enum Facing: String, Codable, CaseIterable, Sendable {
    case south, west, north, east

    /// East and west turn the footprint a quarter, so width and height swap.
    public var swapsAxes: Bool { self == .west || self == .east }

    /// Quarter turns from south (0 = south … 3 = east), like `DecorationDef.quarterTurns`.
    public var quarterTurns: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

extension BuildingDef {
    /// True when the player may turn this building (`rotatable` in buildings.json).
    public var isRotatable: Bool { rotatable ?? false }

    /// The facing actually used: anything goes when rotatable, otherwise always south.
    public func allowedFacing(_ facing: Facing) -> Facing { isRotatable ? facing : .south }

    /// Footprint size in tiles when the building faces `facing`.
    public func size(facing: Facing) -> (width: Int, height: Int) {
        allowedFacing(facing).swapsAxes ? (height, width) : (width, height)
    }

    /// Every tile covered when the top-left tile is `origin` and it faces `facing`.
    public func footprintTiles(at origin: GridPoint, facing: Facing) -> [GridPoint] {
        let s = size(facing: facing)
        return origin.footprintTiles(width: s.width, height: s.height)
    }
}

extension Building {
    /// This building's footprint size in tiles (turned by its facing).
    public func size(_ def: BuildingDef) -> (width: Int, height: Int) { def.size(facing: facing) }

    /// Every tile this building covers (turned by its facing).
    public func footprintTiles(_ def: BuildingDef) -> [GridPoint] { def.footprintTiles(at: origin, facing: facing) }
}
