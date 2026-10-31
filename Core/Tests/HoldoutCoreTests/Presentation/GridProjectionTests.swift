// Purpose: Tile ↔ screen math for both views: round trips, corners, draw order, and the presentation.json views. Notes: docs/features/rendering-art.md
import Foundation
import Testing
@testable import HoldoutCore

struct GridProjectionTests {
    static let iso = GridProjection(kind: .isometric, tileWidth: 64, tileHeight: 32, mapWidth: 40, mapHeight: 30)
    static let top = GridProjection(kind: .topDown, tileWidth: 32, tileHeight: 32, mapWidth: 40, mapHeight: 30)

    @Test(arguments: [iso, top])
    func everyTileRoundTrips(_ p: GridProjection) {
        for y in 0..<p.mapHeight {
            for x in 0..<p.mapWidth {
                let c = p.center(origin: GridPoint(x: x, y: y), width: 1, height: 1)
                #expect(p.tile(sx: c.x, sy: c.y) == GridPoint(x: x, y: y))
            }
        }
    }

    @Test(arguments: [iso, top])
    func mapCornersStayInsideMapBox(_ p: GridProjection) {
        let size = p.mapSize
        for (gx, gy) in [(0.0, 0.0), (40.0, 0.0), (40.0, 30.0), (0.0, 30.0)] {
            let s = p.screen(gx: gx, gy: gy)
            #expect(s.x >= -1e-9 && s.x <= size.x + 1e-9 && s.y >= -1e-9 && s.y <= size.y + 1e-9)
        }
    }

    @Test func isometricIsADiamond() {
        let p = Self.iso
        #expect(p.screen(gx: 0, gy: 0) == .init(x: 30 * 32, y: 70 * 16))      // north-west corner = top point
        #expect(p.screen(gx: 40, gy: 30) == .init(x: 40 * 32, y: 0))         // south-east corner = bottom point
        #expect(p.mapSize == .init(x: 70 * 32, y: 70 * 16))
        // One tile is a 64×32 diamond.
        let o = p.outline(origin: GridPoint(x: 5, y: 5), width: 1, height: 1)
        #expect(o[1].x - o[3].x == 64 && o[0].y - o[2].y == 32)
    }

    @Test func groundAnchorIsFrontCornerInIsoAndCenterTopDown() {
        let origin = GridPoint(x: 10, y: 12)
        #expect(Self.iso.groundAnchor(origin: origin, width: 2, height: 2) == Self.iso.screen(gx: 12, gy: 14))
        #expect(Self.top.groundAnchor(origin: origin, width: 2, height: 2) == Self.top.center(origin: origin, width: 2, height: 2))
        #expect(Self.iso.footprintWidth(width: 2, height: 2) == 128)
    }

    @Test func thingsInFrontDrawInFront() {
        let p = Self.iso
        // A 2×2 building at (10,10): a unit south-east of it is in front, one north-west is behind.
        let building = p.depth(gx: 11, gy: 11)
        #expect(p.depth(gx: 12.5, gy: 10.5) > building)   // east neighbor (lower right on screen)
        #expect(p.depth(gx: 10.5, gy: 12.5) > building)   // south neighbor (lower left)
        #expect(p.depth(gx: 9.5, gy: 10.5) < building)    // west neighbor (upper left)
        #expect(p.depth(gx: 10.5, gy: 9.5) < building)    // north neighbor (upper right)
        // Lower on screen = in front.
        #expect(p.screen(gx: 12.5, gy: 10.5).y < p.screen(gx: 11, gy: 11).y)
    }

    @Test func presentationFileHasBothViews() throws {
        let presentation = try TestSupport.content().presentation
        for kind in ProjectionKind.allCases {
            let view = try #require(presentation.view(kind))
            #expect(view.projection == kind)
        }
        #expect(presentation.view(.isometric)?.tileWidthPt == 2 * (presentation.view(.isometric)?.tileHeightPt ?? 0))
    }
}
