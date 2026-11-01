// Purpose: Builds the short-lived 3D effect shapes (tracer, muzzle flash, goo, dust, trap flash) from shared meshes. Notes: docs/features/rendering-art.md
import RealityKit
import UIKit

/// Every effect is an unlit, see-through shape that casts no shadow. Meshes and materials are made once and shared,
/// so a busy horde only adds cheap entities. Sizes are look-only constants in metres (1 tile = 1 m today).
@MainActor
enum EffectMeshes3D {
    // Look only: sizes in metres.
    static let tracerThickness: Float = 0.035
    static let flashRadius: Float = 0.16
    static let gooSize: Float = 0.9
    static let gooLift: Float = 0.01
    static let trapFlashLift: Float = 0.05

    private static let tracerMesh = MeshResource.generateBox(width: 1, height: tracerThickness, depth: tracerThickness)
    private static let sphereMesh = MeshResource.generateSphere(radius: 0.5)
    private static let flashMesh = MeshResource.generateSphere(radius: flashRadius)
    private static let gooMesh = MeshResource.generatePlane(width: gooSize, depth: gooSize, cornerRadius: gooSize / 2)
    private static let tileMesh = MeshResource.generatePlane(width: 0.9, depth: 0.9, cornerRadius: 0.1)

    private static let tracerMaterial = material(UIColor(red: 1, green: 0.88, blue: 0.45, alpha: 1), alpha: 0.95)
    private static let flashMaterial = material(UIColor(red: 1, green: 0.8, blue: 0.35, alpha: 1), alpha: 0.9)
    private static let gooMaterial = material(UIColor(red: 0.27, green: 0.36, blue: 0.12, alpha: 1), alpha: 0.85)
    private static let dustMaterial = material(UIColor(red: 0.8, green: 0.76, blue: 0.68, alpha: 1), alpha: 0.8)
    private static let trapMaterial = material(.white, alpha: 0.75)

    /// A thin streak from `from` to `to`.
    static func tracer(from: SIMD3<Float>, to: SIMD3<Float>) -> Entity {
        let d = to - from
        let length = max(simd_length(d), 0.01)
        let e = shape(tracerMesh, tracerMaterial)
        e.position = from + d / 2
        e.scale = [length, 1, 1]
        e.orientation = simd_quatf(from: [1, 0, 0], to: d / length)
        return e
    }

    static func muzzleFlash(at point: SIMD3<Float>) -> Entity {
        let e = shape(flashMesh, flashMaterial)
        e.position = point
        return e
    }

    /// A goo splat lying on the ground; `stretch` (about 0.7–1.3) and `turn` keep neighbours from looking identical.
    static func goo(at ground: SIMD3<Float>, stretch: Float, turn: Float) -> Entity {
        let e = shape(gooMesh, gooMaterial)
        e.position = [ground.x, gooLift, ground.z]
        e.scale = [stretch, 1, 1 / stretch]
        e.orientation = simd_quatf(angle: turn, axis: [0, 1, 0])
        return e
    }

    /// A low cloud of three dust balls about `width` metres across, centred on `ground`.
    static func dust(at ground: SIMD3<Float>, width: Float) -> Entity {
        let root = Entity()
        root.position = ground
        for (dx, dz, size) in [(-0.25, 0.1, 0.8), (0.22, -0.12, 0.7), (0.05, 0.2, 0.6)] as [(Float, Float, Float)] {
            let ball = shape(sphereMesh, dustMaterial)
            ball.position = [dx * width, size * width * 0.3, dz * width]
            ball.scale = [size * width, size * width * 0.6, size * width]
            root.addChild(ball)
        }
        return root
    }

    /// A white flash just above a trap's tile.
    static func trapFlash(at ground: SIMD3<Float>) -> Entity {
        let e = shape(tileMesh, trapMaterial)
        e.position = [ground.x, trapFlashLift, ground.z]
        return e
    }

    private static func shape(_ mesh: MeshResource, _ material: UnlitMaterial) -> ModelEntity {
        let e = ModelEntity(mesh: mesh, materials: [material])
        e.components.set(DynamicLightShadowComponent(castsShadow: false))
        return e
    }

    private static func material(_ color: UIColor, alpha: Float) -> UnlitMaterial {
        var m = UnlitMaterial(color: color)
        m.blending = .transparent(opacity: .init(floatLiteral: alpha))
        return m
    }
}
