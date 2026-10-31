// Purpose: Switches the scene between isometric and top-down: fade out, rebuild the world, keep the same spot centered, fade in. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

extension GameScene {
    /// Draws the map for `style` from scratch; buildings, ghost, and selection are re-made on the next frame.
    func apply(_ style: ArtStyle) {
        guard let loop = store.loop else { return }
        world.removeAllChildren()
        buildingNodes.removeAll()
        ghost = nil
        selection = nil
        self.style = style
        world.addChild(TerrainNodeFactory.make(map: loop.map, style: style, art: art))
        cameraController?.configure(mapSize: style.geometry.mapSize, minScale: style.view.minScale)
    }

    /// Fades to the other view over presentation.json switchFadeSeconds, keeping the same map spot in the middle
    /// and roughly the same tiles on screen.
    func switchView(to kind: ProjectionKind) {
        guard let loop = store.loop, let old = style, let cameraController,
              let new = ArtStyle(kind: kind, content: loop.content, map: loop.map) else { return }
        isSwitchingView = true
        let center = old.geometry.grid(at: cameraController.camera.position)
        let scale = cameraController.camera.xScale * new.geometry.tileWidth / old.geometry.tileWidth
        let half = loop.content.presentation.switchFadeSeconds / 2
        let swap = SKAction.run { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.apply(new)
                cameraController.center(on: new.geometry.point(gx: center.x, gy: center.y), scale: scale, viewSize: self.size)
            }
        }
        let done = SKAction.run { [weak self] in
            MainActor.assumeIsolated { self?.isSwitchingView = false }
        }
        world.run(.sequence([.fadeOut(withDuration: half), swap, .fadeIn(withDuration: half), done]))
    }
}
