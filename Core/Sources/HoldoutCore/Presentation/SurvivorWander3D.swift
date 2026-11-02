// Purpose: Look-only routes for survivors strolling around the base (open tiles only, seeded). Notes: docs/features/characters-3d.md
import Foundation

/// Which tiles a drawn survivor may walk on: on the map, not a decoration, not under any building (walls, traps and
/// towers included). Built fresh when the buildings change; never touches game state.
public struct SurvivorWalkGrid: Sendable {
    public let width: Int
    public let height: Int
    private let open: [Bool]

    public init(state: GameState, content: GameContent) {
        guard let map = content.maps[state.base.mapId] else {
            (width, height, open) = (0, 0, [])
            return
        }
        width = map.width
        height = map.height
        var open = Array(repeating: true, count: map.width * map.height)
        for p in map.decorationTiles where map.contains(p) { open[p.y * map.width + p.x] = false }
        for b in state.base.buildings {
            guard let def = content.buildingDef(b.defId) else { continue }
            for t in b.footprintTiles(def) where map.contains(t) {
                open[t.y * map.width + t.x] = false
            }
        }
        self.open = open
    }

    public func isOpen(_ p: GridPoint) -> Bool {
        p.x >= 0 && p.y >= 0 && p.x < width && p.y < height && open[p.y * width + p.x]
    }

    /// The open tile closest to `p` (ring by ring, fixed order), or nil if the map has none.
    public func nearestOpen(to p: GridPoint) -> GridPoint? {
        for r in 0...max(width, height) {
            for dy in -r...r {
                for dx in -r...r where max(abs(dx), abs(dy)) == r {
                    let q = GridPoint(x: p.x + dx, y: p.y + dy)
                    if isOpen(q) { return q }
                }
            }
        }
        return nil
    }
}

/// Picks where a strolling survivor goes next and the tiles on the way (straight steps only, so nobody cuts a corner
/// through a building).
public enum SurvivorWander3D {
    static let steps = [GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: -1, y: 0), GridPoint(x: 0, y: -1)]

    /// Tiles from `from` (excluded) to a random open tile reachable from `from` that lies within `radius` tiles of
    /// `around`. Empty if `from` isn't open or nothing else is reachable.
    public static func route(grid: SurvivorWalkGrid, from: GridPoint, around: GridPoint, radius: Int,
                             random: inout SeededRandom) -> [GridPoint] {
        guard grid.isOpen(from) else { return [] }
        var came: [GridPoint: GridPoint] = [from: from]
        var queue = [from]
        var index = 0
        var candidates: [GridPoint] = []
        while index < queue.count {
            let p = queue[index]
            index += 1
            for s in steps {
                let q = GridPoint(x: p.x + s.x, y: p.y + s.y)
                guard came[q] == nil, grid.isOpen(q),
                      max(abs(q.x - around.x), abs(q.y - around.y)) <= radius else { continue }
                came[q] = p
                queue.append(q)
                candidates.append(q)
            }
        }
        guard !candidates.isEmpty else { return [] }
        var tile = candidates[Int(random.next() % UInt64(candidates.count))]
        var path: [GridPoint] = []
        while tile != from {
            path.append(tile)
            tile = came[tile]!
        }
        return path.reversed()
    }
}
