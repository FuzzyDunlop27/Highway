// Purpose: Barracks panel: train defenders, the training queue, and each defender's post (HQ, tower, hold a spot). Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

struct BarracksSection: View {
    let store: GameStore
    let building: Building

    var body: some View {
        if let loop = store.loop, let jobs = store.jobs {
            let unit = loop.content.units.units.first { $0.training != nil }
            let effects = loop.content.buildingDef(building.defId)?.level(building.level)?.effects
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ArtIcon(id: unit?.icon ?? "icon_defender", size: 28)
                        Text("Defenders \(jobs.defenders.count + jobs.training.count)/\(effects?.maxDefenders ?? 0)")
                            .font(.subheadline.bold().monospacedDigit()).foregroundStyle(Kit.ink)
                        let canTrain = loop.trainingProblem() == nil
                        Button { store.trainDefender() } label: {
                            KitLabel(glyph: "plus", title: "Train" + (unit?.training.map { " · " + PlacementMessages.costText($0.cost) } ?? ""))
                        }
                        .buttonStyle(KitButtonStyle(kind: canTrain ? .primary : .secondary))
                        .accessibilityIdentifier("trainButton")
                    }
                    if !jobs.training.isEmpty { queue(jobs) }
                }
                .fixedSize()
                if !jobs.defenders.isEmpty { defenderList(jobs, loop: loop) }
            }
        }
    }

    private func queue(_ jobs: JobsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(jobs.training.enumerated()), id: \.offset) { index, timer in
                HStack(spacing: 8) {
                    Text(index == 0 ? "Training" : "Waiting").font(.caption).foregroundStyle(Kit.muted).frame(width: 56, alignment: .leading)
                    KitProgressBar(value: index == 0 ? timer.progress : 0, label: "Training").frame(width: 120)
                    Text(index == 0 ? PanelFormat.duration(Double(timer.secondsLeft)) : "")
                        .font(.caption.monospacedDigit()).foregroundStyle(Kit.ink)
                    Button { store.cancelTraining(index: index) } label: { KitGlyph(name: "close", size: 14, color: Kit.danger) }
                        .buttonStyle(.plain).frame(width: 32, height: 28).accessibilityLabel("Cancel training")
                }
            }
            if building.staffed < (store.content?.buildingDef(building.defId)?.workers ?? 0) {
                Text("The Barracks needs its worker before training moves.").font(.caption).foregroundStyle(Kit.danger)
            }
        }
    }

    private func defenderList(_ jobs: JobsSnapshot, loop: GameLoop) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(jobs.defenders) { d in DefenderCard(store: store, defender: d, loop: loop) }
            }
        }
    }
}

/// One defender: where it is, its health, and a menu to post it.
struct DefenderCard: View {
    let store: GameStore
    let defender: Defender
    let loop: GameLoop

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Defender \(defender.id)").font(.caption.bold()).foregroundStyle(Kit.ink)
            Text(status).font(.caption2).foregroundStyle(defender.isKnockedOut ? Kit.danger : Kit.muted)
            Menu {
                Button("Wait at the HQ") { store.recall(defender.id) }
                Button("Hold a spot…") { store.chooseSpot(for: defender.id) }
                ForEach(towers, id: \.id) { tower in
                    Button("Man \(PlacementMessages.name(tower.defId, loop.content)) (\(tower.origin.x),\(tower.origin.y))") {
                        store.garrison(defender.id, in: tower.id)
                    }
                }
            } label: {
                Text("Post…").font(.caption.bold()).foregroundStyle(Kit.white)
                    .padding(.horizontal, 12).frame(minHeight: 28).background(Kit.teal, in: Capsule())
            }
            .disabled(defender.isKnockedOut)
        }
        .padding(8)
        .background(Kit.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
    }

    private var towers: [Building] {
        let allowed = loop.content.units.units.compactMap(\.garrison).first?.allowedIn ?? []
        return loop.state.base.buildings.filter { allowed.contains($0.defId) && $0.isComplete }
    }

    private var status: String {
        let maxHp = loop.content.units.units.first { $0.id == "defender" }?.hp ?? 0
        switch defender.post {
        case .hq: return "At the HQ · \(defender.hp)/\(maxHp)"
        case .garrison(let id):
            let name = loop.state.base.building(id).map { PlacementMessages.name($0.defId, loop.content) } ?? "tower"
            return "Manning \(name) · \(defender.hp)/\(maxHp)"
        case .hold(let tile): return "Holding (\(tile.x),\(tile.y)) · \(defender.hp)/\(maxHp)"
        case .knockedOut(let ticks): return "Knocked out · \(PanelFormat.duration(Double(ticks) / Double(loop.content.economy.ticksPerSecond)))"
        }
    }
}

/// Selected tower: who is manning it, or a menu to assign a defender.
struct TowerGarrisonSection: View {
    let store: GameStore
    let building: Building

    var body: some View {
        if let loop = store.loop, let jobs = store.jobs {
            let boost = Int(((loop.content.units.units.compactMap(\.garrison).first?.towerDamageMultiplier ?? 1) - 1) * 100)
            let manning = jobs.defenders.first { $0.garrisonedIn == building.id }
            HStack(spacing: 10) {
                ArtIcon(id: "icon_defender", size: 26)
                if let manning {
                    Text("Defender \(manning.id) is manning this tower (+\(boost)% damage)").font(.subheadline).foregroundStyle(Kit.ink)
                    Button { store.recall(manning.id) } label: { KitLabel(glyph: "back", title: "Release") }
                        .buttonStyle(KitButtonStyle(kind: .secondary))
                } else {
                    let free = jobs.defenders.filter { !$0.isKnockedOut }
                    Text(free.isEmpty ? "No defenders yet. Train some at the Barracks." : "Man this tower with a defender:")
                        .font(.subheadline).foregroundStyle(Kit.muted)
                    ForEach(free.prefix(4)) { d in
                        Button { store.garrison(d.id, in: building.id) } label: { KitLabel(glyph: "shield", title: "Defender \(d.id)") }
                            .buttonStyle(KitButtonStyle(kind: .secondary))
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}
