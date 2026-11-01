// Purpose: Flat see-through ground overlays for 3D placement/selection: tile squares, outlines, range ring. Notes: docs/features/input.md
import RealityKit
import UIKit
import HoldoutCore

/// Builds unlit, see-through shapes lying just above the ground. Each call returns one entity with one merged mesh,
/// so a 13×13 grid is a single draw, not 169 entities. Overlays never cast shadows.
@MainActor
enum OverlayMeshes3D {
    /// A ground rectangle in world metres.
    struct Rect { var x0, z0, x1, z1: Float }

    /// Look-only: heights above the ground (so overlays don't flicker into it) and line widths, in metres.
    static let tileLift: Float = 0.015
    static let lineLift: Float = 0.025
    static let gridLineWidth: Float = 0.03
    static let outlineWidth: Float = 0.09
    static let ringWidth: Float = 0.08
    private static let ringSegments = 96

    /// The ground rectangle of one tile, shrunk by `inset` metres on every side.
    static func tileRect(_ t: GridPoint, mapping: WorldMapping3D, inset: Float = 0) -> Rect {
        let a = mapping.world(gx: Double(t.x), gy: Double(t.y)), b = mapping.world(gx: Double(t.x + 1), gy: Double(t.y + 1))
        return Rect(x0: Float(a.x) + inset, z0: Float(a.z) + inset, x1: Float(b.x) - inset, z1: Float(b.z) - inset)
    }

    /// The four thin sides of a rectangle (an outline), each `width` wide, lying inside it.
    static func outline(_ r: Rect, width w: Float) -> [Rect] {
        [Rect(x0: r.x0, z0: r.z0, x1: r.x1, z1: r.z0 + w), Rect(x0: r.x0, z0: r.z1 - w, x1: r.x1, z1: r.z1),
         Rect(x0: r.x0, z0: r.z0 + w, x1: r.x0 + w, z1: r.z1 - w), Rect(x0: r.x1 - w, z0: r.z0 + w, x1: r.x1, z1: r.z1 - w)]
    }

    /// Flat rectangles merged into one entity, `lift` metres up. Nil when there is nothing to draw.
    static func rects(_ rects: [Rect], color: UIColor, alpha: Float, lift: Float = tileLift) -> Entity? {
        guard !rects.isEmpty else { return nil }
        var positions: [SIMD3<Float>] = [], indices: [UInt32] = []
        for r in rects {
            let base = UInt32(positions.count)
            positions += [[r.x0, lift, r.z0], [r.x0, lift, r.z1], [r.x1, lift, r.z1], [r.x1, lift, r.z0]]
            indices += [base, base + 1, base + 2, base, base + 2, base + 3]  // counter-clockwise from above
        }
        return model(positions: positions, indices: indices, color: color, alpha: alpha)
    }

    /// A flat ring of radius `radius` metres (to the ring's middle) around ground point `center`, plus an optional
    /// faint filled disc inside it.
    static func ring(center: SIMD3<Float>, radius: Float, color: UIColor, alpha: Float, fillAlpha: Float) -> Entity {
        let root = Entity()
        let n = ringSegments
        let inner = max(radius - ringWidth / 2, 0), outer = radius + ringWidth / 2
        var positions: [SIMD3<Float>] = [], indices: [UInt32] = []
        var disc: [SIMD3<Float>] = [[center.x, tileLift, center.z]], discIndices: [UInt32] = []
        for i in 0..<n {
            let a = Float(i) / Float(n) * 2 * .pi
            let (s, c) = (sin(a), cos(a))
            positions += [[center.x + c * inner, lineLift, center.z + s * inner], [center.x + c * outer, lineLift, center.z + s * outer]]
            disc.append([center.x + c * inner, tileLift, center.z + s * inner])
            let k = UInt32(i * 2), next = UInt32(((i + 1) % n) * 2)
            indices += [k, next, k + 1, k + 1, next, next + 1]  // counter-clockwise from above (+z is south)
            discIndices += [0, UInt32((i + 1) % n + 1), UInt32(i + 1)]
        }
        if let band = model(positions: positions, indices: indices, color: color, alpha: alpha) { root.addChild(band) }
        if fillAlpha > 0, let fill = model(positions: disc, indices: discIndices, color: color, alpha: fillAlpha) {
            root.addChild(fill)
        }
        return root
    }

    /// One unlit see-through mesh that casts no shadow (also used by HordeWarning3D for its arrows).
    static func model(positions: [SIMD3<Float>], indices: [UInt32], color: UIColor, alpha: Float) -> Entity? {
        var d = MeshDescriptor(name: "overlay")
        d.positions = MeshBuffers.Positions(positions)
        d.normals = MeshBuffers.Normals(Array(repeating: [0, 1, 0], count: positions.count))
        d.primitives = .triangles(indices)
        guard let mesh = try? MeshResource.generate(from: [d]) else { return nil }
        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: alpha))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
        return entity
    }
}
