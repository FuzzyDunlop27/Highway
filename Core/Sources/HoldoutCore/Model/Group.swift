// Purpose: The survivor group: people and Knowledge that travel between bases. Notes: docs/features/economy.md
import Foundation

public struct Group: Codable, Equatable, Sendable {
    /// Total survivors (each one needs housing at the base).
    public var survivors: Int
    /// Finished research ids, sorted (research arrives in 1C).
    public var knowledge: [String]

    public init(survivors: Int, knowledge: [String] = []) {
        self.survivors = survivors
        self.knowledge = knowledge
    }
}
