import Foundation
import Observation
import GameCore
import HordeCore

/// Runs one Lanternfall run: feeds frame time, Crown and taps into
/// `HordeGame` and turns its events into haptics. Mirrors GameController.
@MainActor
@Observable
final class LanternfallController {
    private(set) var game: HordeGame
    let isFrozen: Bool

    @ObservationIgnored private var lastFrameDate: Date?
    @ObservationIgnored private var crownTracker = CrownTracker()
    @ObservationIgnored private var finished = false
    private let haptics: ThrottledHaptics
    private let onFinish: @MainActor (HordeRunSummary, LanternfallModel.Outcome) -> Void

    init(game: HordeGame, frozen: Bool, haptics: ThrottledHaptics,
         onFinish: @escaping @MainActor (HordeRunSummary, LanternfallModel.Outcome) -> Void) {
        self.game = game
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
        handle(game.advance(by: now.timeIntervalSince(last)))
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
        handle(game.choose(index))
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
