// Purpose: The game clock: advances GameStore every screen frame, separate from drawing. Notes: docs/features/rendering-art.md
import QuartzCore
import HoldoutCore

/// Drives `GameStore.advance` from a display link, so the clock doesn't depend on the renderer (and can pause while the
/// DEBUG spike covers the game). The 3D view reads the state and takes this frame's Core events with `drainEvents()`.
@MainActor
final class GameTicker: NSObject {
    private let store: GameStore
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var pending: [SimEvent] = []
    /// Look-only safety cap: if nothing takes events (map not on screen), the oldest are dropped.
    private static let maxPendingEvents = 400

    init(store: GameStore) {
        self.store = store
    }

    func start() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(frame(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    /// Events Core produced since the last call (effects to draw). The 3D view calls this once per frame.
    func drainEvents() -> [SimEvent] {
        defer { pending.removeAll(keepingCapacity: true) }
        return pending
    }

    /// Forgets undrawn events (the 3D view was rebuilt; old effects would play in the wrong place).
    func discardEvents() { pending.removeAll() }

    @objc private func frame(_ link: CADisplayLink) {
        let delta = lastTimestamp.map { link.timestamp - $0 } ?? 0
        lastTimestamp = link.timestamp
        // Paused (e.g. the DEBUG 3D spike is covering the game): time doesn't pass, and no catch-up jump afterwards.
        guard !store.isClockPaused else { return }
        pending += store.advance(realSeconds: delta)
        if pending.count > Self.maxPendingEvents { pending.removeFirst(pending.count - Self.maxPendingEvents) }
    }
}
