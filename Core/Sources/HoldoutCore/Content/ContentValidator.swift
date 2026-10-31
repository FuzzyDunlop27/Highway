// Purpose: Cross-checks decoded content (ids exist, sizes match, maps are well formed). Notes: docs/features/core-api.md
import Foundation

enum ContentValidator {
    static func validate(_ c: GameContent) throws {
        try validateEconomy(c.economy)
        try validateResources(c.resources)
        try validateBuildings(c)
        try validatePresentation(c.presentation)
        if c.maps.isEmpty { throw ContentError.invalid(file: "maps/", detail: "no map files found") }
        for map in c.maps.values { try validateMap(map, content: c) }
    }

    private static func fail(_ file: String, _ detail: String) -> ContentError { .invalid(file: file, detail: detail) }

    private static func validateEconomy(_ e: EconomyContent) throws {
        if e.ticksPerSecond <= 0 { throw fail("economy.json", "ticksPerSecond must be above 0") }
        if !e.speedOptions.contains(1) { throw fail("economy.json", "speedOptions must include 1") }
        if e.speedOptions.contains(where: { $0 < 0 }) { throw fail("economy.json", "speedOptions can't be negative") }
        if e.maxFrameSeconds <= 0 { throw fail("economy.json", "maxFrameSeconds must be above 0") }
    }

    private static func validatePresentation(_ p: PresentationContent) throws {
        let file = "presentation.json"
        for kind in ProjectionKind.allCases {
            guard let view = p.view(kind) else { throw fail(file, "missing view '\(kind.rawValue)'") }
            if view.projection != kind { throw fail(file, "view '\(kind.rawValue)' must use projection '\(kind.rawValue)'") }
            if view.tileWidthPt <= 0 || view.tileHeightPt <= 0 { throw fail(file, "\(kind.rawValue): tile size must be above 0") }
            if ![1, 4, 8].contains(view.facings) || ![1, 4, 8].contains(view.turretFacings) {
                throw fail(file, "\(kind.rawValue): facings must be 1, 4 or 8")
            }
            if view.minScale <= 0 || view.startScale < view.minScale { throw fail(file, "\(kind.rawValue): need 0 < minScale <= startScale") }
            for (id, asset) in view.assets where asset.anchor.map({ $0.count != 2 }) ?? false {
                throw fail(file, "\(kind.rawValue).assets.\(id).anchor must be [x, y]")
            }
        }
        if p.switchFadeSeconds < 0 { throw fail(file, "switchFadeSeconds can't be negative") }
    }

    private static func validateResources(_ r: ResourcesContent) throws {
        for kind in ResourceKind.allCases where r.def(kind) == nil {
            throw fail("resources.json", "missing resource '\(kind.rawValue)'")
        }
        if r.resources.first(where: { $0.id == "survivors" }) == nil {
            throw fail("resources.json", "missing resource 'survivors'")
        }
        if r.foodUpkeepPerSurvivorPerMin != 0 {
            throw fail("resources.json", "foodUpkeepPerSurvivorPerMin isn't supported yet; keep it 0 (see STATUS open questions)")
        }
        if r.survivorArrival.intervalSeconds <= 0 { throw fail("resources.json", "survivorArrival.intervalSeconds must be above 0") }
    }

    private static func validateBuildings(_ c: GameContent) throws {
        let file = "buildings.json"
        let all = c.allBuildingDefs
        let ids = all.map(\.id)
        if Set(ids).count != ids.count { throw fail(file, "duplicate building ids") }
        guard let hq = c.buildingDef("hq") else { throw fail(file, "missing building 'hq'") }
        let hqLevels = hq.levels.count
        let researchIDs = Set(c.research.items.map(\.id))
        for def in all {
            if def.footprint.count != 2 || def.footprint.contains(where: { $0 <= 0 }) {
                throw fail(file, "'\(def.id)' footprint must be [width, height] above 0")
            }
            if def.maxCountByHq.count != hqLevels {
                throw fail(file, "'\(def.id)' maxCountByHq needs \(hqLevels) entries (one per HQ level)")
            }
            if def.levels.isEmpty || def.levels.map(\.level) != Array(1...def.levels.count) {
                throw fail(file, "'\(def.id)' levels must be numbered 1, 2, 3… in order")
            }
            if def.workers < 0 { throw fail(file, "'\(def.id)' workers can't be negative") }
            if let shared = def.sharesCountWith, c.buildingDef(shared) == nil {
                throw fail(file, "'\(def.id)' sharesCountWith unknown building '\(shared)'")
            }
            if let req = def.requires {
                if let b = req.building, c.buildingDef(b) == nil { throw fail(file, "'\(def.id)' requires unknown building '\(b)'") }
                if let r = req.research, !researchIDs.contains(r) { throw fail(file, "'\(def.id)' requires unknown research '\(r)'") }
            }
        }
        for entry in c.buildings.startingLayout {
            guard let def = c.buildingDef(entry.id) else { throw fail(file, "startingLayout has unknown building '\(entry.id)'") }
            if def.level(entry.level) == nil { throw fail(file, "startingLayout '\(entry.id)' has no level \(entry.level)") }
        }
    }

    private static func validateMap(_ m: MapDef, content c: GameContent) throws {
        let file = "maps/\(m.id).json"
        if m.width <= 0 || m.height <= 0 { throw fail(file, "width and height must be above 0") }
        if m.rows.count != m.height { throw fail(file, "has \(m.rows.count) rows, expected height \(m.height)") }
        if let bad = m.legend.keys.first(where: { $0.count != 1 }) { throw fail(file, "legend key '\(bad)' must be one character") }
        for (y, row) in m.rows.enumerated() {
            if row.count != m.width { throw fail(file, "row \(y) has \(row.count) tiles, expected width \(m.width)") }
            if let ch = row.first(where: { m.legend[String($0)] == nil }) { throw fail(file, "row \(y) uses '\(ch)', which is not in legend") }
        }
        for d in m.decorations {
            if d.footprint.count != 2 { throw fail(file, "decoration '\(d.id)' footprint must be [width, height]") }
            let tiles = GridPoint(x: d.x, y: d.y).footprintTiles(width: d.footprint[0], height: d.footprint[1])
            if !tiles.allSatisfy(m.contains) { throw fail(file, "decoration '\(d.id)' at (\(d.x),\(d.y)) is off the map") }
        }
        for e in m.spawnEdges {
            let tiles = GridPoint(x: e.x, y: e.y).footprintTiles(width: e.w, height: e.h)
            if e.w <= 0 || e.h <= 0 || !tiles.allSatisfy(m.contains) { throw fail(file, "spawn edge '\(e.id)' is off the map or empty") }
        }
        let edgeIDs = Set(m.spawnEdges.map(\.id))
        for id in c.hordes.spawnEdges where !edgeIDs.contains(id) {
            throw fail(file, "hordes.json spawn edge '\(id)' is not defined in this map")
        }
        for entry in c.buildings.startingLayout {
            let placed = m.startingPositions.filter { $0.id == entry.id }.count
            if placed != entry.count {
                throw fail(file, "startingPositions has \(placed) '\(entry.id)', buildings.json startingLayout expects \(entry.count)")
            }
        }
        let layoutIDs = Set(c.buildings.startingLayout.map(\.id))
        if let extra = m.startingPositions.first(where: { !layoutIDs.contains($0.id) }) {
            throw fail(file, "startingPositions has '\(extra.id)', which is not in buildings.json startingLayout")
        }
    }
}
