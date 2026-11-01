// Purpose: Small strip under the HUD showing build slots in use, builders, and how many jobs wait. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct BuildQueueStripView: View {
    let store: GameStore

    var body: some View {
        if let q = store.jobs?.queue, q.active + q.queued > 0 {
            HStack(spacing: 8) {
                KitGlyph(name: "build", size: 16, color: Kit.gold)
                Text("Building \(q.active)/\(q.slots)").font(.caption.bold().monospacedDigit())
                if q.queued > 0 { Text("· \(q.queued)/\(q.queueLength) waiting").font(.caption.monospacedDigit()) }
                Text("· \(q.freeBuilders) free hands").font(.caption.monospacedDigit())
            }
            .foregroundStyle(Kit.white)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(Kit.surface("ui_resource_chip", corner: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("buildQueueStrip")
        }
    }
}
