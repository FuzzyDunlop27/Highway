// Purpose: Art id → 3D model loaded in the background, or a labeled colored box until then / if missing (never crashes). Notes: docs/features/rendering-art.md
import RealityKit
import UIKit

/// The 3D twin of `ArtRegistry`. `entity(...)` always returns at once: a box the size of the footprint with the art id
/// written above it. If `<artId>.usdz` is in the app bundle (2M puts them there), it loads in the background and replaces
/// the box in every entity still showing it. Missing or broken files keep the box.
@MainActor
final class ModelRegistry {
    static let shared = ModelRegistry()

    /// presentation.json `reality3d.loadModels` (false = boxes only) and `metresPerTile` (models are 1 tile = 1 m).
    var loadModels = true
    var modelScale: Float = 1

    private var templates: [String: Entity] = [:]
    private var failed: Set<String> = []
    private var waiting: [String: [WeakEntity]] = [:]
    private var materials: [String: PhysicallyBasedMaterial] = [:]
    private var boxMeshes: [SIMD3<Float>: MeshResource] = [:]
    private var labelMeshes: [String: MeshResource] = [:]

    /// Look-only: gap left around each placeholder box, label size and lift, and how see-through a half-built 1×1 is.
    private static let boxInset: Float = 0.06
    private static let labelFontMetres: CGFloat = 0.22
    private static let labelLift: Float = 0.2
    static let underConstructionOpacity: Float = 0.45
    static let placeholderName = "placeholder"

    private final class WeakEntity {
        weak var entity: Entity?
        init(_ entity: Entity) { self.entity = entity }
    }

    /// A container for art `id`. `size` = footprint width (x), box height (y) and footprint depth (z), in metres.
    /// Its origin is the footprint's ground middle (the same rule the 2M model export uses).
    func entity(_ id: String, size: SIMD3<Float>, labelMinWidth: Float = 0) -> Entity {
        let container = Entity()
        container.name = id
        if let model = templates[id] {
            container.addChild(model.clone(recursive: true))
            return container
        }
        container.addChild(placeholder(id, size: size, labelMinWidth: labelMinWidth))
        if loadModels && !failed.contains(id) {
            waiting[id, default: []].append(WeakEntity(container))
            startLoading(id)
        }
        return container
    }

    // MARK: Background loading

    private func startLoading(_ id: String) {
        guard waiting[id]?.count == 1 else { return }  // already loading
        guard let url = Bundle.main.url(forResource: id, withExtension: "usdz") else {
            finish(id, model: nil)
            return
        }
        Task { @MainActor in
            let model = try? await Entity(contentsOf: url)
            self.finish(id, model: model)
        }
    }

    private func finish(_ id: String, model: Entity?) {
        let containers = waiting.removeValue(forKey: id) ?? []
        guard let model else {
            failed.insert(id)
            return
        }
        model.scale = .init(repeating: modelScale)
        templates[id] = model
        for container in containers.compactMap(\.entity) {
            container.findEntity(named: Self.placeholderName)?.removeFromParent()
            container.addChild(model.clone(recursive: true))
        }
    }

    // MARK: Placeholder box

    private func placeholder(_ id: String, size: SIMD3<Float>, labelMinWidth: Float) -> Entity {
        let root = Entity()
        root.name = Self.placeholderName
        let box = SIMD3(max(size.x - 2 * Self.boxInset, 0.05), max(size.y, 0.02), max(size.z - 2 * Self.boxInset, 0.05))
        let mesh = boxMeshes[box] ?? MeshResource.generateBox(width: box.x, height: box.y, depth: box.z,
                                                             cornerRadius: min(box.x, box.y, box.z) * 0.08)
        boxMeshes[box] = mesh
        let body = ModelEntity(mesh: mesh, materials: [material(id)])
        body.position.y = box.y / 2
        root.addChild(body)
        if let label = label(id, maxWidth: max(size.x, size.z, labelMinWidth) * 0.95) {
            label.position.y = box.y + Self.labelLift
            root.addChild(label)
        }
        return root
    }

    /// Same color per art category as the menu placeholders (PlaceholderArt.color), matte.
    func material(_ id: String, lighter: CGFloat = 0) -> PhysicallyBasedMaterial {
        let key = "\(id)#\(lighter)"
        if let cached = materials[key] { return cached }
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: PlaceholderArt.color(for: id).lighter(lighter))
        m.roughness = .init(floatLiteral: 1)
        m.metallic = .init(floatLiteral: 0)
        materials[key] = m
        return m
    }

    /// The art id as white text that always faces the camera, shrunk to fit `maxWidth` metres.
    private func label(_ id: String, maxWidth: Float) -> Entity? {
        let mesh = labelMeshes[id] ?? MeshResource.generateText(id, extrusionDepth: 0.005,
                                                                font: .boldSystemFont(ofSize: Self.labelFontMetres))
        labelMeshes[id] = mesh
        let bounds = mesh.bounds
        guard bounds.extents.x > 0 else { return nil }
        let text = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .white)])
        text.position = -bounds.center
        text.components.set(DynamicLightShadowComponent(castsShadow: false))
        let holder = Entity()
        holder.scale = .init(repeating: min(1, maxWidth / bounds.extents.x))
        holder.addChild(text)
        holder.components.set(BillboardComponent())
        return holder
    }
}
