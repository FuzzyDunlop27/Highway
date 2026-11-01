// Purpose: Pulsing red tiles and ground arrows at the spawn edges the next horde was announced for (warning time only). Notes: docs/features/rendering-art.md
import RealityKit
import UIKit
import HoldoutCore

/// The 3D twin of the old 2D HordeWarningOverlay: the warned edges' tiles glow red and a big arrow lies on the ground just
/// inside each edge, pointing at the middle of the map (where zombies head). Redrawn only when the edge list changes.
@MainActor
final class HordeWarning3D {
    let root = Entity()
    private var shown: [String] = []
    private var tiles: [Entity] = [], arrows: [Entity] = []
    private var clock = 0.0

    // Look only: arrow length (tiles), how far inside the map it sits, pulse time, arrow lift (metres).
    private static let arrowTiles = 2.2
    private static let insetTiles = 2.0
    private static let pulseSeconds = 0.5
    private static let arrowLift: Float = 0.04

    init() { root.name = "hordeWarning" }

    /// `edges` = map spawnEdges ids being warned about (empty = nothing to show); `seconds` = real time this frame.
    func sync(edges: [String], map: MapDef, mapping: WorldMapping3D, seconds: Double) {
        if edges != shown { rebuild(edges, map: map, mapping: mapping) }
        guard !edges.isEmpty else { return }
        clock += seconds
        let pulse = Float(0.5 + 0.5 * sin(clock / Self.pulseSeconds * .pi))  // 0…1, one swing per pulseSeconds
        for t in tiles { t.components.set(OpacityComponent(opacity: 0.4 + 0.6 * pulse)) }
        for a in arrows { a.scale = .init(repeating: 1 + 0.25 * pulse) }
    }

    private func rebuild(_ edges: [String], map: MapDef, mapping: WorldMapping3D) {
        root.children.removeAll()
        tiles = []
        arrows = []
        shown = edges
        clock = 0
        for edge in map.spawnEdges where edges.contains(edge.id) {
            var rects: [OverlayMeshes3D.Rect] = []
            for x in edge.x..<(edge.x + edge.w) {
                for y in edge.y..<(edge.y + edge.h) {
                    rects.append(OverlayMeshes3D.tileRect(GridPoint(x: x, y: y), mapping: mapping, inset: 0.04))
                }
            }
            if let glow = OverlayMeshes3D.rects(rects, color: .systemRed, alpha: 0.45) {
                root.addChild(glow)
                tiles.append(glow)
            }
            if let arrow = arrow(edge, map: map, mapping: mapping) {
                root.addChild(arrow)
                arrows.append(arrow)
            }
        }
    }

    /// A flat arrow (tip at +X) just inside the edge, turned toward the map's middle.
    private func arrow(_ edge: SpawnEdgeDef, map: MapDef, mapping: WorldMapping3D) -> Entity? {
        let cx = Double(edge.x) + Double(edge.w) / 2, cy = Double(edge.y) + Double(edge.h) / 2
        let heading = atan2(Double(map.height) / 2 - cy, Double(map.width) / 2 - cx)
        let gx = cx + cos(heading) * Self.insetTiles, gy = cy + sin(heading) * Self.insetTiles
        let l = Float(Self.arrowTiles * mapping.metresPerTile), y = Self.arrowLift
        let points: [SIMD3<Float>] = [[l / 2, y, 0], [-l / 2, y, l * 0.4], [-l / 4, y, 0], [-l / 2, y, -l * 0.4]]
        // Two triangles (tip–back–notch on each side), both windings so it shows from any camera angle.
        let indices: [UInt32] = [0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2]
        guard let shape = OverlayMeshes3D.model(positions: points, indices: indices, color: .systemRed, alpha: 0.9) else { return nil }
        let holder = Entity()
        holder.position = Reality3DSizes.vector(mapping.world(gx: gx, gy: gy))
        holder.orientation = simd_quatf(angle: Float(WorldMapping3D.yaw(heading: heading)), axis: [0, 1, 0])
        holder.addChild(shape)
        return holder
    }
}
