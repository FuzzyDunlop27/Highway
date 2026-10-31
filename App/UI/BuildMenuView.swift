// Purpose: Build menu: Buildings / Defenses tabs over a drawer of kit cards (picture, name, cost); tapping one starts placing it. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct BuildMenuView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case buildings = "Buildings"
        case defenses = "Defenses"
        var id: String { rawValue }
    }

    let store: GameStore
    /// Kept by the parent so the menu reopens on the last tab (handy while laying walls).
    @Binding var tab: Tab
    let onPick: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        if let content = store.content {
            let defs = tab == .buildings ? content.buildings.buildings : content.buildings.defenses
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(Tab.allCases) { tabButton($0) }
                    Spacer()
                    KitIconButton(glyph: "close", label: "Close build menu", action: onClose)
                }
                .padding(.horizontal, 10).padding(.top, 10)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(defs, id: \.id) { def in
                            card(def, canAfford: canAfford(def))
                        }
                    }
                    .padding(10)
                }
            }
            .kitPanel("ui_panel_drawer")
        }
    }

    private func tabButton(_ item: Tab) -> some View {
        let selected = item == tab
        return Button { tab = item } label: {
            Text(item.rawValue)
                .font(.subheadline.bold())
                .foregroundStyle(selected ? Kit.teal : Kit.muted)
                .padding(.horizontal, 18)
                .frame(minWidth: 110, minHeight: 36)
                .background(Kit.surface(selected ? "ui_tab_selected" : "ui_tab_normal", corner: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("buildTab_\(item)")
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
