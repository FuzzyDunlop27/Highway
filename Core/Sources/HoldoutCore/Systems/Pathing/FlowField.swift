// Purpose: Path cost from every tile to the HQ (walls cost more), so zombies flow toward weak points. Notes: docs/features/pathing.md
import Foundation

/// STUB (1B contract) — the pathing agent fills this in. Distance to the HQ for every map tile.
public struct FlowField: Sendable {
    public let width: Int
    public let height: Int
    /// Cost to reach the HQ from each tile (row-major, y * width + x); .infinity = unreachable.
    public let cost: [Double]

    /// Builds the field for zombies with `weight` (zombies.json pathCostWeight) on the base's current buildings.
    public init(state: GameState, content: GameContent, weight: Double) {
        let map = content.maps[state.base.mapId]
        width = map?.width ?? 0
        height = map?.height ?? 0
        cost = Array(repeating: 0, count: width * height)
    }

    /// Cost to the HQ from `tile` (.infinity if off the map or unreachable).
    public func distance(at tile: GridPoint) -> Double {
        guard tile.x >= 0, tile.y >= 0, tile.x < width, tile.y < height else { return .infinity }
        return cost[tile.y * width + tile.x]
    }

    /// The neighboring tile a zombie on `tile` should step to next (nil at the HQ or if stuck).
    public func nextStep(from tile: GridPoint) -> GridPoint? { nil }
}
