import Foundation
import Observation
import GameCore
import HordeCore
import FXCore

/// Runs one Lanternfall run: feeds frame time, Crown and taps into
/// `HordeGame` and turns its events into haptics and particle bursts.
/// Mirrors GameController.
@MainActor
@Observable
final class LanternfallController {
    private(set) var game: HordeGame
    let isFrozen: Bool
    /// Bursts on kills, hits and level-ups; run on game time so they freeze with it.
    private(set) var fx = ParticleSystem(capacity: FXPresets.lanternfallCapacity, seed: 0x4C41_4E46)

    @ObservationIgnored private var fxTime: Double
    @ObservationIgnored private var lastEffectScan: Double = -1
    @ObservationIgnored private var lastFrameDate: Date?
    @ObservationIgnored private var crownTracker = CrownTracker()
    @ObservationIgnored private var finished = false
    private let haptics: ThrottledHaptics
    private let onFinish: @MainActor (HordeRunSummary, LanternfallModel.Outcome) -> Void

    init(game: HordeGame, frozen: Bool, haptics: ThrottledHaptics,
         onFinish: @escaping @MainActor (HordeRunSummary, LanternfallModel.Outcome) -> Void) {
        self.game = game
        self.fxTime = game.elapsed
        self.isFrozen = frozen
        self.haptics = haptics
        self.onFinish = onFinish
    }

    /// True while the simulation should advance: not paused, no offer open,
    /// not over and not a frozen demo.
    var isRunning: Bool {
        game.isRunning && !isFrozen
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
        scanEffectsForBursts()
        fx.update(dt: game.elapsed - fxTime)
        fxTime = game.elapsed
        handle(events)
    }

    /// Reduce Motion turns particles off (none are spawned or drawn).
    func setReduceMotion(_ on: Bool) {
        fx.setEnabled(!on)
    }

    /// For the frozen mid-game screenshot: one kill burst at the enemy nearest
    /// the hero, aged a little so it reads as a burst.
    func seedDemoEffects() {
        let hero = game.hero.position
        guard let enemy = game.enemies.min(by: { ($0.position - hero).lengthSquared < ($1.position - hero).lengthSquared })
        else { return }
        fx.emit(FXPresets.lanternKillShambler, at: Self.fxPoint(enemy.position))
        fx.update(dt: 0.1)
    }

    /// Turns the core's new puff and hurt effects into particle bursts.
    private func scanEffectsForBursts() {
        for effect in game.effects where effect.start > lastEffectScan {
            switch effect.kind {
            case .puff(let radius):
                fx.emit(Self.killBurst(radius: radius, tuning: game.tuning), at: Self.fxPoint(effect.position))
            case .hurt:
                fx.emit(FXPresets.lanternHurt, at: Self.fxPoint(effect.position))
            case .saltRing, .spark:
                break
            }
        }
        lastEffectScan = game.elapsed
    }

    /// A puff's radius is the fallen enemy's radius, which tells the kinds apart.
    private static func killBurst(radius: Double, tuning: HordeTuning) -> BurstSpec {
        if radius == tuning.stats(for: .warden).radius { return FXPresets.lanternKillWarden }
        if radius == tuning.stats(for: .bloat).radius { return FXPresets.lanternKillBloat }
        if radius == tuning.stats(for: .sprinter).radius { return FXPresets.lanternKillSprinter }
        return FXPresets.lanternKillShambler
    }

    private static func fxPoint(_ v: Vec2) -> FXVec {
        FXVec(x: v.x, y: v.y)
    }

    func crownChanged(to value: Double) {
        let delta = crownTracker.delta(for: value)
        if isRunning {
            game.applyCrown(delta: delta)
        }
    }

    func tapArena() {
        if isRunning {
            handle(game.dash())
        }
    }

    func choose(_ index: Int) {
        guard !isFrozen else { return }
        let before = game.offer?.serial
        handle(game.choose(index))
        if game.offer?.serial != before {
            fx.emit(FXPresets.lanternLevelUp, at: Self.fxPoint(game.hero.position))
        }
        lastFrameDate = nil
    }

    func pause() {
        guard !isFrozen else { return }
        game.pause()
        lastFrameDate = nil
    }

    func resume() {
        game.resume()
        lastFrameDate = nil
    }

    /// Ends the run from the pause overlay; records are still saved.
    func endRun() {
        guard !isFrozen else { return }
        finish(.ended)
    }

    private func finish(_ outcome: LanternfallModel.Outcome) {
        guard !finished else { return }
        finished = true
        onFinish(game.summary, outcome)
    }

    private func handle(_ events: [HordeEvent]) {
        for event in events {
            switch event {
            case .dashed:
                haptics.play(.lfDash)
            case .hurt:
                haptics.play(.lfHurt)
            case .offerOpened:
                haptics.play(.lfLevelUp)
            case .bossArrived, .bossEnraged:
                haptics.play(.lfBoss)
            case .dawn:
                haptics.play(.lfDawn)
                finish(.dawn)
            case .fallen:
                haptics.play(.lfDeath)
                finish(.fallen)
            }
        }
    }
}
