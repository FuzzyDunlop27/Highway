// Purpose: Cross-checks decoded content (ids exist, sizes match, maps are well formed). Notes: docs/features/core-api.md
import Foundation

enum ContentValidator {
    static func validate(_ c: GameContent) throws {
        try validateEconomy(c.economy)
        try validateResources(c.resources)
        try validateBuildings(c)
        try validatePresentation(c.presentation)
        try validateJobsAndResearch(c)
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

    private static func validateJobsAndResearch(_ c: GameContent) throws {
        for unit in c.units.units {
            if let t = unit.training, c.buildingDef(t.at) == nil { throw fail("units.json", "'\(unit.id)' trains at unknown building '\(t.at)'") }
            for id in unit.garrison?.allowedIn ?? [] where c.buildingDef(id) == nil {
                throw fail("units.json", "'\(unit.id)' garrison allowedIn unknown building '\(id)'")
            }
        }
        let effectTypes: Set = ["unlockBuilding", "towerRangeBonusTiles", "productionMultiplier"]
        for item in c.research.items {
            let e = item.effect
            if !effectTypes.contains(e.type) { throw fail("research.json", "'\(item.id)' has unknown effect type '\(e.type)'") }
            if item.researchSeconds <= 0 { throw fail("research.json", "'\(item.id)' researchSeconds must be above 0") }
            for id in [e.building].compactMap({ $0 }) + (e.towers ?? []) + (e.buildings ?? []) where c.buildingDef(id) == nil {
                throw fail("research.json", "'\(item.id)' effect names unknown building '\(id)'")
            }
        }
        for def in c.allBuildingDefs {
            let runIDs = Set(def.runs?.types.map(\.id) ?? [])
            for level in def.levels {
                for id in level.effects.runsUnlocked ?? [] where !runIDs.contains(id) {
                    throw fail("buildings.json", "'\(def.id)' level \(level.level) unlocks unknown run '\(id)'")
                }
            }
        }
    }

    private static func validatePresentation(_ p: PresentationContent) throws {
        try validateReality3D(p.reality3d)
    }

    private static func validateReality3D(_ r: Reality3DDef) throws {
        let file = "presentation.json", c = r.camera
        if r.metresPerTile <= 0 { throw fail(file, "reality3d.metresPerTile must be above 0") }
        if r.zombieBoxTiles.width <= 0 || r.zombieBoxTiles.height <= 0 { throw fail(file, "reality3d.zombieBoxTiles must be above 0") }
        let ch = r.characters
        if ch.minGlideSeconds <= 0 || ch.minGlideSeconds > ch.maxGlideSeconds || ch.turnRadiansPerSecond <= 0 || ch.maxWalkRate <= 0 {
            throw fail(file, "reality3d.characters: need 0 < minGlideSeconds <= maxGlideSeconds, turnRadiansPerSecond and maxWalkRate > 0")
        }
        for (id, v) in ch.variants where v.scale <= 0 || v.model.isEmpty {
            throw fail(file, "reality3d.characters.variants.\(id): needs a model and a scale above 0")
        }
        if c.minDistance <= 0 || c.minDistance > c.startDistance || c.startDistance > c.maxDistance {
            throw fail(file, "reality3d.camera: need 0 < minDistance <= startDistance <= maxDistance")
        }
        if c.minPitchDegrees <= 0 || c.minPitchDegrees > c.startPitchDegrees || c.startPitchDegrees > c.maxPitchDegrees
            || c.maxPitchDegrees > 90 {
            throw fail(file, "reality3d.camera: need 0 < minPitchDegrees <= startPitchDegrees <= maxPitchDegrees <= 90")
        }
        for (id, t) in r.groundTextures ?? [:] where t.file.isEmpty || t.repeatTiles <= 0 {
            throw fail(file, "reality3d.groundTextures.\(id): needs a file and a repeatTiles above 0")
        }
        if c.snapAngles < 1 { throw fail(file, "reality3d.camera.snapAngles must be at least 1") }
        if c.fieldOfViewDegrees <= 0 || c.fieldOfViewDegrees >= 180 { throw fail(file, "reality3d.camera.fieldOfViewDegrees must be 0–180") }
        if c.minHeightMetres < 0 || c.snapTurnSeconds < 0 || c.twistThresholdDegrees <= 0 || c.pinchSensitivity <= 0 {
            throw fail(file, "reality3d.camera: minHeightMetres/snapTurnSeconds >= 0, twistThresholdDegrees/pinchSensitivity > 0")
        }
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
        if c.buildings.rules.suggestSpotRadiusTiles < 0 { throw fail(file, "rules.suggestSpotRadiusTiles can't be negative") }
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
            if let f = d.faces, !DecorationDef.facings.contains(f) {
                throw fail(file, "decoration '\(d.id)' at (\(d.x),\(d.y)): faces must be south, west, north or east")
            }
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
