import Foundation
import Observation
import GameCore

/// App-level state: which screen is showing, the best score and first-run flag.
@MainActor
@Observable
final class AppModel {
    enum Screen {
        case start
        case playing(GameController)
        case gameOver(RoundResult)
    }

    struct RoundResult {
        let score: Int
        let best: Int
        let isNewBest: Bool
    }

    static let hasPlayedKey = "ringward.hasPlayed"

    private(set) var screen: Screen
    private(set) var hasPlayed: Bool
    let isDemo: Bool
    private let keeper: BestScoreKeeper
    private let haptics: Haptics

    var best: Int { keeper.best }

    /// Identifies the current screen kind, for screen transitions.
    var screenKey: Int {
        switch screen {
        case .start: return 0
        case .playing: return 1
        case .gameOver: return 2
        }
    }

    /// Set by the game picker; nil when Ringward runs on its own (screenshot demos).
    var exitToPicker: (@MainActor () -> Void)? = nil

    init(options: LaunchOptions) {
        let demo = options.demo != nil
        isDemo = demo
        haptics = Haptics(isEnabled: !demo)
        switch options.demo {
        case .start?:
            keeper = BestScoreKeeper(store: InMemoryBestScoreStore(initial: 0))
            hasPlayed = false
            screen = .start
        case .midgame?:
            keeper = BestScoreKeeper(store: InMemoryBestScoreStore(initial: 0))
            hasPlayed = false
            let controller = GameController(
                game: DemoScenario.midGame(),
                frozen: true,
                haptics: Haptics(isEnabled: false),
                onGameOver: { _ in }
            )
            controller.seedDemoEffects()
            screen = .playing(controller)
        case nil:
            keeper = BestScoreKeeper(store: UserDefaultsBestScoreStore())
            hasPlayed = UserDefaults.standard.bool(forKey: AppModel.hasPlayedKey)
            screen = .start
        }
    }

    func startRound() {
        let controller = GameController(
            game: Game(seed: UInt64.random(in: .min ... .max)),
            frozen: false,
            haptics: haptics,
            onGameOver: { [weak self] score in
                self?.finishRound(score: score)
            }
        )
        screen = .playing(controller)
    }

    func retry() {
        startRound()
    }

    func showStart() {
        screen = .start
    }

    func leaveToPicker() {
        exitToPicker?()
    }

    private func finishRound(score: Int) {
        let isNew = keeper.submit(score)
        haptics.play(isNew ? .newBest : .gameOver)
        hasPlayed = true
        if !isDemo {
            UserDefaults.standard.set(true, forKey: Self.hasPlayedKey)
        }
        screen = .gameOver(RoundResult(score: score, best: keeper.best, isNewBest: isNew))
    }
}
