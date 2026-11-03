import Foundation
import Observation
import GameCore

/// Runs one round: feeds frame time and Crown input into `Game` and turns the
/// resulting events into haptics and short-lived visual effects.
@MainActor
@Observable
final class GameController {
    struct Effect {
        enum Kind {
            case spark(angle: Double)
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

    @ObservationIgnored private var lastFrameDate: Date?
    @ObservationIgnored private var crownTracker = CrownTracker()
    private let haptics: Haptics
    private let onGameOver: @MainActor (Int) -> Void

    init(game: Game, frozen: Bool, haptics: Haptics, onGameOver: @escaping @MainActor (Int) -> Void) {
        self.game = game
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
        pruneEffects()
        handle(events)
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
                addEffect(.spark(angle: angle))
            case .hit:
                haptics.play(.hit)
                lastHitTime = game.elapsed
                addEffect(.hitFlash)
            case .pulseReady:
                haptics.play(.pulseReady)
            case .pulse:
                haptics.play(.pulse)
                addEffect(.pulseRing)
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
