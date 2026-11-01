// Purpose: Smooth drawn movement, turning and walk-cycle speed for 3D characters between Core's 10 ticks/s. Notes: docs/features/characters-3d.md
import Foundation
import Testing
@testable import HoldoutCore

struct CharacterMotion3DTests {
    private let s = Characters3DDef(turnRadiansPerSecond: 4, minGlideSeconds: 0.03, maxGlideSeconds: 0.25,
                                    snapDistanceTiles: 1.5, standSpeedTiles: 0.02, standGraceSeconds: 0.2,
                                    speedSmoothingSeconds: 0.15, maxWalkRate: 6, clipBlendSeconds: 0.2, variants: [:])

    private func near(_ a: Double, _ b: Double, _ tol: Double = 1e-6) -> Bool { abs(a - b) < tol }

    /// Core steps 0.06 tiles every 0.1 s (a walker at 0.6 tiles/s); the screen draws at 60 fps.
    private func walk(_ m: inout CharacterMotion3D, ticks: Int, startX: Double = 0) {
        for tick in 1...ticks {
            let tx = startX + Double(tick) * 0.06
            for _ in 0..<6 { m.update(toX: tx, y: 0, heading: 0, seconds: 0.1 / 6, settings: s) }
        }
    }

    @Test func glidesBetweenTicksInsteadOfJumping() {
        var m = CharacterMotion3D(x: 0, y: 0, heading: 0, settings: s)
        walk(&m, ticks: 5)
        var xs: [Double] = []
        for _ in 0..<6 {  // during the next tick the drawn x moves a little every frame, never a whole step at once
            m.update(toX: 0.36, y: 0, heading: 0, seconds: 0.1 / 6, settings: s)
            xs.append(m.x)
        }
        let steps = zip(xs.dropFirst(), xs).map { $0 - $1 }
        #expect(steps.allSatisfy { $0 > 0 && $0 < 0.03 })
        #expect(near(xs.last!, 0.36))
    }

    @Test func drawnSpeedMatchesCoreSpeedSoTheWalkRateMatchesTheStride() {
        var m = CharacterMotion3D(x: 0, y: 0, heading: 0, settings: s)
        walk(&m, ticks: 20)
        #expect(near(m.speed, 0.6, 0.03))
        #expect(m.clip(attacking: false) == .walk)
        // Walker: 4 s loop carries the body 0.6095 tiles → at 0.6 tiles/s the loop plays ~3.9× as authored.
        let rate = CharacterMotion3D.walkRate(speedTiles: 0.6, strideTiles: 0.6095, cycleSeconds: 4, maxRate: 6)
        #expect(near(rate * 0.6095 / 4, 0.6))  // one loop per stride: the feet move as fast as the ground passes
        #expect(CharacterMotion3D.walkRate(speedTiles: 5, strideTiles: 0.6, cycleSeconds: 4, maxRate: 6) == 6)
        #expect(CharacterMotion3D.walkRate(speedTiles: 1, strideTiles: 0, cycleSeconds: 4, maxRate: 6) == 1)
    }

    @Test func standsStillAfterTheGraceAndAttacksWhenBashing() {
        var m = CharacterMotion3D(x: 0, y: 0, heading: 0, settings: s)
        walk(&m, ticks: 10)
        for _ in 0..<6 { m.update(toX: 0.6, y: 0, heading: 0, seconds: 0.1 / 6, settings: s) }
        #expect(m.clip(attacking: false) == .walk)  // within the grace: no flicker to idle between steps
        for _ in 0..<30 { m.update(toX: 0.6, y: 0, heading: 0, seconds: 0.1 / 6, settings: s) }
        #expect(m.speed == 0 && m.clip(attacking: false) == .idle)
        #expect(m.clip(attacking: true) == .attack)
    }

    @Test func farMovesAreDrawnAsJumps() {
        var m = CharacterMotion3D(x: 0, y: 0, heading: 0, settings: s)
        m.update(toX: 10, y: 4, heading: 0, seconds: 1 / 60, settings: s)
        #expect(m.x == 10 && m.y == 4)
    }

    @Test func turnsTheShortWayAtACappedRate() {
        #expect(near(CharacterMotion3D.turn(0, toward: 1, maxStep: 0.25), 0.25))
        #expect(near(CharacterMotion3D.turn(0, toward: 0.1, maxStep: 0.25), 0.1))
        // From just below +π to just above −π is a small turn across the back, not a full spin.
        #expect(near(CharacterMotion3D.turn(3.1, toward: -3.1, maxStep: 1), 3.1 + (2 * .pi - 6.2)))
        var m = CharacterMotion3D(x: 0, y: 0, heading: 0, settings: s)
        m.update(toX: 0, y: 0, heading: .pi / 2, seconds: 0.1, settings: s)
        #expect(near(m.heading, 0.4))  // 4 rad/s × 0.1 s
    }

    @Test func animFileGivesClipRangesIncludingTheLastFrame() throws {
        let json = #"{"fps": 30, "clips": {"walk": [0, 4], "attack": [4.0333, 6]}, "strideTiles": 0.6095}"#
        let file = try JSONDecoder().decode(CharacterAnimFile.self, from: Data(json.utf8))
        #expect(file.range(.walk) == 0...(4 + 1.0 / 30))
        #expect(file.range(.idle) == nil)
        #expect(file.strideTiles == 0.6095)
    }
}
