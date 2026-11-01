// Purpose: Workshop panel: the research items (cost, time, effect), what is being researched, and what is known. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct WorkshopSection: View {
    let store: GameStore

    var body: some View {
        if let loop = store.loop, let jobs = store.jobs {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(loop.content.research.items, id: \.id) { item in row(item, jobs: jobs, loop: loop) }
            }
        }
    }

    private func row(_ item: ResearchItemDef, jobs: JobsSnapshot, loop: GameLoop) -> some View {
        let known = jobs.knowledge.contains(item.id)
        let active = jobs.research?.itemId == item.id ? jobs.research : nil
        let shop = store.selectedBuilding
        let speed = shop.flatMap { loop.content.buildingDef($0.defId)?.level($0.level)?.effects.researchSpeedMultiplier } ?? 1
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName).font(.subheadline.bold()).foregroundStyle(Kit.ink)
                Text(effectText(item.effect) + " · " + PanelFormat.duration(item.researchSeconds / max(speed, 0.01)) + " · costs "
                     + PlacementMessages.costText(item.cost) + (item.requiredHq > 1 ? " · HQ \(item.requiredHq)" : ""))
                    .font(.caption).foregroundStyle(Kit.muted).lineLimit(1)
            }
            Spacer(minLength: 0)
            if known {
                HStack(spacing: 4) { KitGlyph(name: "check", size: 14, color: Kit.teal); Text("Known").font(.caption.bold()) }
                    .foregroundStyle(Kit.teal)
            } else if let active {
                KitProgressBar(value: active.timer.progress, fill: "ui_progress_amber", label: "Research").frame(width: 90)
                Text(PanelFormat.duration(Double(active.timer.secondsLeft))).font(.caption.monospacedDigit()).foregroundStyle(Kit.ink)
            } else {
                let can = loop.researchProblem(item.id) == nil
                Button { store.startResearch(item.id) } label: { KitLabel(glyph: "star", title: "Research") }
                    .buttonStyle(KitButtonStyle(kind: can ? .primary : .secondary))
                    .accessibilityIdentifier("research_\(item.id)")
            }
        }
    }

    private func effectText(_ e: ResearchEffectDef) -> String {
        switch e.type {
        case "unlockBuilding": "Unlocks metal walls"
        case "towerRangeBonusTiles": "Towers reach +\(Int(e.value ?? 0)) tile"
        case "productionMultiplier": "Farms make +\(Int(((e.value ?? 1) - 1) * 100))% food"
        default: e.type
        }
    }
}
