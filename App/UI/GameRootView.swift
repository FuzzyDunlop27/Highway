// Purpose: Main screen: the SpriteKit map with the HUD, build menu, and placement/selection bars on top. Notes: docs/features/hud-ui.md
import SpriteKit
import SwiftUI

struct GameRootView: View {
    let store: GameStore
    @State private var scene: GameScene
    @State private var showBuildMenu = false
    @State private var buildTab = BuildMenuView.Tab.buildings

    init(store: GameStore) {
        self.store = store
        _scene = State(initialValue: GameScene(store: store))
    }

    var body: some View {
        if let error = store.loadError {
            LoadErrorView(message: error)
        } else {
            ZStack {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
                VStack(spacing: 8) {
                    HUDView(store: store)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .trailing) {
                            if !store.placement.isPositioning { ViewToggleButton(store: store) }
                        }
                    if let notice = store.notice {
                        NoticeBanner(text: notice) { store.notice = nil }
                    }
                    if let banner = store.banner {
                        HordeBannerView(store: store, banner: banner)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                    bottomBar
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .animation(.easeInOut(duration: 0.15), value: store.placement.mode)
            .animation(.easeInOut(duration: 0.15), value: showBuildMenu)
            .animation(.easeInOut(duration: 0.25), value: store.banner)
        }
    }

    @ViewBuilder private var bottomBar: some View {
        switch store.placement.mode {
        case .placing, .moving:
            PlacementBarView(store: store)
        case .selected:
            SelectionBarView(store: store)
        case .idle:
            if showBuildMenu {
                BuildMenuView(store: store, tab: $buildTab) { defId in
                    showBuildMenu = false
                    store.beginPlacing(defId: defId)
                } onClose: {
                    showBuildMenu = false
                }
            } else {
                HStack {
                    Spacer()
                    Button { showBuildMenu = true } label: { KitLabel(glyph: "build", title: "Build") }
                        .buttonStyle(KitButtonStyle(kind: .primary))
                        .accessibilityIdentifier("buildButton")
                }
            }
        }
    }
}

/// Flips between isometric and top-down. Long-press for the "top-down while building" setting.
private struct ViewToggleButton: View {
    let store: GameStore

    var body: some View {
        let isIso = store.preferredView == .isometric
        // Shows the view you'd switch to.
        KitIconButton(glyph: isIso ? "view_topdown" : "view_iso",
                      label: isIso ? "Switch to top-down view" : "Switch to isometric view") { store.toggleView() }
        .accessibilityIdentifier("viewToggle")
        .contextMenu {
            Toggle("Top-down while building", isOn: Binding(
                get: { store.autoTopDownWhilePlacing },
                set: { store.setAutoTopDownWhilePlacing($0) }))
        }
    }
}

/// An art id shown in SwiftUI (real image or labeled placeholder), drawn in its original colors.
struct ArtIcon: View {
    let id: String
    let size: CGFloat

    var body: some View {
        Image(uiImage: ArtRegistry.shared.uiImage(id))
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

private struct NoticeBanner: View {
    let text: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            KitGlyph(name: "alert", size: 18, color: Kit.danger)
            Text(text).font(.subheadline).foregroundStyle(Kit.ink)
            Button("OK", action: dismiss).font(.subheadline.bold()).foregroundStyle(Kit.teal)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .kitPanel()
    }
}

private struct LoadErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Highway Holdout couldn't start").font(.title2.bold())
            Text(message).font(.body.monospaced()).multilineTextAlignment(.center)
        }
        .padding()
    }
}
