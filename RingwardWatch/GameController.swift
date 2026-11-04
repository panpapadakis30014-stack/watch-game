import Foundation
import Observation
import GameCore
import FXCore

/// Runs one round: feeds frame time and Crown input into `Game` and turns the
/// resulting events into haptics, short-lived effects and particle bursts.
@MainActor
@Observable
final class GameController {
    struct Effect {
        enum Kind {
            case pulseRing
            case hitFlash
        }

        let kind: Kind
        let start: Double   // in game.elapsed seconds, so effects freeze with the game
    }

    static let effectLifetime: Double = 0.4
    static let maxEffects = 24

    private(set) var game: Game
    let isFrozen: Bool
    private(set) var effects: [Effect] = []
    private(set) var lastHitTime: Double?
    /// Particle bursts on block, hit and Pulse; run on game time so they freeze with it.
    private(set) var fx = ParticleSystem(capacity: FXPresets.ringwardCapacity, seed: 0x5249_4E47)

    @ObservationIgnored private var fxTime: Double
    @ObservationIgnored private var lastFrameDate: Date?
    @ObservationIgnored private var crownTracker = CrownTracker()
    private let haptics: Haptics
    private let onGameOver: @MainActor (Int) -> Void

    init(game: Game, frozen: Bool, haptics: Haptics, onGameOver: @escaping @MainActor (Int) -> Void) {
        self.game = game
        self.fxTime = game.elapsed
        self.isFrozen = frozen
        self.haptics = haptics
        self.onGameOver = onGameOver
    }

    /// True while the simulation should advance. False when paused, over or a frozen demo.
    var isRunning: Bool {
        game.phase == .playing && !isFrozen
    }

    func tick(now: Date) {
        guard isRunning else {
            lastFrameDate = nil
            return
        }
        guard let last = lastFrameDate else {
            lastFrameDate = now
            return
        }
        lastFrameDate = now
        let events = game.advance(by: now.timeIntervalSince(last))
        fx.update(dt: game.elapsed - fxTime)
        fxTime = game.elapsed
        pruneEffects()
        handle(events)
    }

    /// Reduce Motion turns particles off (none are spawned or drawn).
    func setReduceMotion(_ on: Bool) {
        fx.setEnabled(!on)
    }

    /// For the frozen mid-game screenshot: one block burst at the shard nearest
    /// the shield, aged a little so it reads as a burst.
    func seedDemoEffects() {
        guard let shard = game.shards.min(by: {
            abs(AngleMath.signedDelta(from: game.shieldAngle, to: $0.angle))
                < abs(AngleMath.signedDelta(from: game.shieldAngle, to: $1.angle))
        }) else { return }
        fx.emit(FXPresets.ringwardBlock, at: Self.point(shard.angle, game.tuning.shieldRadius),
                direction: Self.point(shard.angle, 1))
        fx.update(dt: 0.1)
    }

    /// Arena point at `degrees` (0 = up, clockwise) and `r` arena radii.
    private static func point(_ degrees: Double, _ r: Double) -> FXVec {
        let a = degrees * .pi / 180
        return FXVec(x: r * sin(a), y: -r * cos(a))
    }

    func crownChanged(to value: Double) {
        let delta = crownTracker.delta(for: value)
        if isRunning {
            game.applyCrown(delta: delta)
        }
    }

    func tapArena() {
        if isRunning {
            handle(game.usePulse())
        }
    }

    /// Frozen demo states never pause, so the screenshot shows the live round.
    func pause() {
        guard !isFrozen else { return }
        game.pause()
        lastFrameDate = nil
    }

    func resume() {
        game.resume()
        lastFrameDate = nil
    }

    private func handle(_ events: [GameEvent]) {
        for event in events {
            switch event {
            case .blocked(let angle, _, _):
                haptics.play(.block)
                fx.emit(FXPresets.ringwardBlock, at: Self.point(angle, game.tuning.shieldRadius),
                        direction: Self.point(angle, 1))
            case .hit(let angle, _):
                haptics.play(.hit)
                lastHitTime = game.elapsed
                addEffect(.hitFlash)
                fx.emit(FXPresets.ringwardHit, at: Self.point(angle, game.tuning.coreRadius),
                        direction: Self.point(angle, 1))
            case .pulseReady:
                haptics.play(.pulseReady)
            case .pulse:
                haptics.play(.pulse)
                addEffect(.pulseRing)
                fx.emit(FXPresets.ringwardPulse, at: .zero)
            case .gameOver(let finalScore):
                // The game-over / new-best haptic is played by AppModel.
                onGameOver(finalScore)
            }
        }
    }

    private func addEffect(_ kind: Effect.Kind) {
        effects.append(Effect(kind: kind, start: game.elapsed))
        if effects.count > Self.maxEffects {
            effects.removeFirst(effects.count - Self.maxEffects)
        }
    }

    private func pruneEffects() {
        let now = game.elapsed
        if effects.contains(where: { now - $0.start > Self.effectLifetime }) {
            effects.removeAll { now - $0.start > Self.effectLifetime }
        }
    }
}
