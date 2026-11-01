// Purpose: Panel above the selection bar: level badge, Upgrade, worker −/+, and the Barracks / Post / Workshop / tower sections. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct BuildingPanelView: View {
    let store: GameStore
    /// Look-only: the Barracks/Post/Workshop list scrolls past this height so the town stays visible on a phone.
    private static let sectionMaxHeight: CGFloat = 130

    var body: some View {
        if let b = store.selectedBuilding, b.isComplete, let loop = store.loop, let def = loop.content.buildingDef(b.defId) {
            let _ = store.resources  // redraw when money changes (buttons show what is affordable)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    LevelBadge(level: b.level)
                    upgradeControl(b, def: def, loop: loop)
                    Spacer(minLength: 0)
                    if def.workers > 0 { workerStepper(b, def: def) }
                }
                if hasSection(def, loop: loop) {
                    ScrollView(.vertical, showsIndicators: false) { section(b, def: def, loop: loop) }
                        .frame(maxHeight: Self.sectionMaxHeight)
                }
            }
            .padding(12)
            .kitPanel()
        }
    }

    @ViewBuilder private func upgradeControl(_ b: Building, def: BuildingDef, loop: GameLoop) -> some View {
        if let job = store.jobs?.selectedJob, job.kind == .upgrade {
            HStack(spacing: 8) {
                Text(job.started ? "Upgrading to L\(job.targetLevel)" : "Upgrade to L\(job.targetLevel) waiting")
                    .font(.subheadline.bold()).foregroundStyle(Kit.ink)
                KitProgressBar(value: job.started ? job.progress : 0, fill: "ui_progress_amber", label: "Upgrade").frame(width: 90)
            }
        } else if let cost = loop.upgradeCost(id: b.id) {
            let canDo = loop.upgradeProblem(id: b.id) == nil
            Button { store.upgradeSelected() } label: {
                KitLabel(glyph: "upgrade", title: "Upgrade to L\(b.level + 1) · \(PlacementMessages.costText(cost))")
            }
            .buttonStyle(KitButtonStyle(kind: canDo ? .primary : .secondary))
            .accessibilityIdentifier("upgradeButton")
        } else {
            Text("Top level").font(.subheadline).foregroundStyle(Kit.muted)
        }
    }

    private func workerStepper(_ b: Building, def: BuildingDef) -> some View {
        HStack(spacing: 6) {
            Text("Workers").font(.caption).foregroundStyle(Kit.muted)
            KitIconButton(glyph: "minus", label: "Fewer workers") { store.changeWorkers(by: -1) }
            Text("\(b.staffed)/\(def.workers)").font(.headline.monospacedDigit()).foregroundStyle(Kit.ink)
                .frame(minWidth: 40).accessibilityIdentifier("workerCount")
            KitIconButton(glyph: "plus", label: "More workers") { store.changeWorkers(by: 1) }
        }
    }

    private func hasSection(_ def: BuildingDef, loop: GameLoop) -> Bool {
        ["barracks", "scavenger", "workshop"].contains(def.id)
            || loop.content.units.units.compactMap(\.garrison).first?.allowedIn.contains(def.id) == true
    }

    @ViewBuilder private func section(_ b: Building, def: BuildingDef, loop: GameLoop) -> some View {
        switch def.id {
        case "barracks": BarracksSection(store: store, building: b)
        case "scavenger": ScavengerSection(store: store, building: b)
        case "workshop": WorkshopSection(store: store)
        default:
            if loop.content.units.units.compactMap(\.garrison).first?.allowedIn.contains(def.id) == true {
                TowerGarrisonSection(store: store, building: b)
            }
        }
    }
}

/// The kit's level badge with the level number, tinted by level.
struct LevelBadge: View {
    let level: Int

    var body: some View {
        ZStack {
            Image("UI/ui_level_badge").resizable().scaledToFit().colorMultiply(Kit.levelTint(level))
            Text("\(level)").font(.headline.bold()).foregroundStyle(Kit.ink)
        }
        .frame(width: 34, height: 34)
        .accessibilityLabel("Level \(level)")
    }
}

/// Small text helpers the panels share.
enum PanelFormat {
    /// 45 → "45s", 300 → "5 min", 3600 → "1 h", 5400 → "1 h 30 min".
    static func duration(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        if s < 60 { return "\(s)s" }
        if s < 3600 { return s % 60 == 0 ? "\(s / 60) min" : "\(s / 60):" + String(format: "%02d", s % 60) }
        let h = s / 3600, m = (s % 3600) / 60
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }

    /// "+60 scrap · +5 food", leaving out zero parts.
    static func gain(_ cost: Cost) -> String {
        let parts = [cost.scrap > 0 ? "+\(cost.scrap) scrap" : nil, cost.food > 0 ? "+\(cost.food) food" : nil].compactMap { $0 }
        return parts.isEmpty ? "nothing" : parts.joined(separator: " · ")
    }
}
