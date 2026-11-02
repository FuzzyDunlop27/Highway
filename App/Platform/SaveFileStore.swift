// Purpose: Reads and writes the one save file on disk (Application Support/HighwayHoldout/save.json). Notes: docs/features/save.md
import Foundation

struct SaveFileStore {
    let fileURL: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HighwayHoldout", isDirectory: true)
        fileURL = base.appendingPathComponent("save.json")
    }

    /// The saved bytes, or nil if there is no save yet.
    func read() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    /// Writes atomically, so a crash mid-write never leaves half a save.
    func write(_ data: Data) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Renames an unreadable save to save.broken-<time>.json so it isn't overwritten and can be inspected.
    func setAsideBroken() { setAside(as: "broken") }

    /// Renames the save to save.<label>-<time>.json (kept on disk, never deleted).
    func setAside(as label: String) {
        let stamp = Int(Date().timeIntervalSince1970)
        let dest = fileURL.deletingLastPathComponent().appendingPathComponent("save.\(label)-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: dest)
    }
}
