// Purpose: Decides when to save: on leaving the foreground and every economy.json autosaveSeconds of real time. Notes: docs/features/save.md
import SwiftUI

@MainActor
final class AppLifecycle {
    private var autosaveSeconds: Double = .infinity
    private var secondsSinceSave: Double = 0

    func configure(autosaveSeconds: Double) {
        self.autosaveSeconds = autosaveSeconds
    }

    /// Counts real frame time; returns true (and restarts the count) when an autosave is due.
    func autosaveDue(afterRealSeconds seconds: Double) -> Bool {
        secondsSinceSave += max(0, seconds)
        guard secondsSinceSave >= autosaveSeconds else { return false }
        secondsSinceSave = 0
        return true
    }

    /// Save as soon as the app stops being active (app switcher, home, lock); iOS may kill it after that.
    func handle(phase: ScenePhase, store: GameStore) {
        guard phase != .active else { return }
        store.save()
        secondsSinceSave = 0
    }
}
