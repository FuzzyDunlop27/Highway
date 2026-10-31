// Purpose: Turns GameState into versioned save JSON and back (the App does the disk IO). Notes: docs/features/save.md
import Foundation

public enum SaveError: Error, Equatable {
    /// The data isn't a save file (not JSON or no `version`).
    case notASave
    /// Saved by a newer app version than this one understands.
    case newerVersion(Int)
    case missingMigration(from: Int)
    /// JSON had the right version but wrong contents.
    case corrupt(String)
}

/// Save file layout: `{ "version": 1, "state": { ...GameState... } }`.
public enum SaveCodec {
    public static let currentVersion = 2

    struct SaveFile: Codable {
        let version: Int
        let state: GameState
    }

    /// Encodes `state` as save JSON (sorted keys, so two saves of the same state are identical).
    public static func encode(_ state: GameState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(SaveFile(version: currentVersion, state: state))
    }

    /// Decodes save JSON from any supported version, running migrations first if it's older.
    public static func decode(_ data: Data) throws -> GameState {
        try decode(data, migrations: SaveMigrations.steps)
    }

    static func decode(_ data: Data, migrations: [Int: SaveMigrations.Step]) throws -> GameState {
        guard var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let version = json["version"] as? Int else { throw SaveError.notASave }
        if version > currentVersion { throw SaveError.newerVersion(version) }
        var payload = data
        if version < currentVersion {
            try SaveMigrations.migrate(&json, from: version, to: currentVersion, steps: migrations)
            payload = try JSONSerialization.data(withJSONObject: json)
        }
        do {
            return try JSONDecoder().decode(SaveFile.self, from: payload).state
        } catch let error as DecodingError {
            throw SaveError.corrupt(ContentLoader.describe(error))
        }
    }
}
