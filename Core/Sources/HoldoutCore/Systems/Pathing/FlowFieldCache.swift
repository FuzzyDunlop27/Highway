// Purpose: Keeps one flow field per zombie path weight and rebuilds them only when buildings change. Notes: docs/features/pathing.md
import Foundation

/// STUB (1B contract) — the pathing agent fills this in. Not saved: always derived from the state.
public final class FlowFieldCache: @unchecked Sendable {
    public init() {}

    /// The field for `weight` on the current buildings (cached until a building is added, moved, damaged, or removed).
    public func field(weight: Double, state: GameState, content: GameContent) -> FlowField {
        FlowField(state: state, content: content, weight: weight)
    }
}
