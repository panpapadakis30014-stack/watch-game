/// Burst tuning for Ringward and Lanternfall. Units: arena radii for
/// Ringward, world units for Lanternfall; times in game seconds. Future
/// games define their own BurstSpecs in their own modules.
public enum FXPresets {
    /// Hard cap for any one game screen.
    public static let maxScreenCapacity = 48
    public static let ringwardCapacity = 36
    public static let lanternfallCapacity = 48

    // Ringward (styles: 0 shield, 1 shard, 2 pulse)
    public static let ringwardBlock = BurstSpec(count: 8, speedMin: 0.5, speedMax: 1.1, lifeMin: 0.25, lifeMax: 0.45,
                                                sizeMin: 0.014, sizeMax: 0.026, drag: 3.0, gravity: 0, spread: 0.6, style: 0)
    public static let ringwardHit = BurstSpec(count: 12, speedMin: 0.3, speedMax: 0.9, lifeMin: 0.30, lifeMax: 0.55,
                                              sizeMin: 0.016, sizeMax: 0.030, drag: 2.5, gravity: 0, spread: 1.2, style: 1)
    public static let ringwardPulse = BurstSpec(count: 16, speedMin: 1.2, speedMax: 1.8, lifeMin: 0.35, lifeMax: 0.50,
                                                sizeMin: 0.014, sizeMax: 0.024, drag: 1.5, gravity: 0, spread: 0, style: 2)

    // Lanternfall (styles: 0 shambler, 1 sprinter, 2 bloat, 3 lantern, 4 danger)
    public static let lanternKillShambler = BurstSpec(count: 6, speedMin: 0.25, speedMax: 0.6, lifeMin: 0.25, lifeMax: 0.45,
                                                      sizeMin: 0.012, sizeMax: 0.024, drag: 3.0, gravity: 0, spread: 0, style: 0)
    public static let lanternKillSprinter = BurstSpec(count: 6, speedMin: 0.25, speedMax: 0.6, lifeMin: 0.25, lifeMax: 0.45,
                                                      sizeMin: 0.012, sizeMax: 0.024, drag: 3.0, gravity: 0, spread: 0, style: 1)
    public static let lanternKillBloat = BurstSpec(count: 10, speedMin: 0.3, speedMax: 0.7, lifeMin: 0.30, lifeMax: 0.50,
                                                   sizeMin: 0.014, sizeMax: 0.028, drag: 3.0, gravity: 0, spread: 0, style: 2)
    public static let lanternKillWarden = BurstSpec(count: 24, speedMin: 0.4, speedMax: 1.0, lifeMin: 0.50, lifeMax: 0.80,
                                                    sizeMin: 0.018, sizeMax: 0.034, drag: 2.0, gravity: 0, spread: 0, style: 3)
    public static let lanternHurt = BurstSpec(count: 8, speedMin: 0.3, speedMax: 0.7, lifeMin: 0.25, lifeMax: 0.40,
                                              sizeMin: 0.014, sizeMax: 0.024, drag: 3.0, gravity: 0, spread: 0, style: 4)
    public static let lanternLevelUp = BurstSpec(count: 20, speedMin: 0.5, speedMax: 1.0, lifeMin: 0.40, lifeMax: 0.60,
                                                 sizeMin: 0.014, sizeMax: 0.026, drag: 2.0, gravity: -0.3, spread: 0, style: 3)

    public static let ringwardSpecs = [ringwardBlock, ringwardHit, ringwardPulse]
    public static let lanternfallSpecs = [lanternKillShambler, lanternKillSprinter, lanternKillBloat,
                                          lanternKillWarden, lanternHurt, lanternLevelUp]
}
