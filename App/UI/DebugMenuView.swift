// Purpose: DEBUG-only testing menu (long-press the horde chip): start a horde now, add resources, kill all zombies, open the 3D spike. Notes: docs/features/hud-ui.md
#if DEBUG
import SwiftUI
import HoldoutCore

struct DebugMenuView: View {
    let store: GameStore
    let close: () -> Void
    /// Opens the chunk 1R RealityKit spike (App/Spike3D/).
    let openSpike3D: () -> Void
    /// Testing gift only; Core clamps it to storage caps.
    private static let gift = Cost(scrap: 500, food: 500)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Debug").font(.headline).foregroundStyle(Kit.ink)
                Spacer()
                KitIconButton(glyph: "close", label: "Close debug menu", action: close)
            }
            item("Horde now", glyph: "alert", kind: .danger, command: .debugStartHorde)
            item("+\(Self.gift.food) food & scrap", glyph: "plus", kind: .primary, command: .debugAddResources(Self.gift))
            item("Kill all zombies", glyph: "demolish", kind: .secondary, command: .debugKillAllZombies)
            Button(action: openSpike3D) {
                KitLabel(glyph: "plus", title: "3D spike (1R)").frame(maxWidth: .infinity)
            }
            .buttonStyle(KitButtonStyle(kind: .secondary))
            .accessibilityIdentifier("debug_spike3d")
        }
        .padding(16)
        .frame(width: 260)
        .kitPanel()
    }

    private func item(_ title: String, glyph: String, kind: KitButtonStyle.Kind, command: Command) -> some View {
        Button {
            store.sendDebug(command)
            close()
        } label: {
            KitLabel(glyph: glyph, title: title).frame(maxWidth: .infinity)
        }
        .buttonStyle(KitButtonStyle(kind: kind))
        .accessibilityIdentifier("debug_\(title)")
    }
}
#endif
