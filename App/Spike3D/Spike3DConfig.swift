// Purpose: Chunk 1R spike tuning, decoded from spike3d.json (DEBUG throwaway). Notes: docs/plans/3d-spike-1R-results.md
#if DEBUG
import Foundation

struct Spike3DConfig: Decodable {
    struct Ground: Decodable { let width, depth, roadZ, roadWidth: Float }
    struct Sun: Decodable { let elevationDegrees, azimuthDegrees, intensityLux, shadowMaxDistance, shadowDepthBias: Float }
    struct Fill: Decodable { let intensityLux: Float }
    struct Camera: Decodable {
        let fieldOfViewDegrees, startDistance, minDistance, maxDistance: Float
        let startPitchDegrees, minPitchDegrees, maxPitchDegrees, startYawDegrees, panLimit: Float
    }
    struct Walkers: Decodable {
        let scale, strideTiles, cyclesPerLoop, innerRadius, ringSpacing: Float
        let perRing: Int
        let counts: [Int]
    }
    struct FreeAssets: Decodable { let metresToTiles: Float }
    let ground: Ground
    let freeAssets: FreeAssets
    let sun: Sun
    let fill: Fill
    let camera: Camera
    let walkers: Walkers
    let cappedFrameRate: Float

    static let shared: Spike3DConfig = {
        guard let url = Bundle.main.url(forResource: "spike3d", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(Spike3DConfig.self, from: data) else {
            fatalError("spike3d.json missing or invalid (DEBUG spike only)")
        }
        return config
    }()
}
#endif
