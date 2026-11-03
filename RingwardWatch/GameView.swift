import SwiftUI
import GameCore

/// The playing screen: arena in the middle, HUD in the four corners the
/// circle leaves free, Crown turns the shield, a tap anywhere fires the Pulse.
struct GameView: View {
    let controller: GameController

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var crownValue = 0.0
    @FocusState private var crownFocused: Bool

    var body: some View {
        GeometryReader { geo in
            let game = controller.game
            let isPaused = game.phase == .paused
            ZStack {
                arena(side: min(geo.size.width, geo.size.height) * Theme.arenaScale)
                    .opacity(isPaused ? 0.35 : 1)
                hud(game: game, size: geo.size)
                if isPaused {
                    PauseOverlay {
                        controller.resume()
                        crownFocused = true
                    }
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

    private func arena(side: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !controller.isRunning)) { timeline in
            ArenaCanvas(
                game: controller.game,
                effects: controller.effects,
                reduceMotion: reduceMotion,
                now: controller.game.elapsed,
                lastHitTime: controller.lastHitTime
            )
            .onChange(of: timeline.date) { _, date in
                controller.tick(now: date)
            }
        }
        .frame(width: side, height: side)
    }

    // MARK: HUD

    private func hud(game: Game, size: CGSize) -> some View {
        Color.clear
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topLeading) { pauseButton(size: size) }
            .overlay(alignment: .topTrailing) { scoreView(game: game) }
            .overlay(alignment: .bottomLeading) { livesView(game: game) }
            .overlay(alignment: .bottomTrailing) { pulseMeter(game: game, size: size) }
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

    private func scoreView(game: Game) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(game.score)")
                .font(.title3.monospacedDigit())
                .foregroundStyle(.white)
                .accessibilityLabel("Score \(game.score)")
            if game.multiplier > 1 {
                Text("x\(game.multiplier)")
                    .font(.caption2)
                    .foregroundStyle(Theme.pulse)
                    .accessibilityLabel("Combo multiplier \(game.multiplier)")
            }
        }
    }

    private func livesView(game: Game) -> some View {
        let label: String = game.lives == 1 ? "1 life left" : "\(game.lives) lives left"
        return HStack(spacing: 2) {
            ForEach(0..<game.tuning.startLives, id: \.self) { i in
                Image(systemName: i < game.lives ? "heart.fill" : "heart")
            }
        }
        .font(.footnote)
        .foregroundStyle(Theme.danger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    private func pulseMeter(game: Game, size: CGSize) -> some View {
        let width = size.width * 0.28
        let height = max(4, size.height * 0.025)
        let fraction = min(CGFloat(game.pulseCharge) / CGFloat(game.tuning.pulseChargeMax), 1)
        let label: String = game.isPulseReady
            ? "Pulse ready. Tap the screen to fire."
            : "Pulse charge \(game.pulseCharge) of \(game.tuning.pulseChargeMax)"
        return VStack(alignment: .trailing, spacing: 2) {
            if game.isPulseReady {
                Text("Tap: Pulse")
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.pulse)
            }
            Capsule()
                .fill(Theme.ring)
                .frame(width: width, height: height)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Theme.pulse)
                        .frame(width: width * fraction, height: height)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
