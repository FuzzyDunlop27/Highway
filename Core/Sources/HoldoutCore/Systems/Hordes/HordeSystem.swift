// Purpose: The horde clock (app-open only), the warning, and spawning zombies at the chosen edges. Notes: docs/features/hordes.md
import Foundation

/// Runs once per tick. The clock only moves inside ticks, so it advances only while the app is open
/// (and scales with game speed); it is frozen while a horde is attacking. Times from hordes.json `schedule`.
enum HordeSystem {
    static func tick(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        if state.base.horde.active != nil {
            spawnDue(&state, content: content, events: &events)
            return
        }
        let schedule = content.hordes.schedule
        var horde = state.base.horde
        // Day 1 waits firstHordeSeconds from a fresh game; later days wait intervalSeconds after the last horde ended.
        let ticksLeft = (horde.ticksUntilNext ?? content.ticks(forSeconds: horde.day > 1 ? schedule.intervalSeconds
                                                                                          : schedule.firstHordeSeconds)) - 1
        horde.ticksUntilNext = max(ticksLeft, 0)
        state.base.horde = horde

        if ticksLeft <= content.ticks(forSeconds: schedule.warningSeconds) && state.base.horde.warningEdges.isEmpty {
            let edges = HordeComposer.chooseEdges(day: horde.day, state: &state, content: content)
            state.base.horde.warningEdges = edges
            if !edges.isEmpty {
                events.append(.hordeWarning(edges: edges, seconds: Double(max(ticksLeft, 0)) / Double(content.economy.ticksPerSecond)))
            }
        }
        if ticksLeft <= 0 { start(&state, content: content, events: &events) }
    }

    /// Starts the next horde right away (debug command). Does nothing while a horde is attacking.
    static func startNow(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard state.base.horde.active == nil else { return }
        start(&state, content: content, events: &events)
    }

    /// Composes the queue (edges = the warned ones, or picked now), makes the horde active, and spawns the first wave.
    private static func start(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        let day = state.base.horde.day
        var edges = state.base.horde.warningEdges
        if edges.isEmpty { edges = HordeComposer.chooseEdges(day: day, state: &state, content: content) }
        let queue = HordeComposer.composeQueue(day: day, state: &state, content: content)
        state.base.horde.active = ActiveHorde(edges: edges, spawnQueue: queue)
        state.base.horde.warningEdges = []
        state.base.horde.ticksUntilNext = nil
        events.append(.hordeStarted(day: day, edges: edges, isBonus: false))
        spawnDue(&state, content: content, events: &events)
    }

    /// Every `spawnIntervalSeconds`, one zombie enters at each active edge (so they split evenly across edges).
    static func spawnDue(_ state: inout GameState, content: GameContent, events: inout [SimEvent]) {
        guard var active = state.base.horde.active else { return }
        if active.ticksUntilNextSpawn > 0 { active.ticksUntilNextSpawn -= 1 }
        if active.ticksUntilNextSpawn == 0 && !active.spawnQueue.isEmpty {
            let rects = edgeRects(active.edges, state: state, content: content)
            if rects.isEmpty { active.spawnQueue.removeAll() } // nowhere to enter: drop the rest rather than stall the horde
            for rect in rects where !active.spawnQueue.isEmpty {
                let defId = active.spawnQueue.removeFirst()
                if spawn(defId, in: rect, state: &state, content: content, events: &events) { active.spawned += 1 }
            }
            active.ticksUntilNextSpawn = max(1, content.ticks(forSeconds: content.hordes.spawnIntervalSeconds))
        }
        state.base.horde.active = active
    }

    /// Adds one zombie of `defId` on a random tile inside `rect`, standing in the tile's middle.
    private static func spawn(_ defId: String, in rect: SpawnEdgeDef, state: inout GameState, content: GameContent,
                              events: inout [SimEvent]) -> Bool {
        guard let def = content.zombies.zombies.first(where: { $0.id == defId }) else { return false }
        let tx = rect.x + HordeComposer.roll(max(rect.w, 1), &state.random)
        let ty = rect.y + HordeComposer.roll(max(rect.h, 1), &state.random)
        let id = state.base.horde.nextZombieID
        state.base.horde.nextZombieID += 1
        state.base.zombies.append(Zombie(id: id, defId: defId, x: Double(tx) + 0.5, y: Double(ty) + 0.5, hp: Double(def.hp)))
        events.append(.zombieSpawned(id))
        return true
    }

    /// The map rectangles for these edge ids (unknown ids are skipped).
    private static func edgeRects(_ ids: [String], state: GameState, content: GameContent) -> [SpawnEdgeDef] {
        guard let map = content.maps[state.base.mapId] else { return [] }
        return ids.compactMap { id in map.spawnEdges.first { $0.id == id } }
    }
}
