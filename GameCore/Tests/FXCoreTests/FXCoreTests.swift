import XCTest
@testable import FXCore

final class FXCoreTests: XCTestCase {
    private let spec20 = BurstSpec(count: 20, speedMin: 0.2, speedMax: 1.0, lifeMin: 0.3, lifeMax: 0.8,
                                   sizeMin: 0.01, sizeMax: 0.03, drag: 2, gravity: 0, spread: 0.5, style: 0)

    func testCapNeverExceededWith1000Bursts() {
        var fx = ParticleSystem(capacity: 48, seed: 1)
        for i in 0..<1000 {
            XCTAssertEqual(fx.emit(spec20, at: .zero, direction: i % 2 == 0 ? FXVec(x: 0, y: -1) : nil), 20)
            XCTAssertLessThanOrEqual(fx.count, 48)
            fx.update(dt: 1.0 / 30.0)
            XCTAssertLessThanOrEqual(fx.count, 48)
        }
    }

    func testParticlesExpireOnTime() {
        var fx = ParticleSystem(capacity: 48, seed: 2)
        var spec = spec20
        spec.count = 10
        spec.lifeMin = 0.5
        spec.lifeMax = 0.5
        fx.emit(spec, at: .zero)
        for _ in 0..<49 { fx.update(dt: 0.01) }
        XCTAssertEqual(fx.count, 10)
        fx.update(dt: 0.01)
        fx.update(dt: 0.01)
        XCTAssertEqual(fx.count, 0)
    }

    private func script(seed: UInt64) -> ParticleSystem {
        var fx = ParticleSystem(capacity: 36, seed: seed)
        for i in 0..<30 {
            fx.emit(spec20, at: FXVec(x: Double(i) * 0.1, y: 0), direction: i % 3 == 0 ? nil : FXVec(x: 1, y: 1))
            fx.update(dt: 1.0 / 60.0)
        }
        return fx
    }

    func testSameSeedSameOutput() {
        XCTAssertEqual(script(seed: 7), script(seed: 7))
        XCTAssertNotEqual(script(seed: 8), script(seed: 7))
    }

    func testReduceMotionSpawnsNothing() {
        var off = ParticleSystem(capacity: 48, seed: 3, enabled: false)
        XCTAssertEqual(off.emit(spec20, at: .zero), 0)
        XCTAssertEqual(off.count, 0)

        var fx = ParticleSystem(capacity: 48, seed: 3)
        fx.emit(spec20, at: .zero)
        fx.emit(spec20, at: .zero)
        XCTAssertEqual(fx.count, 40)
        fx.setEnabled(false)
        XCTAssertEqual(fx.count, 0)
        XCTAssertEqual(fx.emit(spec20, at: .zero), 0)
        XCTAssertEqual(fx.count, 0)
        fx.setEnabled(true)
        XCTAssertEqual(fx.emit(spec20, at: .zero), 20)
    }

    func testOldestDroppedFirstWhenFull() {
        var fx = ParticleSystem(capacity: 4, seed: 4)
        for style in 0..<3 {
            var spec = spec20
            spec.count = 2
            spec.style = style
            fx.emit(spec, at: .zero)
        }
        XCTAssertEqual(fx.particles.map(\.style), [1, 1, 2, 2])
    }

    func testZeroSpreadFollowsDirection() {
        var fx = ParticleSystem(capacity: 48, seed: 5)
        var spec = spec20
        spec.spread = 0
        fx.emit(spec, at: .zero, direction: FXVec(x: 0, y: -1))
        for p in fx.particles {
            XCTAssertEqual(p.velocity.x, 0, accuracy: 1e-12)
            XCTAssertLessThan(p.velocity.y, 0)
        }
    }

    func testUpdateIntegratesDragAndGravity() {
        var fx = ParticleSystem(capacity: 4, seed: 6)
        let spec = BurstSpec(count: 1, speedMin: 1, speedMax: 1, lifeMin: 5, lifeMax: 5, sizeMin: 0.02, sizeMax: 0.02,
                             drag: 2, gravity: 1, spread: 0, style: 0)
        fx.emit(spec, at: .zero, direction: FXVec(x: 1, y: 0))
        fx.update(dt: 0.1)
        let p = fx.particles[0]
        XCTAssertEqual(p.velocity.x, 0.8, accuracy: 1e-12)
        XCTAssertEqual(p.velocity.y, 0.1, accuracy: 1e-12)
        XCTAssertEqual(p.position.x, 0.08, accuracy: 1e-12)
        XCTAssertEqual(p.position.y, 0.01, accuracy: 1e-12)
    }

    func testOpacityAndRadiusCurves() {
        var p = Particle(position: .zero, velocity: .zero, age: 0, life: 1, size: 0.05, drag: 0, gravity: 0, style: 0)
        XCTAssertEqual(p.opacity, 1, accuracy: 1e-12)
        XCTAssertEqual(p.radius, 0.05, accuracy: 1e-12)
        p.age = 0.5
        XCTAssertEqual(p.opacity, 0.75, accuracy: 1e-12)
        p.age = 1
        XCTAssertEqual(p.opacity, 0, accuracy: 1e-12)
        XCTAssertEqual(p.radius, 0.03, accuracy: 1e-12)
    }

    func testPresetsFitTheirScreens() {
        for spec in FXPresets.ringwardSpecs {
            XCTAssertLessThanOrEqual(spec.count, FXPresets.ringwardCapacity)
        }
        for spec in FXPresets.lanternfallSpecs {
            XCTAssertLessThanOrEqual(spec.count, FXPresets.lanternfallCapacity)
        }
        XCTAssertLessThanOrEqual(FXPresets.ringwardCapacity, FXPresets.maxScreenCapacity)
        XCTAssertLessThanOrEqual(FXPresets.lanternfallCapacity, FXPresets.maxScreenCapacity)
    }
}
