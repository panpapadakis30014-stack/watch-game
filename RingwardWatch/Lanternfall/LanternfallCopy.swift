import HordeCore

/// Every Lanternfall string that is built from values (English only).
enum LanternfallCopy {
    // MARK: Upgrades

    static func name(_ kind: UpgradeKind) -> String {
        switch kind {
        case .lanternBolt: return "Lantern Bolt"
        case .emberOrbit: return "Ember Orbit"
        case .saltBurst: return "Salt Burst"
        case .chainSpark: return "Chain Spark"
        case .swiftBoots: return "Swift Boots"
        case .thickCoat: return "Thick Coat"
        case .lodestone: return "Lodestone"
        case .quickHands: return "Quick Hands"
        case .keenWick: return "Keen Wick"
        case .secondWind: return "Second Wind"
        case .mending: return "Mending"
        case .hotTea: return "Hot Tea"
        }
    }

    /// One-line effect; `toLevel == 1` is the "new" wording.
    static func effect(_ kind: UpgradeKind, toLevel: Int) -> String {
        let isNew = toLevel == 1
        switch kind {
        case .lanternBolt: return "+1 damage, 10% faster"
        case .emberOrbit: return isNew ? "An ember circles you" : "+1 circling ember"
        case .saltBurst: return isNew ? "Blast foes back every 4 s" : "Bigger, harder blast"
        case .chainSpark: return isNew ? "Zaps 2 foes every 2 s" : "Zaps 1 more foe"
        case .swiftBoots: return "Walk 10% faster"
        case .thickCoat: return "+1 max heart, heal 1"
        case .lodestone: return "Pick up from 30% farther"
        case .quickHands: return "Weapons 8% quicker"
        case .keenWick: return "+15% weapon damage"
        case .secondWind: return "Dash ready 20% sooner"
        case .mending: return isNew ? "Heal 1 every 30 s" : "Heal 1 every 15 s"
        case .hotTea: return "Heal 2 hearts"
        }
    }

    static func levelLine(_ option: UpgradeOption) -> String {
        if option.kind == .hotTea { return "Bonus" }
        if option.fromLevel == 0 { return "New" }
        return "Lv \(option.fromLevel) → \(option.toLevel)"
    }

    static func levelSpoken(_ option: UpgradeOption) -> String {
        if option.kind == .hotTea { return "Bonus" }
        if option.fromLevel == 0 { return "New upgrade" }
        return "Level \(option.fromLevel) to \(option.toLevel)"
    }

    static func optionAccessibility(_ option: UpgradeOption) -> String {
        "\(name(option.kind)). \(effect(option.kind, toLevel: option.toLevel)). \(levelSpoken(option))."
    }

    static func levelUpTitle(_ heroLevel: Int) -> String {
        "Level \(heroLevel)"
    }

    static func levelUpAccessibility(_ heroLevel: Int) -> String {
        "Level up. Level \(heroLevel). Choose one upgrade."
    }

    // MARK: Time and counts

    /// `m:ss`, e.g. 3:05.
    static func clock(_ seconds: Int) -> String {
        let s = seconds % 60
        return "\(seconds / 60):" + (s < 10 ? "0" : "") + "\(s)"
    }

    static func spokenTime(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        let minutes = "\(m) " + (m == 1 ? "minute" : "minutes")
        let secs = "\(s) " + (s == 1 ? "second" : "seconds")
        if m == 0 { return secs }
        if s == 0 { return minutes }
        return "\(minutes) \(secs)"
    }

    static func killsLabel(_ kills: Int) -> String {
        kills == 1 ? "1 kill" : "\(kills) kills"
    }

    static func healthLabel(hp: Int, maxHP: Int) -> String {
        "Health \(hp) of \(maxHP)"
    }

    // MARK: Records

    static func pickerLine(_ r: HordeRecords) -> String {
        guard r.hasAny else { return "No runs yet" }
        if r.dawns > 0 { return "Dawns \(r.dawns) · \(killsLabel(r.mostKills))" }
        return "Best \(clock(r.bestSeconds)) · \(killsLabel(r.mostKills))"
    }

    static func pickerAccessibility(_ r: HordeRecords) -> String {
        guard r.hasAny else { return "Lanternfall. No runs yet" }
        if r.dawns > 0 { return "Lanternfall. Dawns reached \(r.dawns), most kills \(r.mostKills)" }
        return "Lanternfall. Longest night \(spokenTime(r.bestSeconds)), most kills \(r.mostKills)"
    }

    static func startRecordsLine(_ r: HordeRecords) -> String {
        guard r.hasAny else { return "No runs yet" }
        return "Best \(clock(r.bestSeconds)) · \(killsLabel(r.mostKills))"
    }

    static func startRecordsAccessibility(_ r: HordeRecords) -> String {
        guard r.hasAny else { return "No runs yet" }
        return "Longest night \(spokenTime(r.bestSeconds)), most kills \(r.mostKills)"
    }

    // MARK: Results

    static func outcomeTitle(_ outcome: LanternfallModel.Outcome) -> String {
        switch outcome {
        case .fallen: return "The lantern went out"
        case .dawn: return "Dawn breaks"
        case .ended: return "Run ended"
        }
    }

    static func resultsLine(_ s: HordeRunSummary) -> String {
        "\(killsLabel(s.kills)) · Level \(s.level)"
    }

    static func resultsAccessibility(_ s: HordeRunSummary) -> String {
        "\(killsLabel(s.kills)), level \(s.level)"
    }
}
