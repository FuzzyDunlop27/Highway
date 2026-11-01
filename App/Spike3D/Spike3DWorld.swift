// Purpose: Builds the 1R spike scene (ground, study models, dusk sun, camera) and runs walkers + fps each frame. Notes: docs/plans/3d-spike-1R-results.md
#if DEBUG
import Foundation
import Observation
import RealityKit
import UIKit

/// Numbers shown on the spike's overlay, refreshed about twice a second.
@MainActor @Observable
final class Spike3DStats {
    var fps: Double = 0
    var worstFrameMs: Double = 0
    var walkers = 0
    var loadNote = "loading…"
}

@MainActor
final class Spike3DWorld {
    let root = Entity()
    let camera = PerspectiveCamera()
    let sun = DirectionalLight()
    var orbit: Spike3DOrbitCamera
    let stats: Spike3DStats
    private let config = Spike3DConfig.shared
    private var walkerTemplate: Entity?
    private var walkers: [(entity: Entity, radius: Float, angle: Float)] = []
    private var cycleSeconds: Float = 1
    private var frameTimes: [Double] = []
    private var lastStatsUpdate = 0.0
    private var clock = 0.0

    private let scene: Spike3DScene

    init(stats: Spike3DStats, scene: Spike3DScene = .study) {
        self.stats = stats
        self.scene = scene
        orbit = Spike3DOrbitCamera(Spike3DConfig.shared.camera)
        camera.camera.fieldOfViewInDegrees = config.camera.fieldOfViewDegrees
        camera.camera.far = 200
        root.addChild(camera)
        addGround()
        addLights()
        applyCamera()
    }

    func applyCamera() { camera.transform = orbit.transform }

    /// Loads the USDZ models (synchronously, timed) and places them.
    func loadModels() {
        let start = Date()
        var missing: [String] = []
        var cache: [String: Entity] = [:]
        for item in scene.layout {
            guard let model = cache[item.id] ?? (try? Entity.load(named: item.id)) else {
                missing.append(item.id)
                continue
            }
            cache[item.id] = model
            let copy = model.clone(recursive: true)
            copy.position = [item.x, item.y, item.z]
            copy.orientation = simd_quatf(angle: item.turn, axis: [0, 1, 0])
            if item.unitMetres > 0 { copy.scale = .init(repeating: item.unitMetres * config.freeAssets.metresToTiles) }
            root.addChild(copy)
        }
        let modelsMs = Date().timeIntervalSince(start) * 1000
        let walkerStart = Date()
        walkerTemplate = try? Entity.load(named: "zmb_walker_mixamo")
        let walkerMs = Date().timeIntervalSince(walkerStart) * 1000
        if let anim = walkerTemplate?.availableAnimations.first { cycleSeconds = Float(anim.definition.duration) }
        stats.loadNote = String(format: "models %.0f ms, walker %.0f ms (%@ anim %.2fs)%@", modelsMs, walkerMs,
                                walkerTemplate == nil ? "MISSING" : "ok", cycleSeconds,
                                missing.isEmpty ? "" : " missing: \(missing.joined(separator: ","))")
    }

    func setShadows(_ on: Bool) {
        sun.shadow = on ? DirectionalLightComponent.Shadow(maximumDistance: config.sun.shadowMaxDistance,
                                                           depthBias: config.sun.shadowDepthBias) : nil
    }

    /// Replaces the walker crowd with `count` copies on rings around the town.
    func setWalkers(_ count: Int) {
        walkers.forEach { $0.entity.removeFromParent() }
        walkers = []
        guard let template = walkerTemplate else { return }
        let w = config.walkers
        for i in 0..<count {
            let ring = i / w.perRing, slot = i % w.perRing
            let radius = w.innerRadius + Float(ring) * w.ringSpacing
            let angle = Float(slot) / Float(w.perRing) * 2 * .pi + Float(ring) * 0.37
            let walker = template.clone(recursive: true)
            walker.scale = .init(repeating: w.scale)
            root.addChild(walker)
            if let anim = walker.availableAnimations.first {
                let controller = walker.playAnimation(anim.repeat(), transitionDuration: 0, startsPaused: false)
                controller.time = Double(Float(i) * 0.137).truncatingRemainder(dividingBy: Double(cycleSeconds))
            }
            walkers.append((walker, radius, angle))
        }
        stats.walkers = count
        place(dt: 0)
    }

    /// Called every rendered frame with the frame's delta time.
    func update(dt: Double) {
        clock += dt
        frameTimes.append(dt)
        place(dt: Float(dt))
        if clock - lastStatsUpdate >= 0.5, !frameTimes.isEmpty {
            let total = frameTimes.reduce(0, +)
            stats.fps = Double(frameTimes.count) / max(total, 0.0001)
            stats.worstFrameMs = (frameTimes.max() ?? 0) * 1000
            frameTimes.removeAll(keepingCapacity: true)
            lastStatsUpdate = clock
            print(String(format: "SPIKE3D fps=%.1f worstMs=%.1f walkers=%d shadows=%d", stats.fps, stats.worstFrameMs, walkers.count, sun.shadow == nil ? 0 : 1))
        }
    }

    /// Walk speed = stride per animation cycle, so feet don't slide.
    private func place(dt: Float) {
        let w = config.walkers
        let speed = w.strideTiles * w.cyclesPerLoop / max(cycleSeconds, 0.01)
        for i in walkers.indices {
            walkers[i].angle += speed / walkers[i].radius * dt
            let a = walkers[i].angle, r = walkers[i].radius
            walkers[i].entity.position = [r * cos(a), 0, r * sin(a)]
            let heading = SIMD3<Float>(-sin(a), 0, cos(a))  // counter-clockwise seen from above
            walkers[i].entity.orientation = simd_quatf(angle: atan2(heading.x, heading.z), axis: [0, 1, 0])
        }
    }

    private func addGround() {
        let g = config.ground
        let dirt = PhysicallyBasedMaterial.spikeMatte(UIColor(red: 0.47, green: 0.40, blue: 0.32, alpha: 1))
        let ground = ModelEntity(mesh: .generatePlane(width: g.width, depth: g.depth), materials: [dirt])
        root.addChild(ground)
        let asphalt = PhysicallyBasedMaterial.spikeMatte(UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1))
        let road = ModelEntity(mesh: .generatePlane(width: g.width, depth: g.roadWidth), materials: [asphalt])
        road.position = [0, 0.01, g.roadZ]
        root.addChild(road)
    }

    private func addLights() {
        let s = config.sun
        sun.light.color = UIColor(red: 1.0, green: 0.78, blue: 0.55, alpha: 1)
        sun.light.intensity = s.intensityLux
        let elevation = s.elevationDegrees * .pi / 180, azimuth = s.azimuthDegrees * .pi / 180
        let toSun = SIMD3<Float>(cos(elevation) * sin(azimuth), sin(elevation), cos(elevation) * cos(azimuth))
        sun.look(at: .zero, from: toSun * 20, relativeTo: nil)
        setShadows(true)
        root.addChild(sun)
        let fill = DirectionalLight()
        fill.light.color = UIColor(red: 0.55, green: 0.62, blue: 0.85, alpha: 1)
        fill.light.intensity = config.fill.intensityLux
        fill.look(at: .zero, from: [-toSun.x * 20, 15, -toSun.z * 20], relativeTo: nil)
        root.addChild(fill)
    }
}

extension PhysicallyBasedMaterial {
    static func spikeMatte(_ color: UIColor) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: color)
        m.roughness = .init(floatLiteral: 1)
        m.metallic = .init(floatLiteral: 0)
        return m
    }
}
#endif
