import Foundation
import Observation
import HordeCore

/// Lanternfall's app-level state: which screen is showing, the records and
/// the first-run flag.
@MainActor
@Observable
final class LanternfallModel {
    enum Screen {
        case start
        case playing(LanternfallController)
        case results(RunResult)
    }

    enum Outcome {
        case fallen, dawn, ended
    }

    struct RunResult {
        let summary: HordeRunSummary
        let outcome: Outcome
        let update: HordeRecordsUpdate
        let records: HordeRecords
    }

    static let hasPlayedKey = "lanternfall.hasPlayed"

    private(set) var screen: Screen
    private(set) var hasPlayed: Bool
    let isDemo: Bool
    private let keeper: HordeRecordsKeeper
    private let haptics: ThrottledHaptics

    var records: HordeRecords { keeper.records }

    /// Set by the game picker.
    var exitToPicker: (@MainActor () -> Void)? = nil

    init(demo: LanternfallDemoMode?) {
        let isDemo = demo != nil
        self.isDemo = isDemo
        haptics = ThrottledHaptics(Haptics(isEnabled: !isDemo))
        switch demo {
        case nil:
            keeper = HordeRecordsKeeper(store: UserDefaultsHordeRecordsStore())
            hasPlayed = UserDefaults.standard.bool(forKey: LanternfallModel.hasPlayedKey)
            screen = .start
        case .picker?, .start?:
            keeper = HordeRecordsKeeper(store: InMemoryHordeRecordsStore())
            hasPlayed = false
            screen = .start
        case .midgame?, .levelup?:
            keeper = HordeRecordsKeeper(store: InMemoryHordeRecordsStore())
            hasPlayed = false
            let game = demo == .midgame ? HordeDemo.midGame() : HordeDemo.levelUpOffer()
            screen = .playing(LanternfallController(
                game: game,
                frozen: true,
                haptics: ThrottledHaptics(Haptics(isEnabled: false)),
                onFinish: { _, _ in }
            ))
        }
    }

    func showStart() {
        screen = .start
    }

    func startRun() {
        let controller = LanternfallController(
            game: HordeGame(seed: UInt64.random(in: .min ... .max)),
            frozen: false,
            haptics: haptics,
            onFinish: { [weak self] summary, outcome in
                self?.finish(summary: summary, outcome: outcome)
            }
        )
        screen = .playing(controller)
    }

    func playAgain() {
        startRun()
    }

    func leaveToPicker() {
        exitToPicker?()
    }

    private func finish(summary: HordeRunSummary, outcome: Outcome) {
        let update = keeper.submit(summary)
        hasPlayed = true
        if !isDemo {
            UserDefaults.standard.set(true, forKey: LanternfallModel.hasPlayedKey)
        }
        screen = .results(RunResult(summary: summary, outcome: outcome, update: update, records: keeper.records))
    }
}
