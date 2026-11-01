// Purpose: Upgrades old save JSON to the current version, one version step at a time. Notes: docs/features/save.md
import Foundation

enum SaveMigrations {
    /// One step: edit the raw JSON of a save at version `key` so it matches version `key + 1`.
    typealias Step = @Sendable (inout [String: Any]) throws -> Void

    /// Add an entry here whenever `SaveCodec.currentVersion` goes up.
    static let steps: [Int: Step] = [
        // v1 → v2 (milestone 1B): bases get zombies + horde clock; buildings get isRubble.
        1: { json in
            guard var state = json["state"] as? [String: Any], var bases = state["bases"] as? [[String: Any]] else {
                throw SaveError.corrupt("v1 save has no state.bases")
            }
            for i in bases.indices {
                bases[i]["zombies"] = [Any]()
                bases[i]["horde"] = ["day": 1, "warningEdges": [Any](), "nextZombieID": 1] as [String: Any]
                if let buildings = bases[i]["buildings"] as? [[String: Any]] {
                    bases[i]["buildings"] = buildings.map { b in var b = b; b["isRubble"] = false; return b }
                }
            }
            state["bases"] = bases
            json["state"] = state
        },
        // v2 → v3 (chunk 1B): bases get a build queue. A building still under construction becomes a running
        // job (already paid, no builders borrowed), so nothing is lost or charged twice.
        2: { json in
            guard var state = json["state"] as? [String: Any], var bases = state["bases"] as? [[String: Any]] else {
                throw SaveError.corrupt("v2 save has no state.bases")
            }
            for i in bases.indices {
                let buildings = bases[i]["buildings"] as? [[String: Any]] ?? []
                bases[i]["jobs"] = buildings.compactMap { b -> [String: Any]? in
                    guard let left = b["constructionTicksLeft"] as? Int, left > 0, let id = b["id"] as? Int else { return nil }
                    return ["buildingId": id, "kind": "build", "targetLevel": b["level"] as? Int ?? 1,
                            "cost": ["scrap": 0, "food": 0], "started": true, "ticksLeft": left,
                            "ticksTotal": b["constructionTicksTotal"] as? Int ?? left, "builders": 0]
                }
            }
            state["bases"] = bases
            json["state"] = state
        },
    ]

    /// Runs every step from `version` up to `target`. Throws if a step is missing.
    static func migrate(_ json: inout [String: Any], from version: Int, to target: Int,
                        steps: [Int: Step] = steps) throws {
        var v = version
        while v < target {
            guard let step = steps[v] else { throw SaveError.missingMigration(from: v) }
            try step(&json)
            v += 1
            json["version"] = v
        }
    }
}
