// Purpose: Picks which zombie a tower shoots (nearest-to-HQ first, or nearest). Notes: docs/features/combat.md
import Foundation

/// How a tower chooses among the zombies in its range (buildings.json `targeting`).
enum TargetingMode: Equatable {
    /// `single_nearest_to_hq`: the zombie with the lowest path distance to the HQ (the most urgent one).
    case nearestToHQ
    /// `single_nearest`: the zombie physically closest to the tower.
    case nearest

    /// Reads the JSON string. Missing or unknown values behave like `single_nearest` (see combat.md).
    init(_ text: String?) {
        switch text {
        case "single_nearest_to_hq": self = .nearestToHQ
        default: self = .nearest
        }
    }
}

enum TargetingSystem {
    /// The middle of a building's footprint, in tiles (same units as `Zombie.x` / `Zombie.y`).
    static func center(of tower: Building, def: BuildingDef) -> (x: Double, y: Double) {
        (Double(tower.origin.x) + Double(def.width) / 2, Double(tower.origin.y) + Double(def.height) / 2)
    }

    /// The zombie `tower` should shoot, or nil if no living zombie (hp > 0) is within `range` tiles.
    /// Range is the straight-line distance from the footprint's middle to the zombie's position.
    /// `distanceToHQ` gives the path distance from a tile to the HQ (the flow field); it is only
    /// asked for in `single_nearest_to_hq` mode. Ties always go to the lower zombie id.
    static func target(for tower: Building, def: BuildingDef, range: Double, zombies: [Zombie],
                       distanceToHQ: (GridPoint) -> Double) -> ZombieID? {
        let mode = TargetingMode(def.targeting)
        let c = center(of: tower, def: def)
        let rangeSquared = range * range
        var best: (score: Double, id: ZombieID)?
        for z in zombies where z.hp > 0 {
            let dx = z.x - c.x, dy = z.y - c.y
            let distSquared = dx * dx + dy * dy
            guard distSquared <= rangeSquared else { continue }
            let score = mode == .nearestToHQ ? distanceToHQ(z.tile) : distSquared
            if let b = best, score > b.score || (score == b.score && z.id > b.id) { continue }
            best = (score, z.id)
        }
        return best?.id
    }
}
