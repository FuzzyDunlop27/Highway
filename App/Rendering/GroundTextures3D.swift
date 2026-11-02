// Purpose: Ground tile looks: repeating Poly Haven photo textures per tile id (presentation.json reality3d.groundTextures). Notes: docs/features/rendering-art.md
import Metal
import RealityKit
import UIKit
import HoldoutCore

/// Loads each ground image once (from the app bundle, `App/Textures/Ground/`) and makes repeating materials for it.
/// A missing or unreadable image returns nil, so the caller falls back to the flat tile color (never crashes).
@MainActor
enum GroundTextures3D {
    private static var textures: [String: TextureResource] = [:]
    private static var failed: Set<String> = []

    /// Material for a textured tile (`lighter` = the faint checkerboard), or nil if the image can't be loaded.
    static func material(_ def: GroundTexture3D, lighter: CGFloat) -> PhysicallyBasedMaterial? {
        guard let texture = texture(def.file) else { return nil }
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor.hex(def.tint).lighter(lighter), texture: .init(texture, sampler: repeating))
        m.roughness = .init(floatLiteral: 1)
        m.metallic = .init(floatLiteral: 0)
        return m
    }

    private static func texture(_ file: String) -> TextureResource? {
        if let cached = textures[file] { return cached }
        guard !failed.contains(file) else { return nil }
        let name = (file as NSString).deletingPathExtension, ext = (file as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let texture = try? TextureResource.load(contentsOf: url, options: .init(semantic: .color, mipmapsMode: .allocateAndGenerateAll))
        else {
            failed.insert(file)
            return nil
        }
        textures[file] = texture
        return texture
    }

    /// Wraps around at the image edge (the ground's UVs run past 1) and stays sharp at a low camera angle.
    private static let repeating: MaterialParameters.Texture.Sampler = {
        let d = MTLSamplerDescriptor()
        d.sAddressMode = .repeat
        d.tAddressMode = .repeat
        d.minFilter = .linear
        d.magFilter = .linear
        d.mipFilter = .linear
        d.maxAnisotropy = 8
        return .init(d)
    }()
}
