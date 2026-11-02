// Purpose: The 3D scene: camera, dusk light, ground, decorations, buildings/zombies, effects, bars and overlays synced every frame. Notes: docs/features/rendering-art.md
import RealityKit
import UIKit
import HoldoutCore

/// Owns everything RealityView shows. It never changes game state: GameTicker runs the clock, this only reads
/// `store.loop` each frame. All numbers come from presentation.json `reality3d` (Reality3DDefs.swift).
@MainActor
final class World3D {
    let root = Entity()
    let camera = PerspectiveCamera()
    var orbit: OrbitCamera3D
    let settings: Reality3DDef
    let mapping: WorldMapping3D
    let store: GameStore
    private let ticker: GameTicker
    private let registry = ModelRegistry.shared
    let buildings = BuildingLayer3D()
    private let zombies = ZombieLayer3D()
    private let defenders = DefenderLayer3D()
    private let survivors = SurvivorLayer3D()
    let placement = PlacementLayer3D()
    private let selection = SelectionLayer3D()
    private let fader = OccluderFader3D()
    private let turrets = TurretLayer3D()
    private let bars = BarsLayer3D()
    private let effects = EffectsLayer3D()
    private let warning = HordeWarning3D()

    init?(store: GameStore, ticker: GameTicker) {
        guard let loop = store.loop else { return nil }
        self.store = store
        self.ticker = ticker
        settings = loop.content.presentation.reality3d
        mapping = WorldMapping3D(metresPerTile: settings.metresPerTile, mapWidth: loop.map.width, mapHeight: loop.map.height)
        orbit = OrbitCamera3D(settings.camera, mapping: mapping)
        registry.loadModels = settings.loadModels
        registry.modelScale = Float(settings.metresPerTile)
        registry.variants = settings.characters.variants

        camera.camera.fieldOfViewInDegrees = Float(settings.camera.fieldOfViewDegrees)
        camera.camera.far = Float(settings.camera.maxDistance * 3)
        root.addChild(camera)
        root.addChild(GroundMesh3D.make(map: loop.map, mapping: mapping, registry: registry,
                                        textures: settings.groundTextures ?? [:]))
        root.addChild(GroundMesh3D.decorations(map: loop.map, mapping: mapping, settings: settings, registry: registry))
        root.addChild(buildings.root)
        root.addChild(zombies.root)
        root.addChild(defenders.root)
        root.addChild(survivors.root)
        root.addChild(warning.root)
        root.addChild(effects.root)
        root.addChild(bars.root)
        root.addChild(selection.root)
        root.addChild(placement.root)
        addLights()
        lookAtHQ(loop)
        #if DEBUG
        // Fixed snap angle for screenshots without touches: `-debug3DSnap 2` (0–3).
        let snap = UserDefaults.standard.integer(forKey: "debug3DSnap")
        if snap != 0 { orbit.turn(steps: snap); orbit.advance(seconds: .infinity) }
        #endif
        update(dt: 0)
    }

    /// Called every rendered frame: finish any camera turn, play this frame's Core events (before the layers drop the
    /// zombies that died), then match Core's buildings and zombies, then effects, bars and overlays.
    func update(dt: Double) {
        let events = ticker.drainEvents()
        orbit.advance(seconds: dt)
        applyCamera()
        guard let loop = store.loop else { return }
        if !events.isEmpty {
            effects.play(events, loop: loop, mapping: mapping, buildings: buildings, zombies: zombies, defenders: defenders,
                         turrets: turrets)
        }
        buildings.sync(loop: loop, mapping: mapping, settings: settings, registry: registry)
        turrets.sync(loop: loop, buildings: buildings, settings: settings, registry: registry, seconds: dt)
        bars.sync(loop: loop, mapping: mapping, buildings: buildings, facing: camera.orientation)
        effects.update(seconds: dt)
        let horde = store.hordeStatus
        warning.sync(edges: horde?.isActive == false ? horde?.warningEdges ?? [] : [], map: loop.map, mapping: mapping, seconds: dt)
        zombies.sync(loop: loop, mapping: mapping, settings: settings, registry: registry, seconds: dt, gameSpeed: Double(store.speed))
        defenders.sync(loop: loop, mapping: mapping, settings: settings, registry: registry, gameSpeed: Double(store.speed))
        survivors.sync(loop: loop, mapping: mapping, settings: settings, registry: registry, seconds: dt, gameSpeed: Double(store.speed))
        placement.sync(placement: store.placement, viewCenter: store.viewCenterTile, loop: loop, mapping: mapping,
                       settings: settings, registry: registry)
        selection.sync(selected: store.selectedBuilding, range: store.selectedBuilding.flatMap { loop.towerRange(id: $0.id) },
                       content: loop.content, mapping: mapping)
        fader.sync(ghost: placement.ghostBox, eye: orbit.position, buildings: buildings, mapping: mapping)
    }

    func applyCamera() {
        let p = orbit.position
        camera.position = [Float(p.x), Float(p.y), Float(p.z)]
        camera.orientation = simd_quatf(angle: Float(orbit.yaw), axis: [0, 1, 0]) * simd_quatf(angle: Float(-orbit.pitch), axis: [1, 0, 0])
        store.viewCenterTile = mapping.tile(x: orbit.targetX, z: orbit.targetZ)
    }

    /// Starts centered on the HQ (the first building), like the 2D view.
    private func lookAtHQ(_ loop: GameLoop) {
        guard let b = loop.state.base.buildings.first, let def = loop.content.buildingDef(b.defId) else { return }
        let c = mapping.footprintCenter(origin: b.origin, width: def.width, height: def.height)
        orbit.lookAt(x: c.x, z: c.z)
    }

    private func addLights() {
        let l = settings.light
        let sun = DirectionalLight()
        sun.light.color = UIColor.hex(l.sunColor)
        sun.light.intensity = Float(l.sunIntensityLux)
        if l.shadows {
            sun.shadow = DirectionalLightComponent.Shadow(maximumDistance: Float(l.shadowMaxDistance), depthBias: Float(l.shadowDepthBias))
        }
        let elevation = l.sunElevationDegrees * .pi / 180, azimuth = l.sunAzimuthDegrees * .pi / 180
        let toSun = SIMD3<Float>(Float(cos(elevation) * sin(azimuth)), Float(sin(elevation)), Float(cos(elevation) * cos(azimuth)))
        sun.look(at: .zero, from: toSun * 30, relativeTo: nil)
        root.addChild(sun)
        let fill = DirectionalLight()
        fill.light.color = UIColor.hex(l.fillColor)
        fill.light.intensity = Float(l.fillIntensityLux)
        fill.look(at: .zero, from: [-toSun.x * 30, 20, -toSun.z * 30], relativeTo: nil)
        root.addChild(fill)
    }
}
