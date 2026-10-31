// Purpose: Bottom bars: Confirm/Cancel while placing or moving; Move/Demolish, health, and Repair/Rebuild for a selected building. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct PlacementBarView: View {
    let store: GameStore

    var body: some View {
        let placement = store.placement
        let content = store.content
        let isValid = placement.check?.isValid ?? false
        let verb = if case .moving = placement.mode { "Move" } else { "Place" }
        let name = placement.ghostDefId.flatMap { content?.buildingDef($0)?.displayName } ?? ""
        let message: String = if let problem = placement.check?.problem, let content {
            PlacementMessages.text(for: problem, content: content)
        } else {
            "Tap or drag to choose a spot."
        }
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(verb) \(name)").font(.headline).foregroundStyle(Kit.ink)
                Text(message).font(.caption).foregroundStyle(isValid ? Kit.muted : Kit.danger)
            }
            Spacer()
            Button { store.cancelPlacement() } label: { KitLabel(glyph: "close", title: "Cancel") }
                .buttonStyle(KitButtonStyle(kind: .secondary))
            Button { store.confirmPlacement() } label: { KitLabel(glyph: "check", title: "Confirm") }
                .buttonStyle(KitButtonStyle(kind: .primary))
                .disabled(!isValid)
                .accessibilityIdentifier("confirmPlacement")
        }
        .padding(14)
        .kitPanel()
    }
}

struct SelectionBarView: View {
    let store: GameStore
    @State private var confirmDemolish = false

    var body: some View {
        if let building = store.selectedBuilding, let content = store.content, let def = content.buildingDef(building.defId) {
            HStack(spacing: 12) {
                Image(uiImage: ArtRegistry.shared.menuImage(for: def))
                    .resizable().scaledToFit().frame(width: 60, height: 44)
                let maxHp = def.level(building.level)?.hp ?? 0
                let isDamaged = building.isComplete && building.hp < maxHp
                let isWreck = building.isRubble && building.constructionTicksLeft == 0
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(def.displayName) · Level \(building.level)").font(.headline).foregroundStyle(Kit.ink)
                    if isWreck {
                        Text("Destroyed").font(.caption.bold()).foregroundStyle(Kit.danger)
                    } else if !building.isComplete {
                        KitProgressBar(value: building.constructionProgress).frame(width: 140)
                    } else if isDamaged {
                        HStack(spacing: 6) {
                            KitProgressBar(value: Double(building.hp) / Double(max(maxHp, 1)), fill: "ui_progress_danger",
                                           label: "Health").frame(width: 110)
                            Text("\(building.hp)/\(maxHp)").font(.caption.monospacedDigit()).foregroundStyle(Kit.danger)
                        }
                    } else {
                        Text(def.workers > 0 ? "Workers \(building.staffed)/\(def.workers)" : "Ready")
                            .font(.caption.monospacedDigit()).foregroundStyle(Kit.muted)
                    }
                }
                Spacer()
                if isWreck || isDamaged {
                    let price = store.loop?.repairCost(id: building.id).map { " · " + PlacementMessages.costText($0) } ?? ""
                    Button { store.repairSelected() } label: {
                        KitLabel(glyph: "build", title: (isWreck ? "Rebuild" : "Repair") + price)
                    }
                        .buttonStyle(KitButtonStyle(kind: .primary))
                        .accessibilityIdentifier("repairButton")
                }
                Button { store.beginMoving() } label: { KitLabel(glyph: "move", title: "Move") }
                    .buttonStyle(KitButtonStyle(kind: .secondary))
                Button { confirmDemolish = true } label: { KitLabel(glyph: "demolish", title: "Demolish") }
                    .buttonStyle(KitButtonStyle(kind: .danger))
                KitIconButton(glyph: "close", label: "Close") { store.deselect() }
            }
            .padding(14)
            .kitPanel()
            .confirmationDialog("Demolish \(def.displayName)?", isPresented: $confirmDemolish, titleVisibility: .visible) {
                Button("Demolish", role: .destructive) { store.demolishSelected() }
            } message: {
                let refund = building.invested.percent(content.buildings.rules.demolishRefundPct)
                Text(refund == .zero ? "You get nothing back." : "You get back \(PlacementMessages.costText(refund)).")
            }
        }
    }
}

/// Kit progress bar (track + fill clipped to `value`, 0...1). `fill`: ui_progress_teal / _amber / _danger.
struct KitProgressBar: View {
    let value: Double
    var fill = "ui_progress_teal"
    var label = "Building"

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Kit.surface("ui_progress_track", corner: 6)
                Kit.surface(fill, corner: 6)
                    .frame(width: max(12, geo.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 10)
        .accessibilityLabel("\(label) \(Int(value * 100)) percent")
    }
}
