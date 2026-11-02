// Purpose: Draws survivors strolling around the base (look only; count from Core's roster, routes from SurvivorWander3D). Notes: docs/features/characters-3d.md
import RealityKit
import HoldoutCore

/// First look at town life (chunk 3M-2): one animated survivor per working/building/idle survivor, up to
/// presentation.json `townLife.maxVisible`. Each strolls to a random open tile near the HQ, stands a moment, and
/// strolls again; nobody walks through buildings. They all go inside (hidden) while zombies are on the map.
/// Never changes game state. Real routines (go to work, do the job) are chunk 3M-3.
@MainActor
final class SurvivorLayer3D {
    let root = Entity()
    private struct Walker {
        let entity: Entity
        var motion: CharacterMotion3D
        var animator = CharacterAnimator3D()
        var x: Double
        var y: Double
        var path: [GridPoint] = []
        var pause: Double
    }
    private var walkers: [Walker] = []
    private var grid: SurvivorWalkGrid?
    private var gridKey: [BuildingID] = []
    private var random: SeededRandom?

    init() { root.name = "survivors" }

    /// `seconds` = real time since the last frame; `gameSpeed` = 0 (paused), 1 or 2.
    func sync(loop: GameLoop, mapping: WorldMapping3D, settings: Reality3DDef, registry: ModelRegistry,
              seconds: Double, gameSpeed: Double) {
        let town = settings.townLife
        if random == nil { random = SeededRandom(seed: town.seed) }
        let base = loop.state.base
        let ids = base.buildings.map(\.id)
        if grid == nil || ids != gridKey {
            grid = SurvivorWalkGrid(state: loop.state, content: loop.content)
            gridKey = ids
        }
        guard let grid, let hq = base.buildings.first(where: { $0.defId == "hq" }),
              let hqDef = loop.content.buildingDef("hq") else { return }
        let home = GridPoint(x: hq.origin.x + hqDef.width / 2, y: hq.origin.y + hqDef.height / 2)
        let people = loop.population
        let wanted = base.zombies.isEmpty ? min(town.maxVisible, people.working + people.building + people.idle) : 0
        root.isEnabled = wanted > 0
        while walkers.count > wanted { walkers.removeLast().entity.removeFromParent() }
        while walkers.count < wanted, let walker = spawn(grid: grid, home: home, settings: settings, registry: registry) {
            walkers.append(walker)
        }
        let gameSeconds = seconds * gameSpeed
        for i in walkers.indices {
            step(&walkers[i], grid: grid, home: home, town: town, gameSeconds: gameSeconds)
            var w = walkers[i]
            let heading = w.path.first.map { atan2(Double($0.y) + 0.5 - w.y, Double($0.x) + 0.5 - w.x) } ?? w.motion.heading
            w.motion.update(toX: w.x, y: w.y, heading: heading, seconds: seconds, settings: settings.characters)
            w.entity.position = Reality3DSizes.vector(mapping.world(gx: w.motion.x, gy: w.motion.y))
            w.entity.orientation = simd_quatf(angle: Float(WorldMapping3D.yaw(heading: w.motion.heading)), axis: [0, 1, 0])
            let walking = w.motion.speed > 0
            let rate = walking ? walkRate(w, town: town, settings: settings, registry: registry) : gameSpeed
            w.animator.update(w.entity, artId: town.survivorArt, clip: walking ? .walk : .idle, rate: rate,
                              phase: Double(i) * 0.37, blendSeconds: settings.characters.clipBlendSeconds, registry: registry)
            walkers[i] = w
        }
    }

    /// A new survivor somewhere near the HQ (at the end of a random stroll from its door), waiting a random moment.
    private func spawn(grid: SurvivorWalkGrid, home: GridPoint, settings: Reality3DDef, registry: ModelRegistry) -> Walker? {
        guard var random, let door = grid.nearestOpen(to: home) else { return nil }
        let town = settings.townLife
        let spot = SurvivorWander3D.route(grid: grid, from: door, around: home, radius: town.wanderRadiusTiles,
                                          random: &random).last ?? door
        let pause = randomPause(town, &random)
        let heading = Double(random.next() % 628) / 100
        self.random = random
        let box = settings.zombieBoxTiles
        let size = SIMD3<Float>(Float(box.width), Float(box.height), Float(box.width)) * Float(settings.metresPerTile)
        let entity = registry.entity(town.survivorArt, size: size, labelMinWidth: 0.8)
        root.addChild(entity)
        let x = Double(spot.x) + 0.5, y = Double(spot.y) + 0.5
        return Walker(entity: entity, motion: CharacterMotion3D(x: x, y: y, heading: heading, settings: settings.characters),
                      x: x, y: y, pause: pause)
    }

    /// Moves one survivor along its route, or counts down its pause and then picks the next route.
    private func step(_ w: inout Walker, grid: SurvivorWalkGrid, home: GridPoint, town: TownLife3DDef, gameSeconds: Double) {
        let here = GridPoint(x: Int(w.x.rounded(.down)), y: Int(w.y.rounded(.down)))
        if !grid.isOpen(here), let free = grid.nearestOpen(to: here) {  // something was built on top of them
            (w.x, w.y, w.path) = (Double(free.x) + 0.5, Double(free.y) + 0.5, [])
        }
        var budget = gameSeconds * town.walkSpeedTiles
        while budget > 0, let next = w.path.first {
            if !grid.isOpen(next) { w.path = []; break }
            let tx = Double(next.x) + 0.5, ty = Double(next.y) + 0.5
            let dist = hypot(tx - w.x, ty - w.y)
            if dist <= budget {
                (w.x, w.y) = (tx, ty)
                budget -= dist
                w.path.removeFirst()
                if w.path.isEmpty, var random { w.pause = randomPause(town, &random); self.random = random }
            } else {
                w.x += (tx - w.x) / dist * budget
                w.y += (ty - w.y) / dist * budget
                budget = 0
            }
        }
        guard w.path.isEmpty else { return }
        w.pause -= gameSeconds
        if w.pause <= 0, var random {
            let from = GridPoint(x: Int(w.x.rounded(.down)), y: Int(w.y.rounded(.down)))
            w.path = SurvivorWander3D.route(grid: grid, from: from, around: home, radius: town.wanderRadiusTiles, random: &random)
            if w.path.isEmpty { w.pause = randomPause(town, &random) }
            self.random = random
        }
    }

    private func randomPause(_ town: TownLife3DDef, _ random: inout SeededRandom) -> Double {
        let lo = town.pauseSeconds.first ?? 1, hi = town.pauseSeconds.last ?? lo
        return lo + (hi - lo) * Double(random.next() % 1000) / 1000
    }

    /// Walk cycle at drawn speed ÷ stride, so the feet don't slide.
    private func walkRate(_ w: Walker, town: TownLife3DDef, settings: Reality3DDef, registry: ModelRegistry) -> Double {
        guard let stride = registry.strideTiles(town.survivorArt),
              let cycle = registry.clipSeconds(town.survivorArt, .walk) else { return 1 }
        return CharacterMotion3D.walkRate(speedTiles: w.motion.speed, strideTiles: stride, cycleSeconds: cycle,
                                          maxRate: settings.characters.maxWalkRate)
    }
}
