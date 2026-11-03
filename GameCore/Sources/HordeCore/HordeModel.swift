public enum EnemyKind: Equatable, CaseIterable {
    case shambler, sprinter, bloat, warden
}

public struct Enemy: Equatable, Identifiable {
    public let id: Int
    public let kind: EnemyKind
    public internal(set) var position: Vec2
    public internal(set) var hp: Double
    public let maxHP: Double
    public internal(set) var emberCooldown: Double = 0
    public internal(set) var hitFlash: Double = 0
}

public struct Projectile: Equatable, Identifiable {
    public let id: Int
    public internal(set) var position: Vec2
    public let velocity: Vec2
    public let damage: Double
    public internal(set) var life: Double
}

public struct Gem: Equatable, Identifiable {
    public let id: Int
    public internal(set) var position: Vec2
    public internal(set) var value: Int
    public internal(set) var magnetized: Bool = false
}

public struct Hero: Equatable {
    public internal(set) var position: Vec2 = .zero
    public internal(set) var heading: Double = 0
    public internal(set) var hp: Int
    public internal(set) var iFrames: Double = 0
    public internal(set) var dashRemaining: Double = 0
    public internal(set) var dashCooldownRemaining: Double = 0
}

/// Short-lived visual effect. Lives in the core so it freezes and is capped
/// together with the simulation.
public struct HordeEffect: Equatable {
    public enum Kind: Equatable {
        case puff(radius: Double)
        case saltRing(radius: Double)
        case spark(to: Vec2)
        case hurt
    }

    public let kind: Kind
    public let position: Vec2
    public let start: Double
    public let duration: Double
}

public enum UpgradeKind: Int, CaseIterable, Equatable {
    case lanternBolt, emberOrbit, saltBurst, chainSpark, swiftBoots, thickCoat,
         lodestone, quickHands, keenWick, secondWind, mending, hotTea

    /// Highest level; 0 means unlimited (Hot Tea, which is never in the pool).
    public var maxLevel: Int {
        switch self {
        case .lanternBolt: return 5
        case .emberOrbit, .saltBurst, .chainSpark: return 4
        case .swiftBoots, .thickCoat, .lodestone, .quickHands, .keenWick: return 3
        case .secondWind, .mending: return 2
        case .hotTea: return 0
        }
    }
}

public struct UpgradeOption: Equatable {
    public let kind: UpgradeKind
    public let fromLevel: Int     // Hot Tea: 0
    public let toLevel: Int       // Hot Tea: 0
}

public struct UpgradeOffer: Equatable {
    public let serial: Int
    public let heroLevel: Int
    public let options: [UpgradeOption]
}

public enum HordePhase: Equatable {
    case playing, fallen, dawn
}

public enum HordeEvent: Equatable {
    case dashed
    case hurt(hpLeft: Int)
    case offerOpened(heroLevel: Int)
    case bossArrived
    case bossEnraged
    case dawn
    case fallen
}

/// The hero's effective numbers for a set of upgrade levels.
public struct HeroStats: Equatable {
    public var moveSpeed: Double
    public var pickupRadius: Double
    public var damageScale: Double
    public var cooldownScale: Double
    public var dashCooldown: Double
    public var mendInterval: Double      // 0 = no Mending
    public var boltDamage: Double
    public var boltCooldown: Double
    public var emberDamage: Double
    public var saltRadius: Double
    public var saltDamage: Double
    public var saltInterval: Double
    public var chainDamage: Double
    public var chainInterval: Double
    public var maxHP: Int
    public var emberCount: Int
    public var chainJumps: Int

    /// `levels` is indexed by `UpgradeKind.rawValue`. Weapon fields are 0 while
    /// that weapon is not owned. Quick Hands speeds up bolt, salt and chain only.
    public init(levels: [Int], tuning t: HordeTuning) {
        func level(_ k: UpgradeKind) -> Int { k.rawValue < levels.count ? levels[k.rawValue] : 0 }
        let bolt = level(.lanternBolt), ember = level(.emberOrbit), salt = level(.saltBurst)
        let chain = level(.chainSpark)
        damageScale = 1 + t.keenWickPerLevel * Double(level(.keenWick))
        cooldownScale = 1 - t.quickHandsPerLevel * Double(level(.quickHands))
        moveSpeed = t.heroSpeed * (1 + t.swiftBootsPerLevel * Double(level(.swiftBoots)))
        maxHP = t.heroBaseHP + level(.thickCoat)
        pickupRadius = t.pickupRadius * (1 + t.lodestonePerLevel * Double(level(.lodestone)))
        dashCooldown = t.dashCooldown * (1 - t.secondWindPerLevel * Double(level(.secondWind)))
        let mend = level(.mending)
        mendInterval = mend == 0 ? 0 : t.mendingInterval / Double(mend)

        if bolt > 0 {
            boltDamage = (t.boltBaseDamage + t.boltDamagePerLevel * Double(bolt - 1)) * damageScale
            boltCooldown = t.boltBaseCooldown * (1 - t.boltCooldownCutPerLevel * Double(bolt - 1)) * cooldownScale
        } else {
            boltDamage = 0
            boltCooldown = 0
        }
        emberCount = ember
        emberDamage = ember > 0 ? t.emberDamage * damageScale : 0
        if salt > 0 {
            saltRadius = t.saltBaseRadius + t.saltRadiusPerLevel * Double(salt - 1)
            saltDamage = (t.saltBaseDamage + t.saltDamagePerLevel * Double(salt - 1)) * damageScale
            saltInterval = t.saltInterval * cooldownScale
        } else {
            saltRadius = 0
            saltDamage = 0
            saltInterval = 0
        }
        chainJumps = chain
        if chain > 0 {
            chainDamage = t.chainDamage * damageScale
            chainInterval = t.chainInterval * cooldownScale
        } else {
            chainDamage = 0
            chainInterval = 0
        }
    }
}
