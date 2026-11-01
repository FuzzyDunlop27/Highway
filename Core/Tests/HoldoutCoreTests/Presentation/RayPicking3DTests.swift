// Purpose: 3D touches: finger ray, nearest building box (tall roof in front wins), what hides the ghost. Notes: docs/features/input.md
import Foundation
import Testing
@testable import HoldoutCore

struct RayPicking3DTests {
    private let mapping = WorldMapping3D(metresPerTile: 1, mapWidth: 40, mapHeight: 30)
    private typealias P = WorldMapping3D.Point3

    private func camera(snap: Int = 0) -> OrbitCamera3D {
        let def = Camera3DDef(fieldOfViewDegrees: 35, startDistance: 20, minDistance: 6, maxDistance: 50, minHeightMetres: 4,
                              startPitchDegrees: 40, minPitchDegrees: 25, maxPitchDegrees: 75, tiltDegreesPerPoint: 0.25,
                              startYawDegrees: 45, snapAngles: 4, twistThresholdDegrees: 25, snapTurnSeconds: 0,
                              pinchSensitivity: 0.6, panMarginTiles: 2)
        var cam = OrbitCamera3D(def, mapping: mapping)
        cam.setViewAspect(2)
        if snap != 0 { cam.turn(steps: snap) }
        return cam
    }

    private func box(_ x: Int, _ y: Int, size: Int = 1, tall: Double) -> Box3D {
        Box3D(footprint: GridPoint(x: x, y: y), width: size, height: size, tall: tall, mapping: mapping)
    }

    @Test func screenMiddleRayHitsTheLookedAtGroundPoint() throws {
        var cam = camera()
        cam.lookAt(x: 3, z: -2)
        let ray = try #require(cam.ray(screenX: 400, screenY: 200, viewWidth: 800, viewHeight: 400))
        let hit = try #require(ray.groundHit)
        #expect(abs(hit.x - 3) < 1e-6 && abs(hit.z + 2) < 1e-6)
        #expect(ray.origin == cam.position)
    }

    @Test func rayStraightDownHitsTheBoxRoofAndMissesNeighbours() {
        let down = Ray3D(origin: P(x: 0.5, y: 10, z: 0.5), direction: P(x: 0, y: -1, z: 0))
        let tile = mapping.tile(x: 0.5, z: 0.5)
        let under = box(tile.x, tile.y, tall: 2)
        let beside = box(tile.x + 2, tile.y, tall: 2)
        #expect(RayPicking3D.hitDistance(down, under) == 8)  // roof at 2 m
        #expect(RayPicking3D.hitDistance(down, beside) == nil)
    }

    @Test func tallRoofInFrontWinsOverTheBuildingBehindIt() {
        // Looking north (−z) at a low slant: a tall tower in front covers a low shed further north on the same line.
        let ray = Ray3D(origin: P(x: 0.5, y: 6, z: 10), direction: P(x: 0, y: -0.3, z: -1))
        let tile = mapping.tile(x: 0.5, z: 0.5)
        let shed = box(tile.x, tile.y - 4, tall: 2.5)
        let tower = box(tile.x, tile.y, tall: 4)
        let boxes: [(id: Int, box: Box3D)] = [(1, shed), (2, tower)]
        #expect(RayPicking3D.nearest(ray, boxes: [(1, shed)]) == 1)  // the ray does reach the shed...
        #expect(RayPicking3D.nearest(ray, boxes: boxes) == 2)  // ...but the tower in front is hit first
        #expect(RayPicking3D.nearest(Ray3D(origin: P(x: 30, y: 6, z: 10), direction: P(x: 0, y: -0.3, z: -1)), boxes: boxes) == nil)
    }

    @Test func aBuildingBetweenTheCameraAndTheGhostHidesItFromEveryAngle() {
        // Ghost at the map middle; a tall building one tile toward each camera angle hides it only from that angle.
        let ghost = box(19, 14, size: 2, tall: 1).inset(0.1)
        for snap in 0..<4 {
            var cam = camera(snap: snap)
            cam.advance(seconds: 1)
            cam.lookAt(x: 0, z: 0)
            let eye = cam.position
            let toward = (x: eye.x > 0 ? 1 : -1, y: eye.z > 0 ? 1 : -1)  // the tile corner nearest the camera
            let front = box(19 + (toward.x > 0 ? 2 : -1), 14 + (toward.y > 0 ? 2 : -1), tall: 6)
            let back = box(19 + (toward.x > 0 ? -2 : 3), 14 + (toward.y > 0 ? -2 : 3), tall: 6)
            let hidden = RayPicking3D.occluders(eye: eye, targets: ghost.corners + [ghost.center],
                                                boxes: [(id: "front", box: front), (id: "back", box: back)])
            #expect(hidden == ["front"], "snap \(snap)")
        }
    }

    @Test func skyRayHasNoGroundPoint() {
        #expect(Ray3D(origin: P(x: 0, y: 5, z: 0), direction: P(x: 0, y: 0.1, z: -1)).groundHit == nil)
    }
}
