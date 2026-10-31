// Purpose: Path cost from every tile to the HQ (walls cost more), so zombies flow toward weak points. Notes: docs/features/pathing.md
import Foundation

/// Distance to the HQ for every map tile, for zombies of one `pathCostWeight`. Dijkstra from the HQ's tiles.
/// Rules (docs/features/pathing.md): stepping onto a tile costs hordes.json `pathing.openTileCost`, plus
/// (for a standing blocking building) its hp × costPerHp × weight, in whole open-tile steps; ×√2 diagonally.
public struct FlowField: Sendable {
    public let width: Int
    public let height: Int
    /// Cost to reach the HQ from each tile (row-major, y * width + x); .infinity = unreachable.
    public let cost: [Double]
    /// Cost to step onto each tile (before the √2 diagonal factor); .infinity = impassable (decorations).
    let entry: [Double]
    /// Tiles a diagonal step may not cut past: decorations and blocking buildings (HQ included).
    let solid: [Bool]
    /// The HQ's own tiles (cost 0).
    let goal: [Bool]

    /// The building zombies walk toward.
    static let hqId = "hq"

    /// The 8 neighbor steps, straight ones first so ties prefer straight moves (fixed order = deterministic).
    static let steps: [(dx: Int, dy: Int)] = [(1, 0), (0, 1), (-1, 0), (0, -1), (1, 1), (-1, 1), (-1, -1), (1, -1)]

    /// Builds the field for zombies with `weight` (zombies.json pathCostWeight) on the base's current buildings.
    public init(state: GameState, content: GameContent, weight: Double) {
        guard let map = content.maps[state.base.mapId] else {
            (width, height, cost, entry, solid, goal) = (0, 0, [], [], [], [])
            return
        }
        width = map.width
        height = map.height
        let pathing = content.hordes.pathing
        var entry = Array(repeating: pathing.openTileCost, count: map.width * map.height)
        var solid = Array(repeating: false, count: entry.count)
        var goal = solid
        for p in map.decorationTiles where map.contains(p) {
            entry[p.y * map.width + p.x] = .infinity
            solid[p.y * map.width + p.x] = true
        }
        for b in state.base.buildings {
            guard let def = content.buildingDef(b.defId), Self.blocks(b, def: def) else { continue }
            let isHQ = b.defId == Self.hqId
            let extra = isHQ ? 0 : Self.hpCost(hp: b.hp, def: def, pathing: pathing) * weight
            for t in b.origin.footprintTiles(width: def.width, height: def.height) where map.contains(t) {
                let i = t.y * map.width + t.x
                guard entry[i].isFinite else { continue }
                solid[i] = true
                if isHQ { goal[i] = true } else { entry[i] = pathing.openTileCost + extra }
            }
        }
        self.entry = entry
        self.solid = solid
        self.goal = goal
        cost = Self.dijkstra(width: map.width, height: map.height, entry: entry, solid: solid, goal: goal)
    }

    /// Cost to the HQ from `tile` (.infinity if off the map or unreachable).
    public func distance(at tile: GridPoint) -> Double {
        guard contains(tile) else { return .infinity }
        return cost[tile.y * width + tile.x]
    }

    /// The neighboring tile a zombie on `tile` should step to next (nil at the HQ or if stuck).
    /// = the allowed neighbor with the lowest (its cost + cost to step onto it); first in `steps` order wins ties.
    public func nextStep(from tile: GridPoint) -> GridPoint? {
        guard contains(tile), !goal[tile.y * width + tile.x] else { return nil }
        var best: GridPoint?
        var bestCost = Double.infinity
        for step in Self.steps {
            let n = GridPoint(x: tile.x + step.dx, y: tile.y + step.dy)
            guard canStep(from: tile, dx: step.dx, dy: step.dy) else { continue }
            let i = n.y * width + n.x
            let total = cost[i] + entry[i] * Self.stepFactor(step.dx, step.dy)
            if total < bestCost {
                bestCost = total
                best = n
            }
        }
        return best
    }

    /// Cost to step onto `tile` straight (before the √2 diagonal factor); .infinity if impassable or off the map.
    func entryCost(at tile: GridPoint) -> Double {
        guard contains(tile) else { return .infinity }
        return entry[tile.y * width + tile.x]
    }

    func contains(_ p: GridPoint) -> Bool { p.x >= 0 && p.y >= 0 && p.x < width && p.y < height }

    /// May a zombie on `from` step by (dx, dy)? The target must be passable; a diagonal step may not cut past
    /// a solid tile (decoration or blocking building) on either side.
    func canStep(from: GridPoint, dx: Int, dy: Int) -> Bool {
        let to = GridPoint(x: from.x + dx, y: from.y + dy)
        guard contains(to), entry[to.y * width + to.x].isFinite else { return false }
        guard dx != 0, dy != 0 else { return true }
        let sideA = GridPoint(x: from.x + dx, y: from.y)
        let sideB = GridPoint(x: from.x, y: from.y + dy)
        return contains(sideA) && contains(sideB)
            && !solid[sideA.y * width + sideA.x] && !solid[sideB.y * width + sideB.x]
    }

    static func stepFactor(_ dx: Int, _ dy: Int) -> Double { dx != 0 && dy != 0 ? 2.0.squareRoot() : 1 }

    // MARK: Shared rules (also used by ZombieMovement and FlowFieldCache)

    /// Does this building stand in a zombie's way? Rubble and traps (`blocksPath: false`) don't.
    static func blocks(_ building: Building, def: BuildingDef) -> Bool {
        !building.isRubble && def.blocksPath != .open
    }

    /// Walls are the `blocksPath: "bashable"` defenses (same set as category "wall").
    static func isWall(_ def: BuildingDef) -> Bool { def.blocksPath == .bashable }

    /// How many whole open-tile steps a building's hp adds to its tile (rounded up, so any standing wall adds
    /// at least one). Rounding keeps the field a pure function of these steps, so the cache can skip rebuilds
    /// for small hp changes and a loaded save still gives identical paths.
    static func hpSteps(hp: Int, def: BuildingDef, pathing: PathingCostDef) -> Double {
        let perHp = isWall(def) ? pathing.wallTileCostPerHp : pathing.buildingTileCostPerHp
        let raw = Double(max(hp, 0)) * perHp
        guard pathing.openTileCost > 0 else { return raw }
        return max(0, (raw / pathing.openTileCost - 1e-9).rounded(.up))
    }

    /// The hp part of a blocking building tile's cost, before the zombie's weight.
    static func hpCost(hp: Int, def: BuildingDef, pathing: PathingCostDef) -> Double {
        let steps = hpSteps(hp: hp, def: def, pathing: pathing)
        return pathing.openTileCost > 0 ? steps * pathing.openTileCost : steps
    }

    // MARK: Dijkstra

    private static func dijkstra(width: Int, height: Int, entry: [Double], solid: [Bool], goal: [Bool]) -> [Double] {
        var cost = Array(repeating: Double.infinity, count: width * height)
        var heap = CostHeap()
        for i in goal.indices where goal[i] {
            cost[i] = 0
            heap.push(0, i)
        }
        // Work with a temporary field view so `canStep` (corner rule) is shared with nextStep.
        let view = FlowField(width: width, height: height, cost: [], entry: entry, solid: solid, goal: goal)
        while let (c, i) = heap.pop() {
            guard c <= cost[i] else { continue }
            let here = GridPoint(x: i % width, y: i / width)
            for step in steps {
                // Reversed search: a zombie on the neighbor `t` steps onto `here`, paying `here`'s entry cost.
                let t = GridPoint(x: here.x + step.dx, y: here.y + step.dy)
                guard view.canStep(from: here, dx: step.dx, dy: step.dy) else { continue }
                let ti = t.y * width + t.x
                guard !goal[ti] else { continue }
                let candidate = c + entry[i] * stepFactor(step.dx, step.dy)
                if candidate < cost[ti] {
                    cost[ti] = candidate
                    heap.push(candidate, ti)
                }
            }
        }
        return cost
    }

    private init(width: Int, height: Int, cost: [Double], entry: [Double], solid: [Bool], goal: [Bool]) {
        (self.width, self.height, self.cost, self.entry, self.solid, self.goal) = (width, height, cost, entry, solid, goal)
    }
}

/// Binary min-heap of (cost, tile index); ties broken by index so the search order is deterministic.
private struct CostHeap {
    private var items: [(cost: Double, index: Int)] = []

    private static func less(_ a: (cost: Double, index: Int), _ b: (cost: Double, index: Int)) -> Bool {
        a.cost < b.cost || (a.cost == b.cost && a.index < b.index)
    }

    mutating func push(_ cost: Double, _ index: Int) {
        items.append((cost, index))
        var child = items.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard Self.less(items[child], items[parent]) else { break }
            items.swapAt(child, parent)
            child = parent
        }
    }

    mutating func pop() -> (Double, Int)? {
        guard let top = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var parent = 0
            while true {
                let left = parent * 2 + 1, right = left + 1
                var smallest = parent
                if left < items.count, Self.less(items[left], items[smallest]) { smallest = left }
                if right < items.count, Self.less(items[right], items[smallest]) { smallest = right }
                guard smallest != parent else { break }
                items.swapAt(parent, smallest)
                parent = smallest
            }
        }
        return (top.cost, top.index)
    }
}
