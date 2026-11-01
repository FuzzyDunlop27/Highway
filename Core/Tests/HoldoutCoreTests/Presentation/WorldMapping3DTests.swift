// Purpose: Tile ↔ 3D world metres for the RealityKit view: map middle at the origin, +X east, +Z south. Notes: docs/features/rendering-art.md
import Foundation
import Testing
@testable import HoldoutCore

struct WorldMapping3DTests {
    private let m = WorldMapping3D(metresPerTile: 1, mapWidth: 40, mapHeight: 30)

    private func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }

    @Test func mapMiddleIsTheOriginAndCornersAreHalfTheMapAway() {
        #expect(m.world(gx: 20, gy: 15) == .init(x: 0, y: 0, z: 0))
        #expect(m.world(gx: 0, gy: 0) == .init(x: -20, y: 0, z: -15))      // north-west corner: west (−X) and north (−Z)
        #expect(m.world(gx: 40, gy: 30, height: 2) == .init(x: 20, y: 2, z: 15))
        #expect(m.halfExtent.x == 20 && m.halfExtent.z == 15)
    }

    @Test func eastIsPlusXAndSouthIsPlusZ() {
        let a = m.world(gx: 10, gy: 10), east = m.world(gx: 11, gy: 10), south = m.world(gx: 10, gy: 11)
        #expect(east.x - a.x == 1 && east.z == a.z)
        #expect(south.z - a.z == 1 && south.x == a.x)
    }

    @Test func metresPerTileScalesEverything() {
        let big = WorldMapping3D(metresPerTile: 2, mapWidth: 40, mapHeight: 30)
        #expect(big.world(gx: 0, gy: 0) == .init(x: -40, y: 0, z: -30))
        let size = big.footprintSize(width: 3, height: 2)
        #expect(size.x == 6 && size.z == 4)
    }

    @Test func groundPointsRoundTripToTheSameTile() {
        for (gx, gy) in [(0.5, 0.5), (12.25, 7.75), (39.9, 29.9)] {
            let p = m.world(gx: gx, gy: gy)
            let back = m.grid(x: p.x, z: p.z)
            #expect(near(back.gx, gx) && near(back.gy, gy))
            #expect(m.tile(x: p.x, z: p.z) == GridPoint(x: Int(gx), y: Int(gy)))
        }
        #expect(m.tile(x: -20.5, z: 0) == GridPoint(x: -1, y: 15))  // off the map to the west
    }

    @Test func footprintCenterIsTheGroundMiddle() {
        #expect(m.footprintCenter(origin: GridPoint(x: 18, y: 13), width: 3, height: 3) == .init(x: -0.5, y: 0, z: -0.5))
        #expect(m.footprintCenter(origin: GridPoint(x: 0, y: 0), width: 1, height: 1) == .init(x: -19.5, y: 0, z: -14.5))
    }

    @Test func yawTurnsAnEastFacingModelAlongTheHeading() {
        // RealityKit turns +X by angle θ about +Y to (cos θ, 0, −sin θ); the heading direction is (cos h, 0, sin h).
        for heading in [0, Double.pi / 2, Double.pi, -Double.pi / 2, 0.7] {
            let yaw = WorldMapping3D.yaw(heading: heading)
            #expect(near(cos(yaw), cos(heading)) && near(-sin(yaw), sin(heading)))
        }
    }
}
