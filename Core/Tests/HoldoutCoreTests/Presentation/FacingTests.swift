// Purpose: Facing image choice for screen directions, including the wrap around east. Notes: docs/features/rendering-art.md
import Foundation
import Testing
@testable import HoldoutCore

struct FacingTests {
    private func deg(_ d: Double) -> Double { d * .pi / 180 }

    @Test func fourFacingsPickTheNearestDiagonal() {
        #expect(Facing.name(screenAngle: deg(30), facings: 4) == "ne")
        #expect(Facing.name(screenAngle: deg(100), facings: 4) == "nw")
        #expect(Facing.name(screenAngle: deg(200), facings: 4) == "sw")
        #expect(Facing.name(screenAngle: deg(300), facings: 4) == "se")
    }

    @Test func fourFacingsWrapCorrectlyJustBelowEast() {
        // Review finding: -5° / 355° picked NE instead of the nearer SE.
        #expect(Facing.name(screenAngle: deg(355), facings: 4) == "se")
        #expect(Facing.name(screenAngle: deg(-5), facings: 4) == "se")
        #expect(Facing.name(screenAngle: deg(5), facings: 4) == "ne")
    }

    @Test func eightFacingsPickTheNearest() {
        #expect(Facing.name(screenAngle: deg(359), facings: 8) == "e")
        #expect(Facing.name(screenAngle: deg(-90), facings: 8) == "s")
        #expect(Facing.name(screenAngle: deg(140), facings: 8) == "nw")
    }
}
