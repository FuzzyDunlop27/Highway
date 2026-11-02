// Purpose: The 3D ground: one merged mesh for the whole map (one part per tile look) plus the decorations. Notes: docs/features/rendering-art.md
import RealityKit
import UIKit
import HoldoutCore

/// Builds the ground once. 1,200 separate tile entities would be slow (plan §5), so every tile becomes two triangles
/// in one mesh; tiles of the same art id (and checker parity, so the grid stays readable) share one material part.
/// Tiles listed in `groundTextures` get a repeating photo texture (UVs in tiles), the rest a flat color.
@MainActor
enum GroundMesh3D {
    /// Look-only: every other tile is drawn this much lighter, like a faint checkerboard.
    private static let checkerLighten: CGFloat = 0.05

    static func make(map: MapDef, mapping: WorldMapping3D, registry: ModelRegistry,
                     textures: [String: GroundTexture3D]) -> Entity {
        struct Part { var positions: [SIMD3<Float>] = []; var tileUVs: [SIMD2<Float>] = []; var indices: [UInt32] = [] }
        var parts: [String: Part] = [:]
        var order: [String] = []
        for y in 0..<map.height {
            for x in 0..<map.width {
                guard let tile = map.tile(at: GridPoint(x: x, y: y)) else { continue }
                let key = "\(tile.tile)|\((x + y) % 2)"
                if parts[key] == nil { order.append(key) }
                var part = parts[key] ?? Part()
                let base = UInt32(part.positions.count)
                let a = mapping.world(gx: Double(x), gy: Double(y)), b = mapping.world(gx: Double(x + 1), gy: Double(y + 1))
                let (x0, z0, x1, z1) = (Float(a.x), Float(a.z), Float(b.x), Float(b.z))
                part.positions += [[x0, 0, z0], [x0, 0, z1], [x1, 0, z1], [x1, 0, z0]]
                let (u0, v0, u1, v1) = (Float(x), Float(y), Float(x + 1), Float(y + 1))
                part.tileUVs += [[u0, v0], [u0, v1], [u1, v1], [u1, v0]]
                part.indices += [base, base + 1, base + 2, base, base + 2, base + 3]  // counter-clockwise from above
                parts[key] = part
            }
        }
        var descriptors: [MeshDescriptor] = []
        var materials: [any RealityKit.Material] = []
        for (index, key) in order.enumerated() {
            guard let part = parts[key] else { continue }
            var d = MeshDescriptor(name: key)
            d.positions = MeshBuffers.Positions(part.positions)
            d.normals = MeshBuffers.Normals(Array(repeating: [0, 1, 0], count: part.positions.count))
            d.primitives = .triangles(part.indices)
            d.materials = .allFaces(UInt32(index))
            let parts = key.split(separator: "|")
            let tileId = String(parts[0]), lighter = parts.last == "1" ? checkerLighten : 0
            if let texture = textures[tileId], let textured = GroundTextures3D.material(texture, lighter: lighter) {
                let repeatTiles = Float(texture.repeatTiles)
                d.textureCoordinates = MeshBuffers.TextureCoordinates(part.tileUVs.map { $0 / repeatTiles })
                materials.append(textured)
            } else {
                materials.append(registry.material(tileId, lighter: lighter))
            }
            descriptors.append(d)
        }
        let root = Entity()
        root.name = "ground"
        if let mesh = try? MeshResource.generate(from: descriptors) {
            let ground = ModelEntity(mesh: mesh, materials: materials)
            ground.components.set(DynamicLightShadowComponent(castsShadow: false))
            root.addChild(ground)
        }
        return root
    }

    /// Car wrecks, trees and rubble from the map file, as models or labeled boxes ("decoration" height).
    static func decorations(map: MapDef, mapping: WorldMapping3D, settings: Reality3DDef, registry: ModelRegistry) -> Entity {
        let root = Entity()
        root.name = "decorations"
        let height = Reality3DSizes.height(category: ArtCategory.decoration, settings: settings)
        for d in map.decorations where d.footprint.count == 2 {
            let w = d.footprint[0], h = d.footprint[1]
            let size = mapping.footprintSize(width: w, height: h)
            let entity = registry.entity(d.id, size: [Float(size.x), height, Float(size.z)])
            entity.position = Reality3DSizes.vector(mapping.footprintCenter(origin: GridPoint(x: d.x, y: d.y), width: w, height: h))
            root.addChild(entity)
        }
        return root
    }
}

/// Small shared helpers for 3D sizes (placeholder heights from presentation.json) and Core → simd points.
enum Reality3DSizes {
    /// Box height in metres for a building category (`default`, then 1 tile, if the category isn't listed).
    static func height(category: String, settings: Reality3DDef) -> Float {
        let tiles = settings.placeholderHeightTiles[category] ?? settings.placeholderHeightTiles["default"] ?? 1
        return Float(tiles * settings.metresPerTile)
    }

    static func vector(_ p: WorldMapping3D.Point3) -> SIMD3<Float> { [Float(p.x), Float(p.y), Float(p.z)] }
}
