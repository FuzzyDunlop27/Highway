// Purpose: Deterministic random numbers (SplitMix64) whose state is saved with the game. Notes: docs/features/core-api.md
import Foundation

/// The only source of randomness in Core. Same seed → same numbers, on every device.
public struct SeededRandom: RandomNumberGenerator, Codable, Equatable, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Saved as a string: JSON numbers can't hold every UInt64 exactly.
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let text = try c.decode(String.self)
        guard let value = UInt64(text) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "random state '\(text)' is not a number")
        }
        state = value
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(String(state))
    }
}
