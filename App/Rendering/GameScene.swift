// Purpose: SpriteKit scene: ticks the store each frame, keeps nodes in sync with Core state, turns touches into store calls. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
final class GameScene: SKScene {
    let store: GameStore
    let art = ArtRegistry.shared
    /// Holds everything drawn in map space; rebuilt when the view changes (ViewSwitcher.swift).
    let world = SKNode()
    var style: ArtStyle?
    var cameraController: CameraController?
    var buildingNodes: [BuildingID: (signature: BuildingNodeFactory.Signature, node: SKNode)] = [:]
    var ghost: (key: GhostKey, node: SKNode)?
    var selection: (key: SelectionKey, node: SKNode)?
    var isSwitchingView = false
    private var lastUpdateTime: TimeInterval?
    private var isDraggingGhost = false

    struct GhostKey: Equatable { let defId: String; let origin: GridPoint; let check: PlacementCheck? }
    struct SelectionKey: Equatable { let id: BuildingID; let origin: GridPoint }

    init(store: GameStore) {
        self.store = store
        super.init(size: CGSize(width: 1024, height: 768))
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    required init?(coder: NSCoder) { fatalError("GameScene is created in code") }

    // MARK: Setup

    override func didMove(to view: SKView) {
        guard cameraController == nil, let loop = store.loop else { return }
        backgroundColor = ArtStyle.color(hex: loop.content.presentation.outsideMapColor)
        addChild(world)
        let kind = store.activeView
        guard let style = ArtStyle(kind: kind, content: loop.content, map: loop.map) else { return }
        let cameraController = CameraController(mapSize: style.geometry.mapSize, minScale: style.view.minScale,
                                                startScale: style.view.startScale)
        self.cameraController = cameraController
        addChild(cameraController.camera)
        camera = cameraController.camera
        apply(style)
        let start = loop.state.base.buildings.first.flatMap { b in
            loop.content.buildingDef(b.defId).map { style.geometry.center(origin: b.origin, width: $0.width, height: $0.height) }
        } ?? CGPoint(x: style.geometry.mapSize.width / 2, y: style.geometry.mapSize.height / 2)
        cameraController.center(on: start, viewSize: size)

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch)))
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        cameraController?.clamp(viewSize: size)
    }

    // MARK: Frame loop

    override func update(_ currentTime: TimeInterval) {
        let delta = lastUpdateTime.map { currentTime - $0 } ?? 0
        lastUpdateTime = currentTime
        store.advance(realSeconds: delta)
        guard let loop = store.loop, let style else { return }
        if store.activeView != style.kind && !isSwitchingView { switchView(to: store.activeView) }
        if let camera = cameraController?.camera { store.viewCenterTile = style.geometry.tile(at: camera.position) }
        syncBuildings(loop: loop, style: style)
        syncGhost(loop: loop, style: style)
        syncSelection(loop: loop, style: style)
    }

    private func syncBuildings(loop: GameLoop, style: ArtStyle) {
        var seen = Set<BuildingID>()
        for building in loop.state.base.buildings {
            seen.insert(building.id)
            let signature = BuildingNodeFactory.Signature(building)
            if let existing = buildingNodes[building.id], existing.signature == signature {
                if !building.isComplete { BuildingNodeFactory.updateProgress(existing.node, building: building) }
                continue
            }
            buildingNodes[building.id]?.node.removeFromParent()
            let node = BuildingNodeFactory.make(building, content: loop.content, style: style, art: art)
            world.addChild(node)
            buildingNodes[building.id] = (signature, node)
        }
        for id in buildingNodes.keys where !seen.contains(id) {
            buildingNodes.removeValue(forKey: id)?.node.removeFromParent()
        }
    }

    private func syncGhost(loop: GameLoop, style: ArtStyle) {
        let placement = store.placement
        guard let defId = placement.ghostDefId, let def = loop.content.buildingDef(defId) else {
            ghost?.node.removeFromParent()
            ghost = nil
            return
        }
        let key = GhostKey(defId: defId, origin: placement.ghostOrigin, check: placement.check)
        guard ghost?.key != key else { return }
        ghost?.node.removeFromParent()
        let node = GhostNodeFactory.make(def: def, origin: key.origin, check: key.check, style: style, art: art)
        world.addChild(node)
        ghost = (key, node)
    }

    private func syncSelection(loop: GameLoop, style: ArtStyle) {
        let selected = store.selectedBuilding
        let key = selected.map { SelectionKey(id: $0.id, origin: $0.origin) }
        guard selection?.key != key else { return }
        selection?.node.removeFromParent()
        selection = nil
        guard let selected, let key, let def = loop.content.buildingDef(selected.defId) else { return }
        let node = GhostNodeFactory.selectionOutline(def: def, origin: selected.origin, style: style)
        world.addChild(node)
        selection = (key, node)
    }

    // MARK: Touches

    private func tile(atViewPoint point: CGPoint) -> GridPoint? {
        style?.geometry.tile(at: convertPoint(fromView: point))
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let view, !isSwitchingView, let tile = tile(atViewPoint: gesture.location(in: view)) else { return }
        // Isometric: a tall roof covers tiles behind it, so ask what is drawn there first.
        let hit = style?.kind == .isometric
            ? HitTesting.building(at: convertPoint(fromView: gesture.location(in: view)), in: world,
                                  nodes: buildingNodes.mapValues(\.node))
            : nil
        store.tapped(tile: tile, drawnBuilding: hit)
    }

    /// One finger: drags the ghost if the touch started on it, otherwise pans the camera.
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view, let loop = store.loop, let cameraController, !isSwitchingView else { return }
        let location = gesture.location(in: view)
        switch gesture.state {
        case .began:
            let translation = gesture.translation(in: view)
            let start = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
            if let startTile = tile(atViewPoint: start), store.placement.ghostCovers(startTile, loop: loop) {
                isDraggingGhost = true
                store.placement.beginDrag(at: startTile)
            } else {
                isDraggingGhost = false
            }
            fallthrough
        case .changed:
            if isDraggingGhost {
                if let tile = tile(atViewPoint: location) { store.placement.drag(to: tile, loop: loop) }
            } else {
                cameraController.pan(byViewDelta: gesture.translation(in: view), viewSize: size)
                gesture.setTranslation(.zero, in: view)
            }
        default:
            if isDraggingGhost { store.placement.endDrag() }
            isDraggingGhost = false
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard !isSwitchingView else { return }
        cameraController?.handlePinch(gesture, in: self)
    }
}
