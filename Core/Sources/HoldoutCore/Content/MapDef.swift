// Purpose: Codable shape for Content/maps/*.json and tile lookups. Notes: docs/features/construction.md
import Foundation

/// A map: a grid of tiles (row 0 = top), decorations, spawn edges, and starting building spots.
public struct MapDef: Codable, Sendable {
    public let schemaVersion: Int
    public let id: String
    public let displayName: String
    public let width: Int
    public let height: Int
    /// One character in `rows` → which tile art to draw and whether it can be built on.
    public let legend: [String: TileDef]
    /// `rows[y]` is one row of tile characters, left to right.
    public let rows: [String]
    public let decorations: [DecorationDef]
    public let spawnEdges: [SpawnEdgeDef]
    public let startingPositions: [StartingPositionDef]

    public func contains(_ p: GridPoint) -> Bool { p.x >= 0 && p.y >= 0 && p.x < width && p.y < height }

    /// The tile at `p`, or nil if `p` is off the map. (Validated on load, so in-bounds always resolves.)
    public func tile(at p: GridPoint) -> TileDef? {
        guard contains(p) else { return nil }
        let row = Array(rows[p.y])
        return legend[String(row[p.x])]
    }

    /// Tiles covered by decorations (car wrecks, trees, rubble); nothing can be built there.
    public var decorationTiles: Set<GridPoint> {
        Set(decorations.flatMap { GridPoint(x: $0.x, y: $0.y).footprintTiles(width: $0.footprint[0], height: $0.footprint[1]) })
    }
}

public struct TileDef: Codable, Sendable {
    /// Art id, e.g. `tile_asphalt` (see docs/graphics-spec-phase1.md).
    public let tile: String
    public let buildable: Bool
}

public struct DecorationDef: Codable, Sendable {
    public let id: String
    public let x: Int
    public let y: Int
    /// [width, height] it covers on the map, already turned (a 3×4 house facing east covers [4, 3]).
    public let footprint: [Int]
    /// Which way the model's front points: "south" (as modelled, the default), "west", "north" or "east". Look only.
    public let faces: String?

    /// The allowed `faces` values, in quarter turns from "south".
    public static let facings = ["south", "west", "north", "east"]

    /// Quarter turns from the modelled direction (0 = south … 3 = east); 0 when `faces` is missing.
    public var quarterTurns: Int { faces.flatMap { Self.facings.firstIndex(of: $0) } ?? 0 }
}

/// A rectangle of edge tiles where hordes enter (used from 1B).
public struct SpawnEdgeDef: Codable, Sendable {
    public let id: String
    public let x: Int
    public let y: Int
    public let w: Int
    public let h: Int
}

public struct StartingPositionDef: Codable, Sendable {
    public let id: String
    public let x: Int
    public let y: Int
}
