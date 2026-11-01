// Purpose: 3D placement preview: see-through ghost, tile grid around it, green/red footprint, the wall tool's planned line. Notes: docs/features/input.md
import RealityKit
import UIKit
import HoldoutCore

/// Draws what `PlacementController` describes; never changes game state. Each part is rebuilt only when what it shows
/// changes (the ghost model only when the building type changes; dragging just moves it).
@MainActor
final class PlacementLayer3D {
    let root = Entity()
    /// The ghost's pick/fade box (footprint × box height), or nil when no ghost shows. Read by touches and the fader.
    private(set) var ghostBox: Box3D?

    /// Look-only: tiles of grid drawn on each side of the ghost / line end, and how see-through the previews are.
    static let gridRadius = 6
    static let ghostOpacity: Float = 0.6
    static let plannedWallOpacity: Float = 0.6
    private static let gridAlpha: Float = 0.35
    private static let blockedAlpha: Float = 0.2
    private static let footprintAlpha: Float = 0.5
    private static let footprintInset: Float = 0.04

    private struct GridKey: Equatable { let origin: GridPoint; let width: Int; let height: Int }
    private struct FootprintKey: Equatable { let origin: GridPoint; let width: Int; let height: Int; let check: PlacementCheck? }
    private var ghost: (defId: String, entity: Entity)?
    private var grid: (key: GridKey, entity: Entity)?
    private var footprint: (key: FootprintKey, entity: Entity)?
    private var line: (plan: LinePlan, entity: Entity)?

    init() { root.name = "placement" }

    func sync(placement: PlacementController, viewCenter: GridPoint, loop: GameLoop, mapping: WorldMapping3D,
              settings: Reality3DDef, registry: ModelRegistry) {
        if case .drawingLine(let defId) = placement.mode, let def = loop.content.buildingDef(defId) {
            clearGhost()
            syncGrid(GridKey(origin: placement.lineEnd ?? viewCenter, width: 1, height: 1), map: loop.map, mapping: mapping)
            syncLine(placement.linePlan, def: def, loop: loop, mapping: mapping, settings: settings, registry: registry)
        } else if let defId = placement.ghostDefId, let def = loop.content.buildingDef(defId) {
            clearLine()
            let origin = placement.ghostOrigin
            syncGrid(GridKey(origin: origin, width: def.width, height: def.height), map: loop.map, mapping: mapping)
            syncFootprint(FootprintKey(origin: origin, width: def.width, height: def.height, check: placement.check),
                          mapping: mapping)
            syncGhost(def: def, origin: origin, mapping: mapping, settings: settings, registry: registry)
        } else {
            clearGhost()
            clearLine()
            replace(&grid, with: nil)
        }
    }

    // MARK: Ghost

    private func syncGhost(def: BuildingDef, origin: GridPoint, mapping: WorldMapping3D, settings: Reality3DDef,
                           registry: ModelRegistry) {
        let height = Reality3DSizes.height(category: def.category, settings: settings)
        if ghost?.defId != def.id {
            ghost?.entity.removeFromParent()
            let size = mapping.footprintSize(width: def.width, height: def.height)
            let entity = registry.entity(def.sprite, size: [Float(size.x), height, Float(size.z)])
            entity.components.set(OpacityComponent(opacity: Self.ghostOpacity))
            entity.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(entity)
            ghost = (def.id, entity)
        }
        ghost?.entity.position = Reality3DSizes.vector(mapping.footprintCenter(origin: origin, width: def.width, height: def.height))
        ghostBox = Box3D(footprint: origin, width: def.width, height: def.height, tall: Double(height), mapping: mapping)
    }

    private func clearGhost() {
        ghost?.entity.removeFromParent()
        ghost = nil
        ghostBox = nil
        replace(&footprint, with: nil)
    }

    /// Green when the spot is fine; otherwise blocked tiles strong red and the rest light red (cost, limit, HQ level).
    private func syncFootprint(_ key: FootprintKey, mapping: WorldMapping3D) {
        guard footprint?.key != key else { return }
        let tiles = key.origin.footprintTiles(width: key.width, height: key.height)
        let entity = Entity()
        if key.check?.isValid ?? false {
            add(tiles, color: .systemGreen, alpha: Self.footprintAlpha, to: entity, mapping: mapping)
        } else {
            let bad = Set(key.check?.badTiles ?? [])
            add(tiles.filter(bad.contains), color: .systemRed, alpha: Self.footprintAlpha, to: entity, mapping: mapping)
            add(tiles.filter { !bad.contains($0) }, color: .systemRed, alpha: Self.footprintAlpha * 0.5, to: entity, mapping: mapping)
        }
        replace(&footprint, with: (key, entity))
    }

    // MARK: Grid

    /// Tile lines within `gridRadius` of the ghost; tiles that can never be built on (highway, wrecks, trees) tinted red.
    private func syncGrid(_ key: GridKey, map: MapDef, mapping: WorldMapping3D) {
        guard grid?.key != key else { return }
        let r = Self.gridRadius
        let x0 = max(0, key.origin.x - r), x1 = min(map.width - 1, key.origin.x + key.width - 1 + r)
        let y0 = max(0, key.origin.y - r), y1 = min(map.height - 1, key.origin.y + key.height - 1 + r)
        let entity = Entity()
        guard x0 <= x1, y0 <= y1 else { replace(&grid, with: (key, entity)); return }
        let decorations = map.decorationTiles
        var blocked: [GridPoint] = []
        for y in y0...y1 {
            for x in x0...x1 {
                let p = GridPoint(x: x, y: y)
                if map.tile(at: p)?.buildable == false || decorations.contains(p) { blocked.append(p) }
            }
        }
        add(blocked, color: .systemRed, alpha: Self.blockedAlpha, to: entity, mapping: mapping)
        let a = mapping.world(gx: Double(x0), gy: Double(y0)), b = mapping.world(gx: Double(x1 + 1), gy: Double(y1 + 1))
        let half = OverlayMeshes3D.gridLineWidth / 2
        var lines: [OverlayMeshes3D.Rect] = []
        for x in x0...(x1 + 1) {
            let wx = Float(mapping.world(gx: Double(x), gy: 0).x)
            lines.append(.init(x0: wx - half, z0: Float(a.z), x1: wx + half, z1: Float(b.z)))
        }
        for y in y0...(y1 + 1) {
            let wz = Float(mapping.world(gx: 0, gy: Double(y)).z)
            lines.append(.init(x0: Float(a.x), z0: wz - half, x1: Float(b.x), z1: wz + half))
        }
        if let l = OverlayMeshes3D.rects(lines, color: .white, alpha: Self.gridAlpha, lift: OverlayMeshes3D.lineLift) {
            entity.addChild(l)
        }
        replace(&grid, with: (key, entity))
    }

    // MARK: Wall tool

    /// Planned walls see-through on green tiles (orange if the line can't be built), skipped tiles red.
    private func syncLine(_ plan: LinePlan?, def: BuildingDef, loop: GameLoop, mapping: WorldMapping3D,
                          settings: Reality3DDef, registry: ModelRegistry) {
        guard let plan else { clearLine(); return }
        guard line?.plan != plan else { return }
        let entity = Entity()
        add(plan.buildable, color: plan.canBuild ? .systemGreen : .systemOrange, alpha: Self.footprintAlpha, to: entity, mapping: mapping)
        add(plan.blocked, color: .systemRed, alpha: Self.footprintAlpha, to: entity, mapping: mapping)
        // Planned walls run along the line like built ones (BuildingLayer3D turns north-south walls).
        let neighbours = BuildingLayer3D.wallTiles(loop.state.base.buildings, content: loop.content).union(plan.tiles)
        let height = Reality3DSizes.height(category: def.category, settings: settings)
        for t in plan.buildable {
            let wall = registry.entity(def.sprite, size: [Float(mapping.metresPerTile), height, Float(mapping.metresPerTile)])
            wall.position = Reality3DSizes.vector(mapping.footprintCenter(origin: t, width: 1, height: 1))
            if BuildingLayer3D.runsNorthSouth(tile: t, wallTiles: neighbours) {
                wall.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            }
            wall.components.set(OpacityComponent(opacity: Self.plannedWallOpacity))
            wall.components.set(DynamicLightShadowComponent(castsShadow: false))
            entity.addChild(wall)
        }
        line?.entity.removeFromParent()
        root.addChild(entity)
        line = (plan, entity)
    }

    private func clearLine() {
        line?.entity.removeFromParent()
        line = nil
    }

    // MARK: Helpers

    private func add(_ tiles: [GridPoint], color: UIColor, alpha: Float, to parent: Entity, mapping: WorldMapping3D) {
        let rects = tiles.map { OverlayMeshes3D.tileRect($0, mapping: mapping, inset: Self.footprintInset) }
        if let e = OverlayMeshes3D.rects(rects, color: color, alpha: alpha) { parent.addChild(e) }
    }

    private func replace<Key>(_ slot: inout (key: Key, entity: Entity)?, with new: (key: Key, entity: Entity)?) {
        slot?.entity.removeFromParent()
        if let new { root.addChild(new.entity) }
        slot = new
    }
}
