// Purpose: Wall tool bar: how many walls the drawn line builds, what it costs, what is skipped; Cancel / Build. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct WallLineBarView: View {
    let store: GameStore

    var body: some View {
        let placement = store.placement
        let name = { if case .drawingLine(let id) = placement.mode { store.content?.buildingDef(id)?.displayName } else { nil } }() ?? "Wall"
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title(name, placement.linePlan)).font(.headline).foregroundStyle(Kit.ink).lineLimit(1)
                Text(detail(placement.linePlan)).font(.caption).foregroundStyle(color(placement.linePlan)).lineLimit(2)
            }
            Spacer()
            Button { store.cancelPlacement() } label: { KitLabel(glyph: "close", title: "Done") }
                .buttonStyle(KitButtonStyle(kind: .secondary))
            Button { store.confirmPlacement() } label: { KitLabel(glyph: "build", title: "Build") }
                .buttonStyle(KitButtonStyle(kind: .primary))
                .disabled(!(placement.linePlan?.canBuild ?? false))
                .accessibilityIdentifier("buildLine")
        }
        .padding(14)
        .kitPanel()
    }

    private func title(_ name: String, _ plan: LinePlan?) -> String {
        guard let plan, !plan.buildable.isEmpty else { return name }
        let n = plan.buildable.count
        return "\(n) × \(name) · \(PlacementMessages.costText(plan.cost))"
    }

    private func detail(_ plan: LinePlan?) -> String {
        guard let plan else { return "Drag along the ground to draw a wall. Two fingers move the map." }
        var parts: [String] = []
        if let problem = plan.problem, let content = store.content {
            parts.append(PlacementMessages.text(for: problem, content: content))
        }
        if !plan.blocked.isEmpty { parts.append("\(plan.blocked.count) red tile\(plan.blocked.count == 1 ? "" : "s") skipped") }
        if !plan.alreadyBuilt.isEmpty { parts.append("\(plan.alreadyBuilt.count) already built") }
        if parts.isEmpty { parts.append("Check the line, then tap Build. Drag again to redraw.") }
        return parts.joined(separator: " · ")
    }

    private func color(_ plan: LinePlan?) -> Color {
        guard let plan else { return Kit.muted }
        return plan.canBuild ? Kit.muted : Kit.danger
    }
}
