// Purpose: Camera pan, pinch zoom (toward the fingers), and keeping the map in view, for whichever view is active. Notes: docs/features/input.md
import SpriteKit

@MainActor
final class CameraController {
    let camera = SKCameraNode()
    private var mapSize: CGSize
    /// Closest zoom for the current view (presentation.json minScale). Farthest = map fills the screen.
    private var minScale: CGFloat
    private var pinchStartScale: CGFloat = 1

    init(mapSize: CGSize, minScale: CGFloat, startScale: CGFloat) {
        self.mapSize = mapSize
        self.minScale = minScale
        camera.setScale(startScale)
    }

    /// Switches to another view's map size and zoom limits, keeping the camera where the caller puts it.
    func configure(mapSize: CGSize, minScale: CGFloat) {
        self.mapSize = mapSize
        self.minScale = minScale
    }

    /// Farthest zoom-out: the map fills the screen edge to edge (no empty bars; the longer side scrolls).
    func maxScale(viewSize: CGSize) -> CGFloat {
        guard viewSize.width > 0, viewSize.height > 0 else { return 1 }
        return max(minScale, min(mapSize.width / viewSize.width, mapSize.height / viewSize.height))
    }

    func center(on point: CGPoint, scale: CGFloat? = nil, viewSize: CGSize) {
        if let scale { camera.setScale(scale) }
        camera.position = point
        clamp(viewSize: viewSize)
    }

    /// Moves the camera opposite to the finger (view points; view y is down).
    func pan(byViewDelta delta: CGPoint, viewSize: CGSize) {
        camera.position.x -= delta.x * camera.xScale
        camera.position.y += delta.y * camera.yScale
        clamp(viewSize: viewSize)
    }

    func handlePinch(_ gesture: UIPinchGestureRecognizer, in scene: SKScene) {
        guard let view = scene.view else { return }
        if gesture.state == .began { pinchStartScale = camera.xScale }
        let focus = gesture.location(in: view)
        let before = scene.convertPoint(fromView: focus)
        let scale = min(max(pinchStartScale / max(gesture.scale, 0.01), minScale), maxScale(viewSize: scene.size))
        camera.setScale(scale)
        let after = scene.convertPoint(fromView: focus)
        camera.position.x += before.x - after.x
        camera.position.y += before.y - after.y
        clamp(viewSize: scene.size)
    }

    /// Keeps the visible area inside the map's box; centers the map on an axis where it is smaller than the screen.
    func clamp(viewSize: CGSize) {
        let scale = min(max(camera.xScale, minScale), maxScale(viewSize: viewSize))
        if scale != camera.xScale { camera.setScale(scale) }
        let halfW = viewSize.width * scale / 2, halfH = viewSize.height * scale / 2
        camera.position.x = halfW * 2 >= mapSize.width ? mapSize.width / 2 : min(max(camera.position.x, halfW), mapSize.width - halfW)
        camera.position.y = halfH * 2 >= mapSize.height ? mapSize.height / 2 : min(max(camera.position.y, halfH), mapSize.height - halfH)
    }
}
