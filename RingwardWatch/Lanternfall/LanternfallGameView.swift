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
            LanternfallCanvas(game: controller.game, reduceMotion: reduceMotion)
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
        return VStack(alignment: .trailing, spacing: 0) {
            Text(LanternfallCopy.clock(seconds))
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .accessibilityLabel("Time \(LanternfallCopy.spokenTime(seconds))")
            Text("Lv \(game.level)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.lfLantern)
                .accessibilityLabel("Level \(game.level)")
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
            VStack(spacing: 2) {
                Capsule()
                    .fill(Theme.ring)
                    .frame(width: width, height: height)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(colour)
                            .frame(width: width * CGFloat(fraction), height: height)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Grave Warden health \(percent) percent")
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
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(colour)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func healthView(game: HordeGame) -> some View {
        let maxHP = game.stats.maxHP
        return HStack(spacing: 2) {
            Image(systemName: "heart.fill")
            Text("\(game.hero.hp)/\(maxHP)")
        }
        .font(.footnote.monospacedDigit())
        .foregroundStyle(Theme.danger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LanternfallCopy.healthLabel(hp: game.hero.hp, maxHP: maxHP))
    }

    private func killsView(game: HordeGame) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "scope")
            Text("\(game.kills)")
        }
        .font(.footnote.monospacedDigit())
        .foregroundStyle(.white)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LanternfallCopy.killsLabel(game.kills))
    }

    private func xpBar(game: HordeGame, size: CGSize) -> some View {
        let width = size.width * Theme.lfXPBarWidthRatio
        let height = max(3, size.height * Theme.lfBarHeightRatio)
        let need = game.xpToNext
        let fraction = need > 0 ? min(CGFloat(game.xp) / CGFloat(need), 1) : 0
        return Capsule()
            .fill(Theme.ring)
            .frame(width: width, height: height)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Theme.lfXP)
                    .frame(width: width * fraction, height: height)
            }
            .padding(.bottom, 4)
            .accessibilityElement()
            .accessibilityLabel("Experience \(game.xp) of \(need)")
    }
}
