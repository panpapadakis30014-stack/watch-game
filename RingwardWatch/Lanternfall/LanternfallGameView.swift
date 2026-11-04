import SwiftUI
import HordeCore

/// The Lanternfall screen: the graveyard fills the display, the HUD sits in
/// the corners and edges, the Crown steers, a tap anywhere dashes. Same
/// focus, Crown and lifecycle handling as Ringward's GameView.
struct LanternfallGameView: View {
    let controller: LanternfallController

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var crownValue = 0.0
    @FocusState private var crownFocused: Bool

    var body: some View {
        GeometryReader { geo in
            let game = controller.game
            ZStack {
                arena
                    .ignoresSafeArea()
                    .opacity(game.isPaused ? 0.35 : 1)
                hud(game: game, size: geo.size)
                if let offer = game.offer {
                    LevelUpView(offer: offer) { index in
                        controller.choose(index)
                    }
                }
                if game.isPaused {
                    LanternfallPauseOverlay(
                        onResume: {
                            controller.resume()
                            crownFocused = true
                        },
                        onEnd: {
                            controller.endRun()
                        }
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                controller.tapArena()
            }
            .focusable(true)
            .focused($crownFocused)
            .focusEffectDisabled()
            .digitalCrownRotation(
                $crownValue,
                from: -1_000_000,
                through: 1_000_000,
                by: nil,
                sensitivity: .high,
                isContinuous: false,
                isHapticFeedbackEnabled: false
            )
            .onChange(of: crownValue) { _, value in
                controller.crownChanged(to: value)
            }
            .onAppear {
                crownFocused = true
            }
            .onChange(of: reduceMotion, initial: true) { _, reduce in
                controller.setReduceMotion(reduce)
            }
            .onChange(of: controller.game.offer?.serial) { _, serial in
                // Choosing an upgrade can move focus to the button; take the Crown back.
                if serial == nil {
                    crownFocused = true
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    controller.pause()
                }
            }
            .onChange(of: isLuminanceReduced) { _, reduced in
                if reduced {
                    controller.pause()
                }
            }
        }
    }

    // MARK: Arena

    private var arena: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !controller.isRunning)) { timeline in
            LanternfallCanvas(game: controller.game, particles: controller.fx, reduceMotion: reduceMotion)
                .onChange(of: timeline.date) { _, date in
                    controller.tick(now: date)
                }
        }
    }

    // MARK: HUD

    private func hud(game: HordeGame, size: CGSize) -> some View {
        Color.clear
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topLeading) { pauseButton(size: size) }
            .overlay(alignment: .topTrailing) { clockView(game: game) }
            .overlay(alignment: .top) { bossView(game: game, size: size) }
            .overlay(alignment: .bottomLeading) { healthView(game: game) }
            .overlay(alignment: .bottomTrailing) { killsView(game: game) }
            .overlay(alignment: .bottom) { xpBar(game: game, size: size) }
    }

    private func pauseButton(size: CGSize) -> some View {
        let side = max(Theme.minTapTarget, size.width * Theme.pauseButtonRatio)
        return Button {
            controller.pause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
                .frame(width: side, height: side)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pause")
    }

    private func clockView(game: HordeGame) -> some View {
        let seconds = Int(game.elapsed)
        return VStack(alignment: .trailing, spacing: 2) {
            HUDLabel(text: LanternfallCopy.clock(seconds), role: .value, plate: true,
                     accessibilityText: "Time \(LanternfallCopy.spokenTime(seconds))")
            HUDLabel(text: "Lv \(game.level)", role: .caption, color: Theme.lanternfallAccent, plate: true,
                     accessibilityText: "Level \(game.level)")
        }
    }

    @ViewBuilder
    private func bossView(game: HordeGame, size: CGSize) -> some View {
        if let boss = game.boss {
            let width = size.width * Theme.lfBossBarWidthRatio
            let height = max(3, size.height * Theme.lfBarHeightRatio)
            let fraction = min(max(boss.hp / boss.maxHP, 0), 1)
            let percent = Int((fraction * 100).rounded(.up))
            let colour = game.isEnraged ? Theme.lfEnraged : Theme.lfWarden
            VStack(spacing: 3) {
                HUDBar(fraction: fraction, width: width, height: height, tint: colour, glow: true,
                       accessibilityText: "Grave Warden health \(percent) percent")
                if game.isEnraged && game.elapsed < game.tuning.enrageTime + Theme.lfBannerDuration {
                    banner("The Warden is enraged", colour: Theme.lfEnraged)
                } else if game.elapsed < game.tuning.bossTime + Theme.lfBannerDuration {
                    banner("The Grave Warden rises", colour: Theme.lfWarden)
                }
            }
            .padding(.top, 4)
        }
    }

    private func banner(_ text: String, colour: Color) -> some View {
        HUDLabel(text: text, role: .caption, color: colour, plate: true, accessibilityText: text)
    }

    private func healthView(game: HordeGame) -> some View {
        let maxHP = game.stats.maxHP
        return HUDLabel(text: "\(game.hero.hp)/\(maxHP)", role: .detail, color: Theme.danger, symbol: "heart.fill",
                        plate: true, accessibilityText: LanternfallCopy.healthLabel(hp: game.hero.hp, maxHP: maxHP))
    }

    private func killsView(game: HordeGame) -> some View {
        HUDLabel(text: "\(game.kills)", role: .detail, symbol: "scope", countingValue: Double(game.kills),
                 plate: true, accessibilityText: LanternfallCopy.killsLabel(game.kills))
    }

    /// No plate and no glow, so it covers no more of the field than before.
    private func xpBar(game: HordeGame, size: CGSize) -> some View {
        let width = size.width * Theme.lfXPBarWidthRatio
        let height = max(3, size.height * Theme.lfBarHeightRatio)
        let need = game.xpToNext
        let fraction = need > 0 ? min(Double(game.xp) / Double(need), 1) : 0
        return HUDBar(fraction: fraction, width: width, height: height, tint: Theme.lfXP,
                      accessibilityText: "Experience \(game.xp) of \(need)")
            .padding(.bottom, 4)
    }
}
