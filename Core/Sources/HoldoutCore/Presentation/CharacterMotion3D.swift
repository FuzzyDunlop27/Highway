// Purpose: Smooth drawn movement, turning and walk-cycle speed for 3D characters between Core's 10 ticks/s. Read by the App only. Notes: docs/features/characters-3d.md
import Foundation

/// Which clip a character model plays.
public enum CharacterClip3D: String, Codable, Sendable, CaseIterable {
    case walk, attack, idle
}

/// One character's drawn state. Core moves zombies in steps (one per tick); this glides the drawn position from where it
/// is to each new Core position over about one tick, turns toward Core's heading at a capped rate, and works out how
/// fast the walk cycle must play so the feet don't slide (cycle speed = drawn speed ÷ stride). Look only; no game rules.
public struct CharacterMotion3D: Sendable {
    public private(set) var x: Double
    public private(set) var y: Double
    /// Drawn heading in grid radians (0 = east, π/2 = south), like `Zombie.heading`.
    public private(set) var heading: Double
    /// Drawn speed in tiles per second, smoothed.
    public private(set) var speed: Double = 0
    private var target: (x: Double, y: Double)
    private var from: (x: Double, y: Double)
    private var segmentSeconds: Double
    private var sinceTargetChange: Double = 0
    private var sinceMoving: Double = .infinity

    public init(x: Double, y: Double, heading: Double, settings: Characters3DDef) {
        self.x = x
        self.y = y
        self.heading = heading
        target = (x, y)
        from = (x, y)
        segmentSeconds = settings.maxGlideSeconds
    }

    /// Advances the drawing by `seconds` towards Core's latest position and heading.
    public mutating func update(toX tx: Double, y ty: Double, heading targetHeading: Double, seconds: Double,
                                settings s: Characters3DDef) {
        if tx != target.x || ty != target.y {
            if hypot(tx - x, ty - y) > s.snapDistanceTiles {
                (x, y, from) = (tx, ty, (tx, ty))  // spawned, teleported or the save reloaded: jump, don't glide
            } else {
                from = (x, y)
            }
            target = (tx, ty)
            // The next step will probably take as long as the last one did.
            segmentSeconds = min(max(sinceTargetChange, s.minGlideSeconds), s.maxGlideSeconds)
            sinceTargetChange = seconds  // the new position arrived during this frame, so this frame already glides
        } else {
            sinceTargetChange += seconds
        }
        let t = min(1, sinceTargetChange / segmentSeconds)
        let nx = from.x + (target.x - from.x) * t, ny = from.y + (target.y - from.y) * t
        let instant = seconds > 0 ? hypot(nx - x, ny - y) / seconds : 0
        (x, y) = (nx, ny)
        if instant > s.standSpeedTiles {
            sinceMoving = 0
            speed += (instant - speed) * min(1, seconds / max(s.speedSmoothingSeconds, 1e-6))
        } else {
            // Between steps the glide may pause for a frame; keep the last speed for a short grace so the walk doesn't flicker.
            sinceMoving += seconds
            if sinceMoving > s.standGraceSeconds { speed = 0 }
        }
        heading = Self.turn(heading, toward: targetHeading, maxStep: s.turnRadiansPerSecond * seconds)
    }

    /// Walk while moving, attack while Core says it is bashing, otherwise stand.
    public func clip(attacking: Bool) -> CharacterClip3D {
        if attacking { return .attack }
        return speed > 0 ? .walk : .idle
    }

    /// Walk-cycle playback speed (1 = as authored) so one loop covers exactly one stride: no foot sliding.
    public static func walkRate(speedTiles: Double, strideTiles: Double, cycleSeconds: Double, maxRate: Double) -> Double {
        guard strideTiles > 0, cycleSeconds > 0 else { return 1 }
        return min(max(speedTiles * cycleSeconds / strideTiles, 0), maxRate)
    }

    /// Turns `angle` toward `goal` the short way round by at most `maxStep` radians.
    public static func turn(_ angle: Double, toward goal: Double, maxStep: Double) -> Double {
        var delta = (goal - angle).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi { delta -= 2 * .pi } else if delta < -.pi { delta += 2 * .pi }
        return abs(delta) <= maxStep ? angle + delta : angle + (delta > 0 ? maxStep : -maxStep)
    }
}

/// What `tools/blender/export_characters.py` writes next to a character model (`<artId>.anim.json`).
public struct CharacterAnimFile: Codable, Sendable {
    public let fps: Double
    /// Clip name → [first, last] second on the model's timeline.
    public let clips: [String: [Double]]
    /// Tiles one walk loop carries the body (at the model's own scale).
    public let strideTiles: Double?

    public func range(_ clip: CharacterClip3D) -> ClosedRange<Double>? {
        guard let r = clips[clip.rawValue], r.count == 2, r[1] >= r[0] else { return nil }
        return r[0]...(r[1] + 1 / fps)  // the last frame is shown for one frame, then the loop starts again
    }
}
