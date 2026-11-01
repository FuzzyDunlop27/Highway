// Purpose: Pure math for the 3D view's orbit camera: pan, zoom toward the fingers, tilt, snapped 90° turns, limits. Notes: docs/features/rendering-art.md
import Foundation

/// The camera looks at a ground point (`targetX`, `targetZ`) from `distance` metres away, `pitch` radians above the
/// ground, from compass angle `yaw` (0 = camera south of the target looking north; bigger = further round toward east).
/// Turning snaps to `snapAngles` steps with an eased swing (D-029). Every limit comes from presentation.json.
/// Lives in Core so it can be unit-tested; the App turns `position`/`yaw`/`pitch` into a RealityKit transform.
public struct OrbitCamera3D: Sendable {
    public typealias Point3 = WorldMapping3D.Point3

    public private(set) var targetX = 0.0
    public private(set) var targetZ = 0.0
    public private(set) var pitch: Double
    public private(set) var distance: Double
    /// Current compass angle (moves smoothly during a turn).
    public private(set) var yaw: Double
    /// Snap step the camera is at or turning to (not wrapped, so turns never spin the long way round).
    public private(set) var snapIndex = 0

    private let fov, minDistance, maxDistance, minHeight, minPitch, maxPitch, tiltPerPoint: Double
    private let startYaw, step, twistThreshold, turnSeconds, pinchSensitivity: Double
    private let snapAngles: Int
    private let boundX, boundZ, mapX, mapZ: Double
    private var aspect = 16.0 / 9.0
    private var turnFrom: Double?
    private var turnElapsed = 0.0
    private var twistSoFar = 0.0
    private var twistTurned = false

    public init(_ c: Camera3DDef, mapping: WorldMapping3D) {
        let rad = Double.pi / 180
        fov = c.fieldOfViewDegrees * rad
        minDistance = c.minDistance
        maxDistance = c.maxDistance
        minHeight = c.minHeightMetres
        minPitch = c.minPitchDegrees * rad
        maxPitch = c.maxPitchDegrees * rad
        tiltPerPoint = c.tiltDegreesPerPoint * rad
        startYaw = c.startYawDegrees * rad
        snapAngles = max(1, c.snapAngles)
        step = 2 * .pi / Double(max(1, c.snapAngles))
        twistThreshold = c.twistThresholdDegrees * rad
        turnSeconds = c.snapTurnSeconds
        pinchSensitivity = c.pinchSensitivity
        let half = mapping.halfExtent, margin = c.panMarginTiles * mapping.metresPerTile
        boundX = half.x + margin
        boundZ = half.z + margin
        mapX = half.x * 2
        mapZ = half.z * 2
        pitch = c.startPitchDegrees * rad
        distance = c.startDistance
        yaw = startYaw
        applyLimits()
    }

    // MARK: Where the camera is

    /// Which of the `snapAngles` views is showing (0 ..< snapAngles).
    public var facingIndex: Int { ((snapIndex % snapAngles) + snapAngles) % snapAngles }
    public var isTurning: Bool { turnFrom != nil }

    public var position: Point3 {
        Point3(x: targetX + sin(yaw) * cos(pitch) * distance, y: sin(pitch) * distance,
               z: targetZ + cos(yaw) * cos(pitch) * distance)
    }

    /// The ground point (y = 0) under a screen point, or nil if that point shows sky. Screen y grows downward.
    public func groundPoint(screenX: Double, screenY: Double, viewWidth: Double, viewHeight: Double) -> (x: Double, z: Double)? {
        guard viewWidth > 0, viewHeight > 0 else { return nil }
        let t = tan(fov / 2)
        let nx = (2 * screenX / viewWidth - 1) * t * viewWidth / viewHeight
        let ny = (1 - 2 * screenY / viewHeight) * t
        let forward = (x: -sin(yaw) * cos(pitch), y: -sin(pitch), z: -cos(yaw) * cos(pitch))
        let right = (x: cos(yaw), z: -sin(yaw))
        let up = (x: -sin(yaw) * sin(pitch), y: cos(pitch), z: -cos(yaw) * sin(pitch))
        let dir = (x: forward.x + right.x * nx + up.x * ny, y: forward.y + up.y * ny, z: forward.z + right.z * nx + up.z * ny)
        guard dir.y < -1e-6 else { return nil }
        let eye = position, k = -eye.y / dir.y
        return (eye.x + dir.x * k, eye.z + dir.z * k)
    }

    // MARK: Moving it

    /// Screen size changed (landscape iPhone vs iPad): the zoom-out limit depends on how wide the screen is.
    public mutating func setViewAspect(_ widthOverHeight: Double) {
        guard widthOverHeight > 0 else { return }
        aspect = widthOverHeight
        applyLimits()
    }

    /// Looks straight at a ground point (kept inside the map limits).
    public mutating func lookAt(x: Double, z: Double) {
        targetX = x
        targetZ = z
        applyLimits()
    }

    /// Drag by (dx, dy) screen points: the ground follows the finger.
    public mutating func pan(dx: Double, dy: Double, viewHeight: Double) {
        let metresPerPoint = 2 * distance * tan(fov / 2) / max(viewHeight, 1)
        targetX += (-cos(yaw) * dx - sin(yaw) * dy / sin(pitch)) * metresPerPoint
        targetZ += (sin(yaw) * dx - cos(yaw) * dy / sin(pitch)) * metresPerPoint
        applyLimits()
    }

    /// Pinch by `factor` (>1 = fingers apart = closer), keeping `toward` (the ground under the fingers) in place.
    public mutating func zoom(by factor: Double, toward: (x: Double, z: Double)?) {
        guard factor > 0 else { return }
        let old = distance
        distance = distance / pow(factor, pinchSensitivity)
        clampDistance()
        if let p = toward {
            let s = distance / old  // scaling the camera about p keeps p under the same screen point
            targetX = p.x + (targetX - p.x) * s
            targetZ = p.z + (targetZ - p.z) * s
        }
        applyLimits()
    }

    /// Two fingers dragged up/down by `dy` points: dragging up looks more from above.
    public mutating func tilt(dy: Double) {
        pitch -= dy * tiltPerPoint
        applyLimits()
    }

    /// More two-finger twist in this gesture (radians, clockwise on screen = positive). Past the threshold the
    /// camera turns one step that way; one gesture turns at most one step. Returns true if a turn started.
    @discardableResult
    public mutating func twist(by radians: Double) -> Bool {
        twistSoFar += radians
        guard !twistTurned, abs(twistSoFar) >= twistThreshold else { return false }
        turn(steps: twistSoFar > 0 ? 1 : -1)
        twistTurned = true
        return true
    }

    /// The fingers lifted: a partial twist is forgotten and the next twist can turn again.
    public mutating func endTwist() {
        twistSoFar = 0
        twistTurned = false
    }

    /// Starts an eased turn by `steps` snap angles (clockwise-looking world turn for positive steps).
    public mutating func turn(steps: Int) {
        snapIndex += steps
        turnFrom = yaw
        turnElapsed = 0
        if turnSeconds <= 0 { advance(seconds: 0) }
        applyLimits()
    }

    /// Moves a running turn forward by real seconds (smoothstep easing); call every frame.
    public mutating func advance(seconds: Double) {
        guard let from = turnFrom else { return }
        turnElapsed += seconds
        let to = startYaw + Double(snapIndex) * step
        let t = turnSeconds <= 0 ? 1 : min(1, turnElapsed / turnSeconds)
        yaw = from + (to - from) * t * t * (3 - 2 * t)
        if t >= 1 { yaw = to; turnFrom = nil }
    }

    // MARK: Limits

    /// Farthest zoom: the map (seen from the snap angle) just fills the screen width, and never past maxDistance.
    private var zoomOutLimit: Double {
        let toward = startYaw + Double(snapIndex) * step
        let span = abs(mapX * cos(toward)) + abs(mapZ * sin(toward))
        return min(maxDistance, span / (2 * tan(fov / 2) * aspect))
    }

    private mutating func clampDistance() {
        let lowest = max(minDistance, minHeight / max(sin(pitch), 0.01))  // never below minHeight: no flying into roofs
        distance = min(max(distance, lowest), max(lowest, zoomOutLimit))
    }

    private mutating func applyLimits() {
        pitch = min(max(pitch, minPitch), maxPitch)
        clampDistance()
        targetX = min(max(targetX, -boundX), boundX)
        targetZ = min(max(targetZ, -boundZ), boundZ)
    }
}
