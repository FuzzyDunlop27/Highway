// Purpose: Tests the fixed tick: speed, pause, frame cap, determinism, and commands. Notes: docs/features/core-api.md
import Testing
@testable import HoldoutCore

struct GameLoopTests {
    @Test func oneSecondAtOneXRunsTicksPerSecond() throws {
        let loop = try TestSupport.loop()
        var ran = 0
        for _ in 0..<10 { ran += loop.advance(realSeconds: 0.1) }
        #expect(ran == loop.content.economy.ticksPerSecond)
        #expect(loop.state.tick == ran)
    }

    @Test func doubleSpeedRunsTwiceAsManyAndPauseRunsNone() throws {
        let loop = try TestSupport.loop()
        #expect(loop.send(.setSpeed(2)) == .success(.speedSet))
        #expect(loop.advance(realSeconds: 0.1) == 2 * loop.content.economy.ticksPerSecond / 10)
        loop.send(.setSpeed(0))
        #expect(loop.advance(realSeconds: 0.1) == 0)
        #expect(loop.send(.setSpeed(7)) == .failure(.invalidSpeed(7)))
    }

    @Test func longFrameIsCappedAtMaxFrameSeconds() throws {
        let loop = try TestSupport.loop()
        let e = loop.content.economy
        let expected = Int(e.maxFrameSeconds * Double(e.ticksPerSecond)) // whole ticks; the rest carries over
        #expect(loop.advance(realSeconds: 3600) == expected)
    }

    @Test func sameSeedAndCommandsGiveSameState() throws {
        func play() throws -> GameState {
            let loop = try TestSupport.loop(seed: 7)
            loop.send(.placeBuilding(defId: "farm", at: TestSupport.grassSpot))
            loop.step(ticks: 5000)
            return loop.state
        }
        #expect(try play() == play())
    }

    @Test func sameSeedGivesSameRandomNumbers() {
        var a = SeededRandom(seed: 99), b = SeededRandom(seed: 99), c = SeededRandom(seed: 100)
        let first = (0..<5).map { _ in a.next() }
        #expect(first == (0..<5).map { _ in b.next() })
        #expect(first != (0..<5).map { _ in c.next() })
    }
}
