// Purpose: Reads every Content/*.json from a folder into GameContent; throws a clear error on bad data. Notes: docs/features/core-api.md
import Foundation

public enum ContentError: Error, CustomStringConvertible, Equatable {
    case missingFile(String)
    case badJSON(file: String, detail: String)
    case invalid(file: String, detail: String)

    public var description: String {
        switch self {
        case .missingFile(let f): "Content file missing: \(f)"
        case .badJSON(let f, let d): "Content file \(f) could not be read: \(d)"
        case .invalid(let f, let d): "Content file \(f) has bad data: \(d)"
        }
    }
}

public enum ContentLoader {
    /// Loads all content from `directory` (the repo's `Content/` folder, or the App's bundled copy).
    /// Throws `ContentError` naming the file and the problem; never returns partial content.
    public static func load(from directory: URL) throws -> GameContent {
        let mapsDir = directory.appendingPathComponent("maps")
        let mapFiles = (try? FileManager.default.contentsOfDirectory(at: mapsDir, includingPropertiesForKeys: nil)) ?? []
        var maps: [String: MapDef] = [:]
        for url in mapFiles.filter({ $0.pathExtension == "json" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let map: MapDef = try decode("maps/\(url.lastPathComponent)", at: url)
            maps[map.id] = map
        }
        let content = GameContent(
            resources: try decode("resources.json", in: directory),
            buildings: try decode("buildings.json", in: directory),
            units: try decode("units.json", in: directory),
            zombies: try decode("zombies.json", in: directory),
            hordes: try decode("hordes.json", in: directory),
            research: try decode("research.json", in: directory),
            offline: try decode("offline.json", in: directory),
            economy: try decode("economy.json", in: directory),
            presentation: try decode("presentation.json", in: directory),
            maps: maps
        )
        try ContentValidator.validate(content)
        return content
    }

    static func decode<T: Decodable>(_ name: String, in directory: URL) throws -> T {
        try decode(name, at: directory.appendingPathComponent(name))
    }

    static func decode<T: Decodable>(_ name: String, at url: URL) throws -> T {
        guard let data = try? Data(contentsOf: url) else { throw ContentError.missingFile(name) }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as DecodingError {
            throw ContentError.badJSON(file: name, detail: describe(error))
        } catch {
            throw ContentError.badJSON(file: name, detail: "\(error)")
        }
    }

    /// Turns a DecodingError into "field path: what went wrong" for humans.
    static func describe(_ error: DecodingError) -> String {
        func path(_ keys: [CodingKey]) -> String {
            keys.map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }.joined(separator: ".")
        }
        switch error {
        case .keyNotFound(let key, let ctx): return "missing field '\(path(ctx.codingPath + [key]))'"
        case .typeMismatch(_, let ctx), .valueNotFound(_, let ctx), .dataCorrupted(let ctx):
            return "'\(path(ctx.codingPath))': \(ctx.debugDescription)"
        @unknown default: return "\(error)"
        }
    }
}
