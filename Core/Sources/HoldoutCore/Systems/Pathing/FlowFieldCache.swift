// Purpose: Keeps one flow field per zombie path weight and rebuilds them only when buildings change. Notes: docs/features/pathing.md
import Foundation

/// Not saved: always derived from the state. A field depends only on the map and on each building's id,
/// type, origin, rubble state, and hp in whole path-cost steps (`FlowField.hpSteps`), so it is rebuilt only
/// when one of those changes (placed, moved, removed, turned to rubble, or damaged/repaired by a full step).
/// Use from one thread (the GameLoop's).
public final class FlowFieldCache: @unchecked Sendable {
    private var key: [Int] = []
    private var mapId = ""
    private var fields: [Double: FlowField] = [:]
    /// How many fields have been built (for tests: proves the cache skips rebuilds).
    private(set) var buildCount = 0

    public init() {}

    /// The field for `weight` on the current buildings (cached until a building is added, moved, damaged, or removed).
    public func field(weight: Double, state: GameState, content: GameContent) -> FlowField {
        let newKey = Self.key(state: state, content: content)
        if newKey != key || state.base.mapId != mapId {
            key = newKey
            mapId = state.base.mapId
            fields.removeAll(keepingCapacity: true)
        }
        if let cached = fields[weight] { return cached }
        let built = FlowField(state: state, content: content, weight: weight)
        fields[weight] = built
        buildCount += 1
        return built
    }

    /// Everything a flow field depends on, flattened (buildings are kept in a stable order in the state).
    static func key(state: GameState, content: GameContent) -> [Int] {
        var key: [Int] = []
        key.reserveCapacity(state.base.buildings.count * 6)
        for b in state.base.buildings {
            guard let def = content.buildingDef(b.defId) else { continue }
            let blocks = FlowField.blocks(b, def: def)
            // The HQ's hp never changes the field (its tiles are the goal), so it isn't part of the key.
            let counts = blocks && b.defId != FlowField.hqId
            let steps = counts ? FlowField.hpSteps(hp: b.hp, def: def, pathing: content.hordes.pathing) : 0
            // defId's hashValue is fine here: the cache lives in memory only (never saved or compared across launches).
            key += [b.id, b.defId.hashValue, b.origin.x, b.origin.y, blocks ? 1 : 0, Int(steps.rounded())]
        }
        return key
    }
}
