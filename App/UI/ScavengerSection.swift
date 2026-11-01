// Purpose: Scavenger Post panel: start a run, watch its timer, collect the reward waiting at the post. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct ScavengerSection: View {
    let store: GameStore
    let building: Building

    var body: some View {
        if let loop = store.loop, let jobs = store.jobs, let def = loop.content.buildingDef(building.defId),
           let types = def.runs?.types, let level = def.level(building.level) {
            let unlocked = level.effects.runsUnlocked ?? []
            VStack(alignment: .leading, spacing: 6) {
                if let held = building.heldReward {
                    HStack(spacing: 10) {
                        KitGlyph(name: "inventory", size: 20, color: Kit.teal)
                        Text("Waiting at the post: \(PanelFormat.gain(held))").font(.subheadline.bold()).foregroundStyle(Kit.ink)
                        Button { store.collectRun(post: building.id) } label: { KitLabel(glyph: "check", title: "Collect") }
                            .buttonStyle(KitButtonStyle(kind: .primary)).accessibilityIdentifier("collectButton")
                    }
                }
                ForEach(types, id: \.id) { run in
                    row(run, unlocked: unlocked.contains(run.id), jobs: jobs, loop: loop,
                        factor: level.effects.runRewardMultiplier ?? 1)
                }
            }
        }
    }

    private func row(_ run: ScavengingRunDef, unlocked: Bool, jobs: JobsSnapshot, loop: GameLoop, factor: Double) -> some View {
        let active = jobs.runs.first { $0.buildingId == building.id && $0.typeId == run.id }
        let reward = Cost(scrap: Int((Double(run.reward.scrap) * factor).rounded(.down)),
                          food: Int((Double(run.reward.food) * factor).rounded(.down)))
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(run.displayName).font(.subheadline.bold()).foregroundStyle(unlocked ? Kit.ink : Kit.muted)
                Text("\(PanelFormat.duration(run.durationSeconds)) · \(run.survivorsSent) survivors · costs "
                     + PlacementMessages.costText(run.cost) + " · " + PanelFormat.gain(reward))
                    .font(.caption).foregroundStyle(Kit.muted).lineLimit(1)
            }
            Spacer(minLength: 0)
            if !unlocked {
                HStack(spacing: 4) { KitGlyph(name: "lock", size: 14, color: Kit.muted); Text("Upgrade the post").font(.caption) }
                    .foregroundStyle(Kit.muted)
            } else if let active {
                KitProgressBar(value: active.timer.progress, fill: "ui_progress_amber", label: "Run").frame(width: 90)
                Text(PanelFormat.duration(Double(active.timer.secondsLeft))).font(.caption.monospacedDigit()).foregroundStyle(Kit.ink)
            } else {
                let can = loop.runProblem(buildingId: building.id, runId: run.id) == nil
                Button { store.startRun(post: building.id, runId: run.id) } label: { KitLabel(glyph: "play", title: "Send") }
                    .buttonStyle(KitButtonStyle(kind: can ? .primary : .secondary))
                    .accessibilityIdentifier("sendRun_\(run.id)")
            }
        }
    }
}
