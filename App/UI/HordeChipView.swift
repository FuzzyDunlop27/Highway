// Purpose: HUD horde chip: "Day N · next horde 3:12", red during the warning, "Horde! 23 left" during an attack. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct HordeChipView: View {
    let store: GameStore
    #if DEBUG
    @State private var showDebug = false
    /// Launch with `-spike3DWalkers N` to open the 1R spike straight away (for measuring without touches).
    @State private var showSpike3D = UserDefaults.standard.object(forKey: "spike3DWalkers") != nil
    #endif

    var body: some View {
        if let status = store.hordeStatus {
            let alarm = status.isActive || !status.warningEdges.isEmpty
            HStack(spacing: 6) {
                KitGlyph(name: alarm ? "alert" : "clock", size: 24, color: alarm ? Kit.white : Kit.gold)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 0) {
                    Text(status.isActive ? "Horde!" : "Day \(status.day)").font(.headline).foregroundStyle(Kit.white)
                    Text(detail(status)).font(.caption2.monospacedDigit()).foregroundStyle(alarm ? Kit.white : Kit.gold)
                }
            }
            .padding(.leading, 6).padding(.trailing, 14).padding(.vertical, 4)
            .frame(minWidth: 128, alignment: .leading)
            .background {
                ZStack {
                    Kit.surface("ui_resource_chip", corner: 20)
                    if alarm { RoundedRectangle(cornerRadius: 18).fill(Kit.danger.opacity(0.9)).padding(2) }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(status.isActive ? "Horde! \(detail(status))" : "Day \(status.day) · \(detail(status))")
            .accessibilityIdentifier("hordeChip")
            #if DEBUG
            .onLongPressGesture { showDebug = true }
            .popover(isPresented: $showDebug) {
                DebugMenuView(store: store, close: { showDebug = false },
                              openSpike3D: { showDebug = false; showSpike3D = true })
                    .presentationCompactAdaptation(.popover)
            }
            .fullScreenCover(isPresented: $showSpike3D) {
                Spike3DScreen { showSpike3D = false }
            }
            .onChange(of: showSpike3D, initial: true) { store.isClockPaused = showSpike3D }  // no game time behind the spike
            #endif
        }
    }

    private func detail(_ status: HordeStatus) -> String {
        if status.isActive { return "\(status.zombiesAlive + status.zombiesToSpawn) left" }
        guard let seconds = status.secondsUntilNext else { return "no horde yet" }
        return "next horde \(Self.clock(seconds))"
    }

    /// 192.4 → "3:13" (rounded up, so it reads 0:01 until the horde arrives).
    static func clock(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}

extension HordeStatus {
    /// True when the HUD would show the same thing (the countdown only matters to the whole second), so the store
    /// doesn't make SwiftUI redraw every tick.
    func looksSameOnHUD(as other: HordeStatus?) -> Bool {
        guard let other else { return false }
        let wholeSeconds = { (s: Double?) in s.map { Int($0.rounded(.up)) } }
        return day == other.day && isActive == other.isActive && warningEdges == other.warningEdges
            && zombiesAlive == other.zombiesAlive && zombiesToSpawn == other.zombiesToSpawn
            && wholeSeconds(secondsUntilNext) == wholeSeconds(other.secondsUntilNext)
    }
}
