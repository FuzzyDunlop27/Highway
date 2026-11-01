// Purpose: Floating bars over buildings: green progress while building/repairing, health (green/amber/red) when damaged. Notes: docs/features/rendering-art.md
import RealityKit
import UIKit
import HoldoutCore

/// One bar per building that needs one, floating just above its roof and turned like the camera, so it lies flat on the
/// screen (a billboard aims at the camera's position and looks slanted toward the screen edges).
/// Same rules as the old 2D bars: under construction → progress; finished and hurt → health; rubble or full → none.
@MainActor
final class BarsLayer3D {
    let root = Entity()
    private enum Kind: Equatable { case progress, health(Int) }
    private struct Bar { let holder: Entity; let fill: ModelEntity; var kind: Kind; var value: Float }
    private var bars: [BuildingID: Bar] = [:]

    // Look only: bar size and lift in metres, width as a share of the footprint.
    private static let widthShare: Float = 0.7
    private static let maxWidth: Float = 1.6
    private static let height: Float = 0.11
    private static let lift: Float = 0.3
    private static let trackMaterial: UnlitMaterial = {
        var m = UnlitMaterial(color: .black)
        m.blending = .transparent(opacity: 0.6)
        return m
    }()
    private var meshes: [Float: MeshResource] = [:]
    private var fills: [UIColor: UnlitMaterial] = [:]

    init() { root.name = "bars" }

    func sync(loop: GameLoop, mapping: WorldMapping3D, buildings: BuildingLayer3D, facing: simd_quatf) {
        var live = Set<BuildingID>()
        for b in loop.state.base.buildings where !b.isRubble {
            guard let def = loop.content.buildingDef(b.defId) else { continue }
            let kind: Kind, value: Double
            if !b.isComplete {
                (kind, value) = (.progress, b.constructionProgress)
            } else {
                let maxHp = def.level(b.level)?.hp ?? 0
                guard maxHp > 0, b.hp < maxHp else { continue }
                value = max(0, Double(b.hp) / Double(maxHp))
                kind = .health(value > 0.6 ? 2 : (value > 0.3 ? 1 : 0))
            }
            guard let top = buildings.topHeight(b.id) else { continue }
            live.insert(b.id)
            var bar = bars[b.id] ?? make(width: min(Float(Double(def.width) * mapping.metresPerTile) * Self.widthShare, Self.maxWidth))
            var c = Reality3DSizes.vector(mapping.footprintCenter(origin: b.origin, width: def.width, height: def.height))
            c.y = top + Self.lift
            bar.holder.position = c
            bar.holder.orientation = facing
            if bar.kind != kind {
                bar.fill.model?.materials = [fill(Self.color(kind))]
                bar.kind = kind
            }
            let v = Float(min(1, max(0.001, value)))
            if bar.value != v {
                let w = bar.fill.model?.mesh.bounds.extents.x ?? 1
                bar.fill.scale.x = v
                bar.fill.position.x = -w / 2 * (1 - v)
                bar.value = v
            }
            bars[b.id] = bar
        }
        guard bars.count != live.count else { return }
        for id in bars.keys where !live.contains(id) {
            bars.removeValue(forKey: id)?.holder.removeFromParent()
        }
    }

    private func make(width: Float) -> Bar {
        let mesh = meshes[width] ?? MeshResource.generatePlane(width: width, height: Self.height)
        meshes[width] = mesh
        let holder = Entity()
        let track = ModelEntity(mesh: mesh, materials: [Self.trackMaterial])
        let fill = ModelEntity(mesh: mesh, materials: [fill(.systemGreen)])
        fill.position.z = 0.004  // just in front of the track (+Z faces the camera)
        for e in [track, fill] {
            e.components.set(DynamicLightShadowComponent(castsShadow: false))
            holder.addChild(e)
        }
        root.addChild(holder)
        return Bar(holder: holder, fill: fill, kind: .progress, value: 1)
    }

    private func fill(_ color: UIColor) -> UnlitMaterial {
        if let m = fills[color] { return m }
        let m = UnlitMaterial(color: color)
        fills[color] = m
        return m
    }

    /// Progress green; health green when mostly healthy, amber, then red (as in 2D).
    private static func color(_ kind: Kind) -> UIColor {
        switch kind {
        case .progress, .health(2): .systemGreen
        case .health(1): .systemOrange
        default: .systemRed
        }
    }
}
