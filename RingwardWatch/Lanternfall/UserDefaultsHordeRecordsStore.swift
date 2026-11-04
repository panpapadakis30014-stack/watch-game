import Foundation
import HordeCore

/// Persists Lanternfall's records on the watch through UserDefaults.
struct UserDefaultsHordeRecordsStore: HordeRecordsStore {
    static let bestSecondsKey = "lanternfall.bestSeconds"
    static let mostKillsKey = "lanternfall.mostKills"
    static let dawnsKey = "lanternfall.dawns"

    let defaults: UserDefaults = .standard

    func loadRecords() -> HordeRecords {
        HordeRecords(
            bestSeconds: defaults.integer(forKey: Self.bestSecondsKey),
            mostKills: defaults.integer(forKey: Self.mostKillsKey),
            dawns: defaults.integer(forKey: Self.dawnsKey)
        )
    }

    func saveRecords(_ records: HordeRecords) {
        defaults.set(records.bestSeconds, forKey: Self.bestSecondsKey)
        defaults.set(records.mostKills, forKey: Self.mostKillsKey)
        defaults.set(records.dawns, forKey: Self.dawnsKey)
    }
}
