// Purpose: Upgrades old save JSON to the current version, one version step at a time. Notes: docs/features/save.md
import Foundation

enum SaveMigrations {
    /// One step: edit the raw JSON of a save at version `key` so it matches version `key + 1`.
    typealias Step = @Sendable (inout [String: Any]) throws -> Void

    /// Add an entry here whenever `SaveCodec.currentVersion` goes up. Version 1 is the first, so none yet.
    /// Example for a future v2: `1: { json in json["state"] = ... }`
    static let steps: [Int: Step] = [:]

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
