// Purpose: Decides a horde's size and mix (budget by day and town value, composition, edges) with seeded random. Notes: docs/features/hordes.md
import Foundation

/// All formulas come from Content/hordes.json (`budget`, `composition`, `spawnEdges`; see its `_notes`).
/// Every random pick uses `state.random`, so the same seed and state give the same horde.
enum HordeComposer {
    /// Zombie types to spawn (in order) and the edges they come from.
    static func compose(day: Int, state: inout GameState, content: GameContent) -> (queue: [String], edges: [String]) {
        let edges = chooseEdges(day: day, state: &state, content: content)
        let queue = composeQueue(day: day, state: &state, content: content)
        return (queue, edges)
    }

    /// The composition bracket whose `days` range holds `day`; past the last range, the last bracket.
    static func bracket(day: Int, content: GameContent) -> HordeBracketDef? {
        let brackets = content.hordes.composition
        return brackets.first { $0.days.count == 2 && $0.days[0] <= day && day <= $0.days[1] } ?? brackets.last
    }

    /// Food + scrap invested in buildings that are still standing (not rubble). Starting buildings are free,
    /// so they add nothing (DECISIONS D-009). Stored resources never count.
    static func townValue(_ base: Base) -> Int {
        base.buildings.filter { !$0.isRubble }.reduce(0) { $0 + $1.invested.food + $1.invested.scrap }
    }

    /// round((baseBudget + budgetPerDay × (day − 1)) × clamp(1 + townValue / townValueDivisor, 1, townFactorMax)).
    static func budget(day: Int, base: Base, content: GameContent) -> Int {
        let b = content.hordes.budget
        let raw = b.baseBudget + b.budgetPerDay * Double(max(day, 1) - 1)
        let factor = b.townValueDivisor > 0 ? 1 + Double(townValue(base)) / b.townValueDivisor : 1
        return Int((raw * min(max(factor, 1), b.townFactorMax)).rounded())
    }

    /// Guaranteed zombies first (their cost comes out of the budget), then weighted random picks until
    /// nothing affordable is left. A type costing more than what remains is skipped.
    static func composeQueue(day: Int, state: inout GameState, content: GameContent) -> [String] {
        guard let bracket = bracket(day: day, content: content) else { return [] }
        let costs = Dictionary(content.zombies.zombies.map { ($0.id, $0.threatCost) }, uniquingKeysWith: { a, _ in a })
        var remaining = budget(day: day, base: state.base, content: content)
        var queue: [String] = []
        // Dictionaries have no fixed order; sort by id so the result never depends on hashing.
        for (id, count) in bracket.guaranteed.sorted(by: { $0.key < $1.key }) where costs[id] != nil {
            for _ in 0..<max(count, 0) {
                queue.append(id)
                remaining -= costs[id] ?? 0
            }
        }
        let weighted = bracket.weights.sorted { $0.key < $1.key }
        while true {
            let options = weighted.filter { id, weight in
                guard weight > 0, let cost = costs[id] else { return false }
                return cost > 0 && cost <= remaining
            }
            let total = options.reduce(0) { $0 + $1.value }
            guard total > 0 else { break }
            var roll = Self.roll(total, &state.random)
            for (id, weight) in options {
                if roll < weight {
                    queue.append(id)
                    remaining -= costs[id] ?? 0
                    break
                }
                roll -= weight
            }
        }
        return queue
    }

    /// `edgeCount` different edges, picked at random from hordes.json `spawnEdges` that exist on this map.
    static func chooseEdges(day: Int, state: inout GameState, content: GameContent) -> [String] {
        guard let map = content.maps[state.base.mapId] else { return [] }
        let onMap = Set(map.spawnEdges.map(\.id))
        var pool = content.hordes.spawnEdges.filter { onMap.contains($0) }
        let count = min(max(bracket(day: day, content: content)?.edgeCount ?? 1, 0), pool.count)
        var chosen: [String] = []
        for _ in 0..<count {
            chosen.append(pool.remove(at: roll(pool.count, &state.random)))
        }
        return chosen
    }

    /// A number in 0..<upperBound from the saved generator. Plain modulo keeps it identical on every
    /// platform and Swift version (the bias is negligible for small bounds).
    static func roll(_ upperBound: Int, _ random: inout SeededRandom) -> Int {
        guard upperBound > 1 else { return 0 }
        return Int(random.next() % UInt64(upperBound))
    }
}
