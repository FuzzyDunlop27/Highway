// Purpose: Orbit camera maths for the 1R spike: pan, zoom, twist, limited tilt → a camera transform. Notes: docs/plans/3d-spike-1R-results.md
#if DEBUG
import RealityKit
import simd

struct Spike3DOrbitCamera {
    var target = SIMD3<Float>(0, 0, 0)
    var yaw: Float
    var pitch: Float
    var distance: Float
    private let limits: Spike3DConfig.Camera

    init(_ limits: Spike3DConfig.Camera) {
        self.limits = limits
        yaw = limits.startYawDegrees * .pi / 180
        pitch = limits.startPitchDegrees * .pi / 180
        distance = limits.startDistance
    }

    /// Screen drag in points → ground movement; scaled by distance so the ground sticks roughly under the finger.
    mutating func pan(dx: Float, dy: Float, viewHeight: Float) {
        let metresPerPoint = 2 * distance * tan(limits.fieldOfViewDegrees * .pi / 360) / max(viewHeight, 1)
        let right = SIMD3<Float>(cos(yaw), 0, -sin(yaw))
        let forward = SIMD3<Float>(-sin(yaw), 0, -cos(yaw))
        target -= right * dx * metresPerPoint
        target += forward * dy * metresPerPoint / max(sin(pitch), 0.3)
        target.x = min(max(target.x, -limits.panLimit), limits.panLimit)
        target.z = min(max(target.z, -limits.panLimit), limits.panLimit)
    }

    mutating func zoom(by factor: Float) {
        distance = min(max(distance / factor, limits.minDistance), limits.maxDistance)
    }

    mutating func twist(by radians: Float) { yaw += radians }

    mutating func tilt(dy: Float) {
        let lo = limits.minPitchDegrees * .pi / 180, hi = limits.maxPitchDegrees * .pi / 180
        pitch = min(max(pitch + dy * 0.005, lo), hi)
    }

    var transform: Transform {
        let offset = SIMD3<Float>(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
        var t = Transform()
        t.translation = target + offset
        t.rotation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: -pitch, axis: [1, 0, 0])
        return t
    }
}
#endif
