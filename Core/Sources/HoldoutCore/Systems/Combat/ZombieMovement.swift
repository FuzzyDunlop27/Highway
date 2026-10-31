// Purpose: Moves zombies along the flow field each tick; hands off to wall bashing and traps. Notes: docs/features/pathing.md
import Foundation

/// Runs every tick after HordeSystem and before TowerFiring. For each living zombie, in array order:
/// 1. traps on its tile act (Traps), 2. if something blocks it, it bashes (WallBashing),
/// 3. otherwise it walks toward the middle of the flow field's next tile at zombies.json `speed`.
/// Dead zombies are left for HordeResolution to remove; 0-hp buildings are left for it to turn to rubble.
enum ZombieMovement {
    static func tick(_ state: inout GameState, content: GameContent, fields: FlowFieldCache, events: inout [SimEvent]) {
        guard !state.base.zombies.isEmpty, let map = content.maps[state.base.mapId] else { return }
        let tps = content.economy.ticksPerSecond
        let defs = Dictionary(content.zombies.zombies.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var base = state.base
        let index = BuildingTileIndex(buildings: base.buildings, map: map, content: content)
        var fieldByWeight: [Double: FlowField] = [:]

        for zi in base.zombies.indices {
            var zombie = base.zombies[zi]
            guard zombie.hp > 0, let def = defs[zombie.defId] else { continue }
            let clock = ZombieClock(tick: state.tick, zombieID: zombie.id, ticksPerSecond: tps)
            let tile = zombie.tile

            let slow = Traps.apply(zombie: &zombie, tile: tile, index: index, buildings: &base.buildings,
                                   content: content, clock: clock, events: &events)
            if zombie.hp > 0 {
                let field: FlowField
                if let cached = fieldByWeight[def.pathCostWeight] {
                    field = cached
                } else {
                    field = fields.field(weight: def.pathCostWeight, state: state, content: content)
                    fieldByWeight[def.pathCostWeight] = field
                }
                let step = def.speed / Double(tps) * slow
                if let target = WallBashing.target(from: tile, field: field, index: index, buildings: base.buildings,
                                                        content: content) {
                    WallBashing.hit(&base.buildings[target.buildingIndex], by: def, content: content, clock: clock, events: &events)
                    zombie.attacking = base.buildings[target.buildingIndex].id
                    face(&zombie, toward: center(of: target.tile))
                    // Settle into the middle of its own tile while bashing (it may have stopped on a tile edge).
                    move(&zombie, toward: center(of: tile), by: step)
                } else if let next = field.nextStep(from: tile) {
                    zombie.attacking = nil
                    face(&zombie, toward: center(of: next))
                    move(&zombie, toward: center(of: next), by: step)
                } else {
                    zombie.attacking = nil
                }
            }
            base.zombies[zi] = zombie
        }
        state.base = base
    }

    static func center(of tile: GridPoint) -> (x: Double, y: Double) { (Double(tile.x) + 0.5, Double(tile.y) + 0.5) }

    /// Turns the zombie to look at `point` (grid-space radians: 0 = east, π/2 = south). No change if already there.
    static func face(_ zombie: inout Zombie, toward point: (x: Double, y: Double)) {
        let dx = point.x - zombie.x, dy = point.y - zombie.y
        guard dx != 0 || dy != 0 else { return }
        zombie.heading = atan2(dy, dx)
    }

    /// Moves up to `distance` tiles straight toward `point`, never past it.
    static func move(_ zombie: inout Zombie, toward point: (x: Double, y: Double), by distance: Double) {
        let dx = point.x - zombie.x, dy = point.y - zombie.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0, distance > 0 else { return }
        if distance >= length {
            zombie.x = point.x
            zombie.y = point.y
        } else {
            zombie.x += dx / length * distance
            zombie.y += dy / length * distance
        }
    }
}

/// Turns per-second rates into per-tick whole amounts for one zombie, and throttles its events.
/// Building hp is a whole number, so damage is dealt as floor((t+1)·r) − floor(t·r) per tick (r = rate/tps,
/// t = tick + zombie id): exact over every whole second for whole-number rates, no saved remainder needed.
struct ZombieClock {
    let tick: Int
    let zombieID: ZombieID
    let ticksPerSecond: Int

    private var t: Int { tick + zombieID }

    /// True about once per in-game second per zombie (staggered by id), so the App isn't spammed with events.
    var isPulse: Bool { ticksPerSecond > 0 && t % ticksPerSecond == 0 }

    /// Whole units of a `perSecond` rate that fall in this tick.
    func wholeAmount(perSecond: Double) -> Int {
        guard ticksPerSecond > 0, perSecond > 0 else { return 0 }
        let tps = Double(ticksPerSecond)
        let after = (Double(t + 1) * perSecond / tps + 1e-9).rounded(.down)
        let before = (Double(t) * perSecond / tps + 1e-9).rounded(.down)
        return Int(after - before)
    }
}

/// Which building (index into base.buildings) covers each map tile. Rubble is left out: it does nothing.
struct BuildingTileIndex {
    private let width: Int
    private let height: Int
    private var slots: [Int]

    init(buildings: [Building], map: MapDef, content: GameContent) {
        width = map.width
        height = map.height
        slots = Array(repeating: -1, count: map.width * map.height)
        for (i, b) in buildings.enumerated() where !b.isRubble {
            guard let def = content.buildingDef(b.defId) else { continue }
            for t in b.origin.footprintTiles(width: def.width, height: def.height) where map.contains(t) {
                slots[t.y * width + t.x] = i
            }
        }
    }

    func buildingIndex(at tile: GridPoint) -> Int? {
        guard tile.x >= 0, tile.y >= 0, tile.x < width, tile.y < height else { return nil }
        let i = slots[tile.y * width + tile.x]
        return i >= 0 ? i : nil
    }
}
