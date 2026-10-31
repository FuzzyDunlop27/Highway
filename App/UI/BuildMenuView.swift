// Purpose: Build menu: a drawer of kit cards (3/4 building picture, name, cost); tapping one starts placing it. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct BuildMenuView: View {
    let store: GameStore
    let onPick: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        if let content = store.content {
            HStack(alignment: .top, spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Buildings only; defenses (walls, towers, traps) join the menu in milestone 1B.
                        ForEach(content.buildings.buildings, id: \.id) { def in
                            card(def, canAfford: canAfford(def))
                        }
                    }
                    .padding(10)
                }
                KitIconButton(glyph: "close", label: "Close build menu", action: onClose)
                    .padding(.top, 10).padding(.trailing, 10)
            }
            .kitPanel("ui_panel_drawer")
        }
    }

    private func card(_ def: BuildingDef, canAfford: Bool) -> some View {
        Button { onPick(def.id) } label: {
            VStack(spacing: 2) {
                Image(uiImage: ArtRegistry.shared.menuImage(for: def))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 68)
                Text(def.displayName).font(.caption.bold()).foregroundStyle(Kit.ink).lineLimit(1)
                Text(PlacementMessages.costText(def.levels.first?.cost ?? .zero))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(canAfford ? Kit.muted : Kit.danger)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6).padding(.vertical, 8)
            .frame(width: 108, height: 128)
            .background(Kit.surface(canAfford ? "ui_item_card_normal" : "ui_item_card_disabled", corner: 18))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("build_\(def.id)")
    }

    private func canAfford(_ def: BuildingDef) -> Bool {
        guard let r = store.resources, let cost = def.levels.first?.cost else { return true }
        return Cost(scrap: r.scrap, food: r.food).covers(cost)
    }
}
