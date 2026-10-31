// Purpose: Top bar: food, scrap (amount/cap, per-minute rate), survivors (count/housing, idle), and the horde chip. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct HUDView: View {
    let store: GameStore

    var body: some View {
        if let r = store.resources, let content = store.content {
            HStack(spacing: 8) {
                chip("food", content: content, amount: "\(r.food)/\(r.foodCap)", detail: rate(r.foodPerMin))
                chip("scrap", content: content, amount: "\(r.scrap)/\(r.scrapCap)", detail: rate(r.scrapPerMin))
                chip("survivors", content: content, amount: "\(r.survivors)/\(r.housing)", detail: "\(r.idleSurvivors) idle")
                HordeChipView(store: store)
            }
            .accessibilityIdentifier("hud")
        }
    }

    /// One dark kit chip. `id` is a resources.json id (food, scrap, survivors); its icon and name come from there.
    private func chip(_ id: String, content: GameContent, amount: String, detail: String) -> some View {
        let def = content.resources.resources.first { $0.id == id }
        return HStack(spacing: 6) {
            ArtIcon(id: def?.icon ?? "ui_item_\(id)", size: 34)
            VStack(alignment: .leading, spacing: 0) {
                Text(amount).font(.headline.monospacedDigit()).foregroundStyle(Kit.white)
                Text(detail).font(.caption2.monospacedDigit()).foregroundStyle(Kit.gold)
            }
        }
        .padding(.leading, 6).padding(.trailing, 14).padding(.vertical, 4)
        .frame(minWidth: 128, alignment: .leading)
        .background(Kit.surface("ui_resource_chip", corner: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(def?.displayName ?? id) \(amount), \(detail)")
    }

    private func rate(_ perMin: Double) -> String {
        perMin == 0 ? "+0/min" : String(format: "+%g/min", (perMin * 10).rounded() / 10)
    }
}
