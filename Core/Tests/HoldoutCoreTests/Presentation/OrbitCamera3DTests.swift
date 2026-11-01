// Purpose: 3D orbit camera: snapped eased turns (D-029), zoom toward the fingers, minimum height, map limits. Notes: docs/features/rendering-art.md
import Foundation
import Testing
@testable import HoldoutCore

struct OrbitCamera3DTests {
    private let mapping = WorldMapping3D(metresPerTile: 1, mapWidth: 40, mapHeight: 30)

    private func def(startDistance: Double = 20, maxDistance: Double = 50, minHeight: Double = 4, pitch: Double = 40,
                     turnSeconds: Double = 0.4) -> Camera3DDef {
        Camera3DDef(fieldOfViewDegrees: 35, startDistance: startDistance, minDistance: 6, maxDistance: maxDistance,
                    minHeightMetres: minHeight, startPitchDegrees: pitch, minPitchDegrees: 25, maxPitchDegrees: 75,
                    tiltDegreesPerPoint: 0.25, startYawDegrees: 45, snapAngles: 4, twistThresholdDegrees: 25,
                    snapTurnSeconds: turnSeconds, pinchSensitivity: 0.6, panMarginTiles: 2)
    }

    private func deg(_ d: Double) -> Double { d * .pi / 180 }
    private func near(_ a: Double, _ b: Double, _ tol: Double = 1e-6) -> Bool { abs(a - b) < tol }

    @Test func smallTwistDoesNothingAndPastTheThresholdTurnsOneStep() {
        var cam = OrbitCamera3D(def(), mapping: mapping)
        #expect(cam.twist(by: deg(15)) == false)
        cam.endTwist()  // fingers lifted: the 15° is forgotten
        #expect(cam.twist(by: deg(15)) == false)
        #expect(cam.snapIndex == 0)
        #expect(cam.twist(by: deg(12)) == true)  // 27° in this gesture
        #expect(cam.snapIndex == 1 && cam.isTurning)
    }

    @Test func oneTwistTurnsOnlyOneStepUntilTheFingersLift() {
        // Simulator check: a 60° twist turned the view twice (180°). One gesture = one 90° turn.
        var cam = OrbitCamera3D(def(), mapping: mapping)
        #expect(cam.twist(by: deg(30)) == true)
        #expect(cam.twist(by: deg(30)) == false)
        #expect(cam.twist(by: deg(60)) == false)
        #expect(cam.snapIndex == 1)
        cam.endTwist()
        #expect(cam.twist(by: deg(-30)) == true)
        #expect(cam.snapIndex == 0)
    }

    @Test func turnEasesAndLandsExactlyOnTheNextAngle() {
        var cam = OrbitCamera3D(def(turnSeconds: 0.4), mapping: mapping)
        cam.turn(steps: 1)
        cam.advance(seconds: 0.1)
        let quarter = cam.yaw
        cam.advance(seconds: 0.1)
        let half = cam.yaw
        #expect(near(half, deg(45 + 45)))                     // smoothstep is exactly halfway at half time
        #expect(quarter - deg(45) < half - quarter)           // eased: slow start
        cam.advance(seconds: 0.5)
        #expect(near(cam.yaw, deg(135)) && !cam.isTurning)
    }

    @Test func fourTurnsComeBackToTheStartViewWithoutSpinning() {
        var cam = OrbitCamera3D(def(turnSeconds: 0), mapping: mapping)
        for expected in [1, 2, 3, 0] {
            cam.turn(steps: 1)
            #expect(cam.facingIndex == expected)
        }
        cam.turn(steps: -1)
        #expect(cam.facingIndex == 3 && near(cam.yaw, deg(45 + 3 * 90)))  // −1 step from 360°+45°, not a full spin back
    }

    @Test func screenMiddleLooksAtTheTarget() throws {
        let cam = OrbitCamera3D(def(), mapping: mapping)
        let p = try #require(cam.groundPoint(screenX: 400, screenY: 200, viewWidth: 800, viewHeight: 400))
        #expect(near(p.x, cam.targetX) && near(p.z, cam.targetZ))
        #expect(cam.groundPoint(screenX: 400, screenY: -5000, viewWidth: 800, viewHeight: 400) == nil)  // sky
    }

    @Test func pinchZoomKeepsTheGroundUnderTheFingers() throws {
        var cam = OrbitCamera3D(def(startDistance: 30), mapping: mapping)
        cam.setViewAspect(2)
        let before = try #require(cam.groundPoint(screenX: 650, screenY: 120, viewWidth: 800, viewHeight: 400))
        cam.zoom(by: 1.5, toward: before)
        #expect(cam.distance < 30)
        let after = try #require(cam.groundPoint(screenX: 650, screenY: 120, viewWidth: 800, viewHeight: 400))
        #expect(near(after.x, before.x, 1e-6) && near(after.z, before.z, 1e-6))
    }

    @Test func pinchIsCalmerThanTheFingers() {
        var cam = OrbitCamera3D(def(startDistance: 30), mapping: mapping)
        cam.setViewAspect(1)
        cam.zoom(by: 2, toward: nil)
        #expect(cam.distance > 15 && near(cam.distance, 30 / pow(2, 0.6)))
    }

    @Test func cameraNeverGoesBelowTheMinimumHeight() {
        var cam = OrbitCamera3D(def(minHeight: 8, pitch: 25), mapping: mapping)
        cam.zoom(by: 100, toward: nil)
        #expect(cam.position.y >= 8 - 1e-9)
        #expect(cam.distance > 6)  // minDistance alone would let it go to 6 m (2.5 m up)
        cam.tilt(dy: 400)          // flatter view: the camera backs off to keep its height
        #expect(cam.position.y >= 8 - 1e-9)
    }

    @Test func zoomOutStopsWhenTheMapFillsTheScreen() {
        var cam = OrbitCamera3D(def(maxDistance: 500), mapping: mapping)
        cam.setViewAspect(2)
        cam.zoom(by: 0.0001, toward: nil)
        // Seen at 45°, the 40×30 map is (40 + 30)·cos45° ≈ 49.5 m wide; that width fills a 2:1 screen at ≈ 39 m.
        let expected = (40 + 30) * cos(deg(45)) / (2 * tan(deg(17.5)) * 2)
        #expect(near(cam.distance, expected, 1e-6))
        var capped = OrbitCamera3D(def(maxDistance: 25), mapping: mapping)
        capped.zoom(by: 0.0001, toward: nil)
        #expect(capped.distance == 25)
    }

    @Test func panMovesTheGroundWithTheFingerAndStopsNearTheMapEdge() {
        var cam = OrbitCamera3D(def(), mapping: mapping)
        let start = (cam.targetX, cam.targetZ)
        cam.pan(dx: 100, dy: 0, viewHeight: 400)  // finger right → ground right → camera looks further left
        let rightOnScreen = (x: cos(cam.yaw), z: -sin(cam.yaw))
        #expect((cam.targetX - start.0) * rightOnScreen.x + (cam.targetZ - start.1) * rightOnScreen.z < 0)
        for _ in 0..<200 { cam.pan(dx: -400, dy: -400, viewHeight: 400) }
        #expect(abs(cam.targetX) <= 22 + 1e-9 && abs(cam.targetZ) <= 17 + 1e-9)  // half map + 2-tile margin
    }

    @Test func lookAtCentersOnAPointButNotFarOffTheMap() {
        var cam = OrbitCamera3D(def(), mapping: mapping)
        cam.lookAt(x: -0.5, z: 3)
        #expect(cam.targetX == -0.5 && cam.targetZ == 3)
        cam.lookAt(x: 500, z: -500)
        #expect(cam.targetX == 22 && cam.targetZ == -17)
    }

    @Test func tiltStaysInsideItsLimits() {
        var cam = OrbitCamera3D(def(), mapping: mapping)
        cam.tilt(dy: -10_000)
        #expect(near(cam.pitch, deg(75)))
        cam.tilt(dy: 10_000)
        #expect(near(cam.pitch, deg(25)))
    }
}
