// Purpose: HUD buttons for game speed (pause / 1x / 2x), built from economy.json speedOptions. Notes: docs/features/hud-ui.md
import SwiftUI

struct SpeedButtonsView: View {
    let store: GameStore
    /// economy.json `speedOptions` (0 = pause); nothing about the speeds is hardcoded here.
    let options: [Int]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { speed in button(speed) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("speedButtons")
    }

    private func button(_ speed: Int) -> some View {
        let selected = store.speed == speed
        return Button { store.setSpeed(speed) } label: {
            VStack(spacing: 0) {
                KitGlyph(name: glyph(for: speed), size: 18, color: selected ? Kit.white : Kit.ink)
                if speed > 1 {
                    Text("\(speed)x").font(.system(size: 10, weight: .bold)).foregroundStyle(selected ? Kit.white : Kit.muted)
                }
            }
            .frame(width: 40, height: 40)
            .background(Kit.surface(selected ? "ui_button_primary_normal" : "ui_icon_button_normal", corner: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(speed == 0 ? "Pause" : "Speed \(speed)x")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("speed_\(speed)")
    }

    private func glyph(for speed: Int) -> String {
        switch speed {
        case 0: "pause"
        case 1: "play"
        default: "speed"
        }
    }
}
