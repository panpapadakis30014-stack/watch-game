import Foundation
import GameCore

/// Persists the best score on the watch through UserDefaults.
struct UserDefaultsBestScoreStore: BestScoreStore {
    static let key = "ringward.bestScore"

    let defaults: UserDefaults = .standard

    func loadBest() -> Int {
        defaults.integer(forKey: Self.key)
    }

    func saveBest(_ score: Int) {
        defaults.set(score, forKey: Self.key)
    }
}
