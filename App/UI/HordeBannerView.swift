// Purpose: Kit-panel banner when a horde starts or ends ("Held! +X scrap", "HQ fell: −X"); hides itself after a few seconds. Notes: docs/features/hud-ui.md
import SwiftUI
import HoldoutCore

/// One banner message, made from a Core event (nil for events that don't get a banner).
struct HordeBanner: Equatable, Identifiable {
    let id: Int
    let title: String
    let detail: String
    let isBad: Bool

    init?(event: SimEvent, id: Int) {
        self.id = id
        switch event {
        case .hordeStarted(let day, _, let isBonus):
            title = isBonus ? "Bonus horde!" : "Horde!"
            detail = "Day \(day): hold the town."
            isBad = true
        case .hordeEnded(.held(let bonus)):
            title = bonus == .zero ? "Held!" : "Held! +\(Self.amounts(bonus, sign: "+"))"
            detail = "Every zombie is down."
            isBad = false
        case .hordeEnded(.hqFell(let lost)):
            title = lost == .zero ? "HQ fell" : "HQ fell: \(Self.amounts(lost, sign: "−"))"
            detail = "Repair and rebuild before the next horde."
            isBad = true
        default:
            return nil
        }
    }

    /// "+20 scrap · +10 food" style text (the first sign is added by the caller's title).
    private static func amounts(_ cost: Cost, sign: String) -> String {
        let parts = [cost.scrap > 0 ? "\(cost.scrap) scrap" : nil, cost.food > 0 ? "\(cost.food) food" : nil].compactMap { $0 }
        return parts.joined(separator: " · \(sign)")
    }
}

struct HordeBannerView: View {
    let store: GameStore
    let banner: HordeBanner
    /// How long a banner stays up (look only, not game tuning).
    private static let visibleSeconds = 4.0

    var body: some View {
        HStack(spacing: 12) {
            KitGlyph(name: banner.isBad ? "alert" : "shield", size: 28, color: banner.isBad ? Kit.danger : Kit.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title).font(.title3.bold()).foregroundStyle(banner.isBad ? Kit.danger : Kit.ink)
                Text(banner.detail).font(.subheadline).foregroundStyle(Kit.muted)
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 14)
        .kitPanel("ui_panel_dialog")
        .onTapGesture { store.dismissBanner(id: banner.id) }
        .task(id: banner.id) {
            try? await Task.sleep(for: .seconds(Self.visibleSeconds))
            store.dismissBanner(id: banner.id)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("hordeBanner")
    }
}
